import json
import tempfile
import os
from typing import List, Dict, Optional

from app.models.child_profile import ChildProfile
from app.repositories.child_repository import ChildRepository, _convert_firestore_timestamps_to_strings
from app.repositories.trait_repository import TraitRepository
from app.schemas.child import Child, CheckInAnswers, RecommendationHistory
from app.agents.planner_agent.agent import LogGenerationService


class ChildService:
    def __init__(self):
        self.child_repo = ChildRepository()
        self.trait_repo = TraitRepository()
        self.log_service = LogGenerationService()
    
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
        
        latest_log = logs[-1]
        followup_questions = latest_log.get('followup_questions', [])
        
        if not followup_questions:
            return {"questions": [], "message": "No follow-up questions available"}
        
        normalized_questions = []
        session_id = f"session_{child_id}"
        await self.log_service._ensure_session(session_id)
        
        for item in followup_questions:
            if isinstance(item, str):
                opts = await self.log_service._generate_question_options(
                    item, latest_log['interpreted_traits'], session_id
                )
                normalized_questions.append({
                    "question": item,
                    "options": opts
                })
            else:
                normalized_questions.append(item)
        
        return {"questions": normalized_questions}
    
    async def submit_check_in(self, child_id: str, answers: CheckInAnswers) -> Dict:
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait database not available")
        
        logs = await self.child_repo.load_logs(child_id)
        if not logs:
            raise ValueError("No logs found for this child")
        
        logs_for_agent = _convert_firestore_timestamps_to_strings(logs)
        latest_log = logs_for_agent[-1]
        
        answer_dict = {answer.question: answer.answer for answer in answers.answers}
        
        report_data = await self.child_repo.load_report(child_id)
        child_profile = ChildProfile(child_id, trait_db)
        child_profile.report = report_data
        
        child_age = child_profile.get_derived_age()
        child_gender = report_data.get("gender")
        
        session_id = f"session_{child_id}"
        await self.log_service._ensure_session(session_id)
        
        new_entry = await self.log_service._generate_followup_entry(
            latest_log['interpreted_traits'],
            answer_dict,
            session_id,
            logs_for_agent,
            derived_age=child_age,
            gender=child_gender
        )
        
        await self.child_repo.save_log(child_id, new_entry)
        
        return {
            "message": "Check-in completed successfully",
            "recommendations": new_entry.get('recommendations', []),
            "summary": new_entry.get('summary', '')
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
    
    async def emergency_check_in(self, child_id: str) -> Dict:
        trait_db = await self.trait_repo.load_trait_db()
        if trait_db.empty:
            raise RuntimeError("Trait database not available")
        
        traits_data = await self.child_repo.load_traits(child_id)
        report_data = await self.child_repo.load_report(child_id)
        logs = await self.child_repo.load_logs(child_id)
        
        child_profile = ChildProfile(child_id, trait_db)
        child_profile.report = report_data
        
        derived_age = child_profile.get_derived_age()
        gender = report_data.get("gender")
        
        session_id = f"emergency_{child_id}"
        await self.log_service._ensure_session(session_id)
        
        emergency_entry = await self.log_service.generate_initial_log(
            traits_data,
            derived_age=derived_age,
            gender=gender
        )
        
        emergency_entry['entry_type'] = 'emergency'
        
        await self.child_repo.save_log(child_id, emergency_entry)
        
        return {
            "message": "Emergency check-in completed",
            "recommendations": emergency_entry.get('recommendations', []),
            "summary": emergency_entry.get('summary', ''),
            "followup_questions": emergency_entry.get('followup_questions', [])
        }