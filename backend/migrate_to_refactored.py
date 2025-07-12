#!/usr/bin/env python3
"""
Migration script to test the refactored codebase
Run this to switch from the old main.py to the new structure
"""

import os
import shutil
import sys


def main():
    print("🔄 Starting migration to refactored codebase...")
    
    # Backup original files
    if os.path.exists("main.py") and not os.path.exists("main_original.py"):
        shutil.copy("main.py", "main_original.py")
        print("✅ Backed up original main.py to main_original.py")
    
    if os.path.exists("childprofile.py") and not os.path.exists("childprofile_original.py"):
        shutil.copy("childprofile.py", "childprofile_original.py")
        print("✅ Backed up original childprofile.py to childprofile_original.py")
    
    # Replace main.py with new version
    if os.path.exists("main_new.py"):
        shutil.copy("main_new.py", "main.py")
        print("✅ Replaced main.py with refactored version")
    
    print("\n📁 New folder structure created:")
    print("├── app/")
    print("│   ├── api/          # API routes")
    print("│   ├── core/         # Core configuration and security")
    print("│   ├── models/       # Data models")
    print("│   ├── services/     # Business logic")
    print("│   ├── repositories/ # Database access")
    print("│   ├── schemas/      # Pydantic schemas")
    print("│   └── agents/       # AI agent logic")
    print("└── tests/")
    
    print("\n✨ Migration complete! You can now:")
    print("1. Run: python main.py")
    print("2. Test new endpoints:")
    print("   - GET /children/{child_id}/recommendations-history")
    print("   - POST /children/{child_id}/emergency-checkin")
    print("\nTo revert: python revert_migration.py")


if __name__ == "__main__":
    main()