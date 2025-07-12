#!/usr/bin/env python3
"""
Revert migration script to restore original codebase
"""

import os
import shutil


def main():
    print("🔄 Reverting to original codebase...")
    
    # Restore original files
    if os.path.exists("main_original.py"):
        shutil.copy("main_original.py", "main.py")
        print("✅ Restored original main.py")
    
    if os.path.exists("childprofile_original.py"):
        shutil.copy("childprofile_original.py", "childprofile.py")
        print("✅ Restored original childprofile.py")
    
    print("\n✨ Revert complete! Original codebase restored.")


if __name__ == "__main__":
    main()