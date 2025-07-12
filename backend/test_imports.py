#!/usr/bin/env python3
"""Test imports to find the blocking issue"""

print("Testing imports...")

try:
    print("1. Testing FastAPI...")
    from fastapi import FastAPI
    print("   ✅ FastAPI OK")
    
    print("2. Testing app.core.config...")
    from app.core.config import settings
    print("   ✅ Config OK")
    
    print("3. Testing app.core.database...")
    from app.core.database import get_db
    print("   ✅ Database OK")
    
    print("4. Testing app.repositories...")
    from app.repositories.user_repository import UserRepository
    print("   ✅ UserRepository OK")
    
    print("5. Testing app.services...")
    from app.services.auth_service import AuthService
    print("   ✅ AuthService OK")
    
    print("6. Testing app.api.auth...")
    from app.api import auth
    print("   ✅ Auth API OK")
    
    print("7. Testing app.api.children...")
    from app.api import children
    print("   ✅ Children API OK")
    
    print("8. Testing Firestore connection...")
    db = get_db()
    print(f"   ✅ Firestore connected: {db.project}")
    
    print("\n🎉 All imports successful!")
    
except Exception as e:
    print(f"❌ Import failed: {e}")
    import traceback
    traceback.print_exc()