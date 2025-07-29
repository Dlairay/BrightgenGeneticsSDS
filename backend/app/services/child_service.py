import json
import tempfile
import os
from typing import List, Dict, Optional

from app.models.child_profile import ChildProfile
from app.repositories.child_repository import ChildRepository, _convert_firestore_timestamps_to_strings
from app.repositories.trait_repository import TraitRepository
from app.schemas.child import Child, CheckInAnswers, RecommendationHistory, DrBloomSessionStart, DrBloomSessionComplete, GeneticReportData
from app.agents.planner_agent.agent import LogGenerationService
from app.services.genetic_report_parser import GeneticReportParser
from app.services.chatbot_service import ChatbotService
import pandas as pd
import os


class ChildService:
    def __init__(self):
        self.child_repo = ChildRepository()
        self.trait_repo = TraitRepository()
        self.log_service = LogGenerationService()
        self.chatbot_service = ChatbotService()
        self.report_parser = GeneticReportParser()
    
    async def get_children_for_user(self, user_id: str) -> List[Child]:
        child_ids = await self.child_repo.get_children_for_user(user_id)
        children = []
        
        for child_id in child_ids:
            report_data = await self.child_repo.load_report(child_id)
            if report_data:
                children.append(Child(
                    id=child_id,
                    name=report_data.get("name", f"Child {child_id}"),
                    birthday=report_data.get("birthday", ""),
                    gender=report_data.get("gender", "")
                ))
        
        return children
    
    async def create_child_profile(self, genetic_data: Dict, child_name: str, user_id: str) -> Dict:
        genetic_data["name"] = child_name
        child_id = genetic_data["child_id"]
        
        # Check if child already exists for this user
        existing_children = await self.child_repo.get_children_for_user(user_id)
        if child_id in existing_children:
            return {
                "message": f"Child profile {child_id} already exists for this user",
                "child_id": child_id,
                "initial_log_created": False,
                "error": "CHILD_ALREADY_EXISTS"
            }
        
        # Check if child profile exists in database (might belong to another user)
        existing_report = await self.child_repo.load_report(child_id)
        if existing_report:
            return {
                "message": f"Child profile {child_id} already exists in the system",
                "child_id": child_id,
                "initial_log_created": False,
                "error": "CHILD_ID_TAKEN"
            }
        
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait reference data could not be loaded from Firestore.")
        
        child_profile = ChildProfile(child_id, trait_db)
        child_profile.report = genetic_data
        
        await self.child_repo.save_report(child_id, genetic_data)
        
        matched_traits = child_profile.match_traits()
        child_profile.traits = matched_traits
        await self.child_repo.save_traits(child_id, matched_traits)
        
        derived_age = child_profile.get_derived_age()
        gender = genetic_data.get("gender")
        
        entry = await self.log_service.generate_initial_log(
            matched_traits,
            derived_age=derived_age,
            gender=gender
        )
        
        await self.child_repo.save_log(child_id, entry)
        await self.child_repo.associate_child_with_user(user_id, child_id)
        
        return {
            "message": "Genetic report uploaded successfully",
            "child_id": child_id,
            "initial_log_created": True
        }
    
    async def get_check_in_questions(self, child_id: str) -> Dict:
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait database not available")
        
        logs = await self.child_repo.load_logs(child_id)
        if not logs:
            raise ValueError("No logs found for this child")
        
        all_questions = []
        
        # Check if most recent log is a Dr. Bloom consultation (Flow 1)
        latest_log = logs[-1]
        if latest_log.get('entry_type') == 'dr_bloom':
            dr_bloom_question = {
                "question": f"Follow-up on Dr. Bloom consultation: Has the situation you discussed with Dr. Bloom improved?",
                "options": ["Yes, it's much better now", "Somewhat better", "No change", "It's gotten worse"],
                "is_dr_bloom_followup": True
            }
            all_questions.append(dr_bloom_question)
        
        # Find most recent "checkin" or "initial" type entry for regular questions (Flow 2)
        latest_checkin_log = None
        for log in reversed(logs):
            if log.get('entry_type') in ['checkin', 'initial']:
                latest_checkin_log = log
                break
        
        if latest_checkin_log:
            followup_questions = latest_checkin_log.get('followup_questions', [])
            
            session_id = f"session_{child_id}"
            await self.log_service._ensure_session(session_id)
            
            for item in followup_questions:
                if isinstance(item, str):
                    opts = await self.log_service._generate_question_options(
                        item, latest_checkin_log['interpreted_traits'], session_id
                    )
                    all_questions.append({
                        "question": item,
                        "options": opts,
                        "is_emergency_followup": False
                    })
                else:
                    item["is_emergency_followup"] = False
                    all_questions.append(item)
        
        if not all_questions:
            return {"questions": [], "message": "No follow-up questions available"}
        
        return {"questions": all_questions}
    
    async def submit_check_in(self, child_id: str, answers: CheckInAnswers) -> Dict:
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait database not available")
        
        logs = await self.child_repo.load_logs(child_id)
        if not logs:
            raise ValueError("No logs found for this child")
        
        logs_for_agent = _convert_firestore_timestamps_to_strings(logs)
        
        # Separate Dr. Bloom follow-up from regular answers
        dr_bloom_answers = []
        regular_answers = []
        
        for answer in answers.answers:
            # Check if this is a Dr. Bloom follow-up question
            if "Follow-up on Dr. Bloom consultation" in answer.question:
                dr_bloom_answers.append(answer)
            else:
                regular_answers.append(answer)
        
        # Handle Dr. Bloom follow-up if present
        if dr_bloom_answers:
            dr_bloom_answer = dr_bloom_answers[0].answer
            latest_dr_bloom_log = logs_for_agent[-1]  # Most recent should be dr_bloom
            
            if dr_bloom_answer in ["Yes, it's much better now", "Somewhat better"]:
                # Mark Dr. Bloom consultation as resolved
                resolved_entry = {
                    'entry_type': 'dr_bloom_resolved',
                    'interpreted_traits': [],
                    'recommendations': [],
                    'summary': f"Dr. Bloom follow-up: {dr_bloom_answer}. Consultation issue resolved.",
                    'followup_questions': [],
                    'resolved_consultation_id': latest_dr_bloom_log.get('dr_bloom_session_id', 'Unknown consultation')
                }
                await self.child_repo.save_log(child_id, resolved_entry)
            
            elif dr_bloom_answer in ["No change", "It's gotten worse"]:
                # Note: In this case, the parent might want to start another Dr. Bloom session
                # For now, we'll just log the status. The frontend can prompt for another consultation.
                followup_entry = {
                    'entry_type': 'dr_bloom_followup',
                    'interpreted_traits': [],
                    'recommendations': [],
                    'summary': f"Dr. Bloom follow-up: {dr_bloom_answer}. May need additional consultation.",
                    'followup_questions': [],
                    'previous_consultation_id': latest_dr_bloom_log.get('dr_bloom_session_id', 'Unknown consultation')
                }
                await self.child_repo.save_log(child_id, followup_entry)
        
        # Handle regular weekly check-in
        if regular_answers:
            # Find most recent checkin log for traits context
            # If only initial log exists, use it; otherwise use the latest checkin log
            latest_checkin_log = None
            if len(logs_for_agent) == 1 and logs_for_agent[0].get('entry_type') == 'initial':
                # Only initial log exists
                latest_checkin_log = logs_for_agent[0]
            else:
                # Multiple logs exist, find the latest checkin (not initial)
                for log in reversed(logs_for_agent):
                    if log.get('entry_type') == 'checkin':
                        latest_checkin_log = log
                        break
                
                # If no checkin found but initial exists, use initial
                if not latest_checkin_log:
                    for log in reversed(logs_for_agent):
                        if log.get('entry_type') == 'initial':
                            latest_checkin_log = log
                            break
            
            if not latest_checkin_log:
                raise ValueError("No previous check-in found for regular questions")
            
            regular_answer_dict = {answer.question: answer.answer for answer in regular_answers}
            
            report_data = await self.child_repo.load_report(child_id)
            child_profile = ChildProfile(child_id, trait_db)
            child_profile.report = report_data
            
            child_age = child_profile.get_derived_age()
            child_gender = report_data.get("gender")
            
            session_id = f"session_{child_id}"
            await self.log_service._ensure_session(session_id)
            
            new_entry = await self.log_service._generate_followup_entry(
                latest_checkin_log['interpreted_traits'],
                regular_answer_dict,
                session_id,
                logs_for_agent,
                derived_age=child_age,
                gender=child_gender
            )
            
            await self.child_repo.save_log(child_id, new_entry)
            
            return {
                "message": "Check-in completed successfully",
                "recommendations": new_entry.get('recommendations', []),
                "summary": new_entry.get('summary', ''),
                "emergency_handled": len(dr_bloom_answers) > 0
            }
        
        return {
            "message": "Dr. Bloom follow-up completed",
            "recommendations": [],
            "summary": "Dr. Bloom follow-up has been addressed.",
            "emergency_handled": len(dr_bloom_answers) > 0
        }
    
    async def get_child_profile(self, child_id: str) -> Dict:
        return await self.child_repo.get_child_profile_json(child_id)
    
    async def get_recommendations_history(self, child_id: str) -> List[RecommendationHistory]:
        logs = await self.child_repo.load_logs(child_id)
        
        history = []
        for log in logs:
            if 'recommendations' in log and log['recommendations']:
                history.append(RecommendationHistory(
                    timestamp=log.get('timestamp'),
                    recommendations=log['recommendations'],
                    summary=log.get('summary', ''),
                    entry_type=log.get('entry_type', 'checkin')
                ))
        
        return history
    
    async def start_dr_bloom_session(self, user_id: str, child_id: str, session_data: DrBloomSessionStart) -> Dict:
        """Start a Dr. Bloom consultation session."""
        # Chatbot service is already initialized
        
        # Create a Dr. Bloom conversation (will be deleted after completion)
        conversation = await self.chatbot_service.create_conversation(
            user_id=user_id,
            child_id=child_id,
            is_temporary=True  # This marks it as a Dr. Bloom session
        )
        
        # Send the initial message with image if provided
        initial_response = await self.chatbot_service.send_message(
            user_id=user_id,
            session_id=conversation["session_id"],
            message=session_data.initial_concern,
            agent_type="dr_bloom",
            image=session_data.image,
            image_type=session_data.image_type
        )
        
        return {
            "session_id": conversation["session_id"],
            "conversation_id": conversation["id"],
            "initial_response": initial_response["agent_response"],
            "message": "Dr. Bloom session started successfully"
        }
    
    async def complete_dr_bloom_session(self, user_id: str, child_id: str, complete_data: DrBloomSessionComplete) -> Dict:
        """Complete a Dr. Bloom session and create a log entry."""
        print(f"Starting Dr. Bloom completion - user: {user_id}, child: {child_id}, session: {complete_data.session_id}")
        # Chatbot service is already initialized
        
        # Get child info for context
        report_data = await self.child_repo.load_report(child_id)
        child_profile = ChildProfile(child_id, pd.DataFrame())
        child_profile.report = report_data
        
        child_name = report_data.get("name", "Child")
        
        # Get structured log data from Dr. Bloom conversation BEFORE deleting
        print("Getting structured log data...")
        try:
            log_data = await self.chatbot_service.generate_structured_log(
                session_id=complete_data.session_id,
                user_id=user_id,
                child_id=child_id
            )
            print(f"Log data generated: {log_data}")
        except Exception as e:
            print(f"Error generating log data: {e}")
            raise
        
        # Delete the conversation and all its messages immediately after getting data
        print("Deleting conversation...")
        try:
            await self.chatbot_service.delete_conversation_completely(
                session_id=complete_data.session_id,
                user_id=user_id
            )
            print("Conversation deleted successfully")
        except Exception as e:
            print(f"Error deleting conversation: {e}")
            # Continue anyway - we still want to save the log
        # Create log entry matching your exact structure
        dr_bloom_entry = {
            'entry_type': 'dr_bloom',  # Add this to your accepted entry types
            'interpreted_traits': log_data.get('interpreted_traits', []),
            'recommendations': log_data.get('recommendations', []),
            'summary': log_data.get('summary', ''),
            'followup_questions': log_data.get('followup_questions', [])
        }
        
        print(f"Saving log entry: {dr_bloom_entry}")
        try:
            await self.child_repo.save_log(child_id, dr_bloom_entry)
            print("Log entry saved successfully")
        except Exception as e:
            print(f"Error saving log entry: {e}")
            raise
        
        print("Dr. Bloom completion finished successfully")
        return {
            "message": "Dr. Bloom consultation completed and logged",
            "summary": log_data.get('summary', 'Consultation completed'),
            "log_created": True,
            "conversation_deleted": True
        }
    
    async def create_child_profile_from_file(self, file_content: bytes, content_type: str, child_name: str, user_id: str) -> Dict:
        """
        Create child profile from either JSON or PDF file
        
        Args:
            file_content: File content as bytes
            content_type: MIME type of the file
            child_name: Name of the child
            user_id: User ID
            
        Returns:
            Dictionary with result status
        """
        # Parse the file to extract genetic data
        genetic_report_data = await self.report_parser.parse_json_or_pdf(file_content, content_type)
        
        # Convert to dictionary format expected by create_child_profile
        genetic_data = {
            "child_id": genetic_report_data.child_id,
            "birthday": genetic_report_data.birthday,
            "gender": genetic_report_data.gender,
            "genotype_profile": [
                {"rs_id": item["rs_id"], "genotype": item["genotype"]} 
                for item in genetic_report_data.genotype_profile
            ]
        }
        
        # Use existing create_child_profile method
        return await self.create_child_profile(genetic_data, child_name, user_id)