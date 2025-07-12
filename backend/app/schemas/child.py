from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime


class Child(BaseModel):
    id: str
    name: str
    birthday: str
    gender: str


class QuestionResponse(BaseModel):
    question: str
    answer: str


class CheckInAnswers(BaseModel):
    answers: List[QuestionResponse]


class GeneticReportData(BaseModel):
    child_id: str
    birthday: str
    gender: str
    genotype_profile: List[Dict[str, str]]


class Recommendation(BaseModel):
    trait: str
    goal: str
    activity: str


class FollowupQuestion(BaseModel):
    question: str
    options: List[str]


class RecommendationHistory(BaseModel):
    timestamp: datetime
    recommendations: List[Recommendation]
    summary: str
    entry_type: str