from fastapi import APIRouter, HTTPException
import logging
from app.schemas.user import UserCreate, UserLogin, Token
from app.services.auth_service import AuthService

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])
auth_service = AuthService()


@router.post("/register", response_model=Token)
async def register(user_data: UserCreate):
    logger.info(f"🔐 REGISTER REQUEST: email={user_data.email}, name={user_data.name}")
    try:
        result = await auth_service.register(user_data)
        logger.info(f"✅ REGISTER SUCCESS: email={user_data.email}")
        return result
    except ValueError as e:
        logger.error(f"❌ REGISTER VALIDATION ERROR: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"💥 REGISTER UNEXPECTED ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


@router.post("/login", response_model=Token)
async def login(user_data: UserLogin):
    logger.info(f"🔑 LOGIN REQUEST: email={user_data.email}")
    try:
        result = await auth_service.login(user_data)
        logger.info(f"✅ LOGIN SUCCESS: email={user_data.email}")
        return result
    except ValueError as e:
        logger.error(f"❌ LOGIN VALIDATION ERROR: {str(e)}")
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"💥 LOGIN UNEXPECTED ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")