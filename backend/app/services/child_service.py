import json
import tempfile
import os
from typing import List, Dict, Optional

from app.models.child_profile import ChildProfile
from app.repositories.child_repository import ChildRepository, _convert_firestore_timestamps_to_strings
from app.repositories.trait_repository import TraitRepository
from app.schemas.child import Child, CheckInAnswers, RecommendationHistory, EmergencyCheckIn, GeneticReportData
from app.agents.planner_agent.agent import LogGenerationService
from app.services.genetic_report_parser import GeneticReportParser
import pandas as pd
import os


class ChildService:
    def __init__(self):
        self.child_repo = ChildRepository()
        self.trait_repo = TraitRepository()
        self.log_service = LogGenerationService()
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
        
        # Check if most recent log is an emergency (Flow 1)
        latest_log = logs[-1]
        if latest_log.get('entry_type') == 'emergency':
            emergency_question = {
                "question": f"Follow-up on emergency: Has the situation from your last emergency report improved?",
                "options": ["Yes, it's much better now", "Somewhat better", "No change", "It's gotten worse"],
                "is_emergency_followup": True
            }
            all_questions.append(emergency_question)
        
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
        
        # Separate emergency follow-up from regular answers
        emergency_answers = []
        regular_answers = []
        
        for answer in answers.answers:
            # Check if this is an emergency follow-up question
            if "Follow-up on emergency" in answer.question:
                emergency_answers.append(answer)
            else:
                regular_answers.append(answer)
        
        # Handle emergency follow-up if present
        if emergency_answers:
            emergency_answer = emergency_answers[0].answer
            latest_emergency_log = logs_for_agent[-1]  # Most recent should be emergency
            
            if emergency_answer in ["Yes, it's much better now", "Somewhat better"]:
                # Mark emergency as resolved
                resolved_entry = {
                    'entry_type': 'emergency_resolved',
                    'interpreted_traits': [],
                    'recommendations': [],
                    'summary': f"Emergency follow-up: {emergency_answer}. Emergency situation resolved.",
                    'followup_questions': [],
                    'resolved_emergency_id': latest_emergency_log.get('emergency_description', 'Unknown emergency')
                }
                await self.child_repo.save_log(child_id, resolved_entry)
            
            elif emergency_answer in ["No change", "It's gotten worse"]:
                # Trigger new emergency check-in
                emergency_data = EmergencyCheckIn(
                    description=f"Follow-up: {emergency_answer}. Original issue: {latest_emergency_log.get('emergency_description', 'Previous emergency situation')}"
                )
                await self.emergency_check_in(child_id, emergency_data)
        
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
                "emergency_handled": len(emergency_answers) > 0
            }
        
        return {
            "message": "Emergency follow-up completed",
            "recommendations": [],
            "summary": "Emergency situation has been addressed.",
            "emergency_handled": True
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
    
    async def emergency_check_in(self, child_id: str, emergency_data: EmergencyCheckIn) -> Dict:
        # Get child info for context
        report_data = await self.child_repo.load_report(child_id)
        child_profile = ChildProfile(child_id, pd.DataFrame())  # We don't need traits for emergency
        child_profile.report = report_data
        
        derived_age = child_profile.get_derived_age()
        gender = report_data.get("gender", "unknown")
        child_name = report_data.get("name", "Child")
        
        # Use existing agent infrastructure for analysis
        session_id = f"emergency_{child_id}"
        await self.log_service._ensure_session(session_id)
        
        # Create a simple emergency summary without using external APIs
        emergency_summary = f"Emergency report received for {child_name} (age {derived_age}): {emergency_data.description}"
        if emergency_data.image:
            emergency_summary += " [Image attached]"
        
        # Create emergency log entry
        emergency_entry = {
            'entry_type': 'emergency',
            'interpreted_traits': [],  # Empty for emergency
            'recommendations': [],     # Empty as requested
            'summary': emergency_summary,
            'followup_questions': [],  # Empty for emergency
            'emergency_description': emergency_data.description,
            'has_image': emergency_data.image is not None,
            'image_type': emergency_data.image_type if emergency_data.image else None
        }
        
        await self.child_repo.save_log(child_id, emergency_entry)
        
        return {
            "message": "Emergency report submitted successfully",
            "summary": emergency_summary,
            "emergency_id": child_id
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