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
from app.services.immunity_service import ImmunityService
from app.services.growth_milestone_service import GrowthMilestoneService
import pandas as pd


class ChildService:
    def __init__(self):
        self.child_repo = ChildRepository()
        self.trait_repo = TraitRepository()
        self.log_service = LogGenerationService()
        self.immunity_service = ImmunityService()
        self.growth_service = GrowthMilestoneService()
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
        
        # Filter traits for weekly check-ins to only include "Cognitive & Behavioral" archetype
        cognitive_behavioral_traits = [
            trait for trait in matched_traits 
            if trait.get("archetype", "").lower() == "cognitive & behavioral"
        ]
        
        entry = await self.log_service.generate_initial_log(
            cognitive_behavioral_traits,  # Pass filtered traits for check-ins
            derived_age=derived_age,
            gender=gender
        )
        
        await self.child_repo.save_log(child_id, entry)
        await self.child_repo.associate_child_with_user(user_id, child_id)
        
        # Pre-compute and store static reference data for performance
        print(f"🔄 Pre-computing immunity and growth data for child {child_id}...")
        
        # Pre-compute immunity suggestions (static data)
        try:
            immunity_data = await self._precompute_immunity_suggestions(child_id, matched_traits)
            await self.child_repo.save_immunity_data(child_id, immunity_data)
            print(f"✅ Immunity data pre-computed: {len(immunity_data.get('suggestions_by_trait', {}))} traits")
        except Exception as e:
            print(f"⚠️ Failed to pre-compute immunity data: {e}")
        
        # Pre-compute growth roadmap (static data)
        try:
            roadmap_data = await self._precompute_growth_roadmap(child_id, matched_traits, genetic_data.get("birthday", ""))
            await self.child_repo.save_roadmap_data(child_id, roadmap_data)
            print(f"✅ Growth roadmap pre-computed: {len(roadmap_data.get('roadmap', []))} age groups")
        except Exception as e:
            print(f"⚠️ Failed to pre-compute growth roadmap: {e}")
        
        return {
            "message": "Genetic report uploaded successfully",
            "child_id": child_id,
            "initial_log_created": True,
            "immunity_data_precomputed": True,
            "roadmap_data_precomputed": True
        }
    
    async def get_check_in_questions(self, child_id: str) -> Dict:
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait database not available")
        
        logs = await self.child_repo.load_logs(child_id)
        if not logs:
            raise ValueError("No logs found for this child")
        
        all_questions = []
        
        # Find most recent "checkin" or "initial" type entry for questions
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
        
        # All answers are now regular check-in answers (no more Dr. Bloom follow-ups)
        regular_answers = answers.answers
        
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
            raise ValueError("No previous check-in found for questions")
        
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
            "emergency_handled": False
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
    
    async def get_latest_recommendations_overview(self, child_id: str) -> Dict:
        """
        Get a quick overview of the latest recommendations for behavioral and cognitive development.
        This pulls from the most recent check-in log without running the AI agent.
        """
        # Get all logs
        logs = await self.child_repo.load_logs(child_id)
        
        # Find the most recent log with recommendations (both initial and checkin)
        latest_log = None
        for log in reversed(logs):  # Start from most recent
            if log.get('entry_type') in ['initial', 'checkin'] and 'recommendations' in log and log['recommendations']:
                latest_log = log
                break
        
        if not latest_log:
            # No check-in logs found, return empty overview
            report_data = await self.child_repo.load_report(child_id)
            child_name = report_data.get('name', 'Child') if report_data else 'Child'
            
            return {
                "child_id": child_id,
                "child_name": child_name,
                "last_check_in_date": None,
                "recommendations": [],
                "summary": "No check-ins completed yet"
            }
        
        # Get child name
        report_data = await self.child_repo.load_report(child_id)
        child_name = report_data.get('name', 'Child') if report_data else 'Child'
        
        # Format recommendations into simple action items
        formatted_recommendations = []
        for rec in latest_log['recommendations']:
            # Use tldr if available, otherwise fall back to combining goal and activity
            if rec.get('tldr'):
                action = rec['tldr']
            else:
                # Fallback for old logs without tldr
                action = f"Provide child with {rec.get('activity', 'activities')} to {rec.get('goal', 'support development').lower()}"
            
            formatted_recommendations.append({
                "trait_name": rec.get('trait', 'Unknown trait'),
                "action": action
            })
        
        return {
            "child_id": child_id,
            "child_name": child_name,
            "last_check_in_date": latest_log.get('timestamp'),
            "recommendations": formatted_recommendations,
            "summary": latest_log.get('summary', 'No summary available')
        }
    
    async def get_latest_recommendations_detail(self, child_id: str) -> Dict:
        """
        Get detailed view of the latest recommendations with full activity descriptions.
        Returns the complete latest log entry for display.
        """
        # Get all logs
        logs = await self.child_repo.load_logs(child_id)
        
        # Find the most recent log with recommendations (both initial and checkin)
        latest_log = None
        for log in reversed(logs):  # Start from most recent
            if log.get('entry_type') in ['initial', 'checkin'] and 'recommendations' in log and log['recommendations']:
                latest_log = log
                break
        
        if not latest_log:
            # No logs found, return empty detail
            report_data = await self.child_repo.load_report(child_id)
            child_name = report_data.get('name', 'Child') if report_data else 'Child'
            
            return {
                "child_id": child_id,
                "child_name": child_name,
                "last_check_in_date": None,
                "entry_type": None,
                "recommendations": [],
                "summary": "No check-ins completed yet"
            }
        
        # Get child name
        report_data = await self.child_repo.load_report(child_id)
        child_name = report_data.get('name', 'Child') if report_data else 'Child'
        
        # Return full recommendation details
        return {
            "child_id": child_id,
            "child_name": child_name,
            "last_check_in_date": latest_log.get('timestamp'),
            "entry_type": latest_log.get('entry_type'),
            "recommendations": latest_log.get('recommendations', []),
            "summary": latest_log.get('summary', 'No summary available')
        }
    
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
        
        # Generate medical logs from Dr. Bloom conversation BEFORE deleting
        print("🏥 Processing Dr. Bloom conversation for medical logs...")
        try:
            medical_result = await self.chatbot_service.generate_medical_logs_only(
                session_id=complete_data.session_id,
                user_id=user_id,
                child_id=child_id
            )
            print(f"🏥 Medical log processing result: {medical_result}")
        except Exception as e:
            print(f"💥 Error processing medical logs: {e}")
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
        print("🏥 Dr. Bloom completion finished successfully")
        
        # Build response carefully to avoid any None/Sentinel issues
        response = {
            "message": "Dr. Bloom medical consultation completed",
            "summary": medical_result.get('summary', 'Medical consultation completed'),
            "medical_logs_created": medical_result.get('medical_logs_created', 0),
            "conversation_deleted": True,
            "status": medical_result.get('status', 'completed')
        }
        
        # Only add medical_log if it exists
        if medical_result.get('medical_log'):
            response["medical_log"] = medical_result['medical_log']
        
        # Only add log_id if it exists
        if medical_result.get('log_id'):
            response["log_id"] = medical_result['log_id']
            
        print(f"🏥 RESPONSE KEYS: {list(response.keys())}")
        print(f"🏥 RESPONSE: {response}")
        
        return response
    
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
    
    async def get_child_traits_mapped(self, child_id: str) -> List[Dict]:
        """
        Get child traits with mapped keys for display.
        Maps trait fields to: confidence, description, gene, trait_name
        Converts confidence from float (0-1) to percentage string
        """
        traits = await self.child_repo.load_traits(child_id)
        
        # Debug: Log the structure of the first trait
        if traits:
            print(f"DEBUG: First trait structure: {traits[0]}")
            print(f"DEBUG: Trait keys: {list(traits[0].keys()) if traits else 'No traits'}")
        
        mapped_traits = []
        for trait in traits:
            # Convert confidence from float to percentage
            confidence_value = trait.get("confidence", 0)
            if isinstance(confidence_value, (int, float)):
                confidence_percentage = f"{int(confidence_value * 100)}%"
            else:
                confidence_percentage = "0%"
            
            mapped_trait = {
                "confidence": confidence_percentage,
                "description": trait.get("description", ""),
                "gene": trait.get("gene", ""),
                "trait_name": trait.get("trait_name", ""),
                "archetype": trait.get("archetype", "")
            }
            mapped_traits.append(mapped_trait)
        
        return mapped_traits
    
    async def _precompute_immunity_suggestions(self, child_id: str, matched_traits: List[Dict]) -> Dict:
        """Pre-compute immunity suggestions based on traits."""
        # Filter for immunity & resilience traits
        immunity_traits = [
            trait for trait in matched_traits
            if trait.get('archetype', '').lower() == 'immunity & resilience'
        ]
        
        # Extract trait names
        trait_names = [trait.get('trait_name', '') for trait in immunity_traits if trait.get('trait_name')]
        
        if not trait_names:
            return {
                'child_id': child_id,
                'immunity_traits': immunity_traits,
                'suggestions_by_trait': {},
                'total_traits': 0,
                'total_suggestions': 0
            }
        
        # Get grouped suggestions from reference data
        grouped_suggestions = await self.immunity_service.immunity_suggestion_repo.get_grouped_suggestions_for_child(trait_names)
        
        return {
            'child_id': child_id,
            'immunity_traits': immunity_traits,
            'suggestions_by_trait': grouped_suggestions,
            'total_traits': len(immunity_traits),
            'total_suggestions': sum(len(suggestions) for suggestions in grouped_suggestions.values())
        }
    
    async def _precompute_growth_roadmap(self, child_id: str, matched_traits: List[Dict], birthday: str) -> Dict:
        """Pre-compute growth milestone roadmap based on traits."""
        # Filter for Growth & Development traits (extract gene IDs)
        growth_genes = []
        for trait in matched_traits:
            if trait.get("archetype", "").lower() == "growth & development":
                gene = trait.get("gene", "")
                if gene and gene not in growth_genes:
                    growth_genes.append(gene)
        
        if not growth_genes:
            return {
                'child_id': child_id,
                'growth_genes': growth_genes,
                'roadmap': [],
                'message': "No Growth & Development traits found for this child"
            }
        
        # Load all milestones for the genes (static data)
        all_milestones = []
        for gene_id in growth_genes:
            gene_milestones = await self.growth_service.milestone_repo.get_milestones_for_gene(gene_id)
            all_milestones.extend(gene_milestones)
        
        if not all_milestones:
            return {
                'child_id': child_id,
                'growth_genes': growth_genes,
                'roadmap': [],
                'message': "No milestones found for this child's genetic traits"
            }
        
        # Group milestones by age ranges (this is static, age-independent)
        age_groups = {}
        
        for milestone in all_milestones:
            age_start = milestone.get("age_start", 0)
            age_end = milestone.get("age_end", 0)
            
            # Create age range key
            age_key = f"{age_start}-{age_end}"
            
            if age_key not in age_groups:
                age_groups[age_key] = {
                    "age_start": age_start,
                    "age_end": age_end,
                    "milestones": []
                }
            
            # Process food examples
            food_examples = milestone.get("food_examples", "")
            food_list = [food.strip() for food in food_examples.split(",") if food.strip()] if food_examples else []
            
            milestone_data = {
                "gene_id": milestone.get("gene_id", ""),
                "trait_name": milestone.get("trait_name", ""),
                "focus_description": milestone.get("focus_description", ""),
                "graphic_icon_id": milestone.get("graphic_icon_id", ""),
                "food_examples": food_list
            }
            
            age_groups[age_key]["milestones"].append(milestone_data)
        
        # Convert to sorted list (static roadmap structure)
        roadmap = []
        for age_key in sorted(age_groups.keys(), key=lambda x: int(x.split("-")[0])):
            age_group = age_groups[age_key]
            roadmap.append(age_group)
        
        return {
            'child_id': child_id,
            'birthday': birthday,  # Store birthday for future age calculations
            'growth_genes': growth_genes,
            'roadmap': roadmap
        }