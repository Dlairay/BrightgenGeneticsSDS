from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import List, Dict, Optional, Any
import json
import os
import tempfile
import asyncio
from datetime import datetime, timedelta
import jwt
from passlib.context import CryptContext
from google.cloud import firestore
import uvicorn

# Import your existing modules
from childprofile import ChildProfile, create_child_profile, load_trait_db_from_firestore, _convert_firestore_timestamps_to_strings
from planner_agent.agent import LogGenerationService, run_for_child

# Initialize FastAPI app
app = FastAPI(title="Child Genetic Profiling API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security setup
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Initialize Firestore
db = firestore.Client()

# Pydantic models
class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class User(BaseModel):
    id: str
    name: str
    email: str

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

# Authentication functions
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        
        # Get user from Firestore
        user_doc = db.collection("users").document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(status_code=401, detail="User not found")
        
        user_data = user_doc.to_dict()
        return User(id=user_id, name=user_data["name"], email=user_data["email"])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

# User authentication endpoints
@app.post("/auth/register", response_model=Token)
async def register(user_data: UserCreate):
    try:
        # Check if user already exists
        users_ref = db.collection("users")
        existing_user = users_ref.where("email", "==", user_data.email).limit(1).get()
        
        if len(list(existing_user)) > 0:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create new user
        hashed_password = get_password_hash(user_data.password)
        user_doc = {
            "name": user_data.name,
            "email": user_data.email,
            "password": hashed_password,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        
        user_ref = users_ref.add(user_doc)
        user_id = user_ref[1].id
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        
        return {"access_token": access_token, "token_type": "bearer"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@app.post("/auth/login", response_model=Token)
async def login(user_data: UserLogin):
    try:
        # Find user by email
        users_ref = db.collection("users")
        user_docs = users_ref.where("email", "==", user_data.email).limit(1).get()
        
        if len(list(user_docs)) == 0:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        user_doc = list(user_docs)[0]
        user_data_db = user_doc.to_dict()
        
        # Verify password
        if not verify_password(user_data.password, user_data_db["password"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user_doc.id}, expires_delta=access_token_expires
        )
        
        return {"access_token": access_token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")

# Child management endpoints
@app.get("/children", response_model=List[Child])
async def get_children(current_user: User = Depends(get_current_user)):
    try:
        # Get children associated with the current user
        children_ref = db.collection("user_children").where("user_id", "==", current_user.id)
        children_docs = children_ref.get()
        
        children = []
        for doc in children_docs:
            child_data = doc.to_dict()
            child_id = child_data["child_id"]
            
            # Get child profile
            profile_doc = db.collection("profiles").document(child_id).get()
            if profile_doc.exists:
                profile_data = profile_doc.to_dict()
                report_data = profile_data.get("report", {})
                
                children.append(Child(
                    id=child_id,
                    name=report_data.get("name", f"Child {child_id}"),
                    birthday=report_data.get("birthday", ""),
                    gender=report_data.get("gender", "")
                ))
        
        return children
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get children: {str(e)}")

@app.post("/children/upload-genetic-report")
async def upload_genetic_report(
    file: UploadFile = File(...),
    child_name: str = Form(...),
    current_user: User = Depends(get_current_user)
):
    try:
        # Read uploaded file
        content = await file.read()
        
        # Create temporary file for processing
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as temp_file:
            temp_file.write(content.decode('utf-8'))
            temp_file_path = temp_file.name
        
        try:
            # Load and validate JSON
            with open(temp_file_path, 'r') as f:
                genetic_data = json.load(f)
            
            # Add child name to the data
            genetic_data["name"] = child_name
            
            # Validate required fields
            required_fields = ["child_id", "birthday", "gender", "genotype_profile"]
            for field in required_fields:
                if field not in genetic_data:
                    raise HTTPException(status_code=400, detail=f"Missing required field: {field}")
            
            # Save updated data back to temp file
            with open(temp_file_path, 'w') as f:
                json.dump(genetic_data, f)
            
            # Create child profile using your existing function
            child_profile, entry = await create_child_profile(temp_file_path)
            
            # Associate child with user
            user_child_doc = {
                "user_id": current_user.id,
                "child_id": genetic_data["child_id"],
                "created_at": firestore.SERVER_TIMESTAMP
            }
            db.collection("user_children").add(user_child_doc)
            
            return {
                "message": "Genetic report uploaded successfully",
                "child_id": genetic_data["child_id"],
                "initial_log_created": True
            }
            
        finally:
            # Clean up temporary file
            os.unlink(temp_file_path)
            
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON file")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process genetic report: {str(e)}")

# Check-in endpoints
@app.get("/children/{child_id}/check-in/questions")
async def get_check_in_questions(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Verify user has access to this child
        user_child_ref = db.collection("user_children").where("user_id", "==", current_user.id).where("child_id", "==", child_id).limit(1).get()
        if len(list(user_child_ref)) == 0:
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Load trait database
        trait_db = await load_trait_db_from_firestore()
        if trait_db.empty:
            raise HTTPException(status_code=500, detail="Trait database not available")
        
        # Get child profile
        child_profile = ChildProfile(child_id=child_id, trait_db=trait_db)
        
        # Load logs to get the latest entry
        logs = child_profile.load_logs()
        if not logs:
            raise HTTPException(status_code=404, detail="No logs found for this child")
        
        latest_log = logs[-1]
        followup_questions = latest_log.get('followup_questions', [])
        
        if not followup_questions:
            return {"questions": [], "message": "No follow-up questions available"}
        
        # Normalize questions to ensure they have options
        normalized_questions = []
        log_service = LogGenerationService()
        session_id = f"session_{child_id}"
        await log_service._ensure_session(session_id)
        
        for item in followup_questions:
            if isinstance(item, str):
                # Generate options for string questions
                opts = await log_service._generate_question_options(
                    item, latest_log['interpreted_traits'], session_id
                )
                normalized_questions.append({
                    "question": item,
                    "options": opts
                })
            else:
                normalized_questions.append(item)
        
        return {"questions": normalized_questions}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get check-in questions: {str(e)}")

# main.py

# main.py

@app.post("/children/{child_id}/check-in/submit")
async def submit_check_in(
    child_id: str,
    answers: CheckInAnswers,
    current_user: User = Depends(get_current_user)
):
    try:
        # Verify user has access to this child
        user_child_ref = db.collection("user_children").where("user_id", "==", current_user.id).where("child_id", "==", child_id).limit(1).get()
        if len(list(user_child_ref)) == 0:
            raise HTTPException(status_code=403, detail="Access denied to this child")

        # FIX: Load the trait database from Firestore
        trait_db = await load_trait_db_from_firestore()
        if trait_db.empty:
            raise HTTPException(status_code=500, detail="Trait database not available")

        # Get child profile
        child_profile = ChildProfile(child_id=child_id, trait_db=trait_db)

        # Load logs and get latest entry
        logs = child_profile.load_logs()
        if not logs:
            raise HTTPException(status_code=404, detail="No logs found for this child")
        
        # Convert Firestore timestamps to JSON-serializable strings for the agent
        logs_for_agent = _convert_firestore_timestamps_to_strings(logs)
        latest_log = logs_for_agent[-1]
        
        # ... (the rest of the function remains the same) ...
        answer_dict = {answer.question: answer.answer for answer in answers.answers}
        
        child_report = child_profile.load_report()
        child_age = child_profile.get_derived_age()
        child_gender = child_report.get("gender")
        
        log_service = LogGenerationService()
        session_id = f"session_{child_id}"
        await log_service._ensure_session(session_id)
        
        new_entry = await log_service._generate_followup_entry(
            latest_log['interpreted_traits'],
            answer_dict,
            session_id,
            logs_for_agent,
            derived_age=child_age,
            gender=child_gender
        )
        
        child_profile.save_log(new_entry)
        
        return {
            "message": "Check-in completed successfully",
            "recommendations": new_entry.get('recommendations', []),
            "summary": new_entry.get('summary', '')
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit check-in: {str(e)}")

# Get child profile endpoint
@app.get("/children/{child_id}/profile")
async def get_child_profile(
    child_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Verify user has access to this child
        user_child_ref = db.collection("user_children").where("user_id", "==", current_user.id).where("child_id", "==", child_id).limit(1).get()
        if len(list(user_child_ref)) == 0:
            raise HTTPException(status_code=403, detail="Access denied to this child")
        
        # Load trait database
        trait_db = await load_trait_db_from_firestore()
        if trait_db.empty:
            raise HTTPException(status_code=500, detail="Trait database not available")
        
        # Get child profile
        child_profile = ChildProfile(child_id=child_id, trait_db=trait_db)
        
        return child_profile.to_json()
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get child profile: {str(e)}")

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)