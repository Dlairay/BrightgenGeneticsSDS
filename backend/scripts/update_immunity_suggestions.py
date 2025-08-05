#!/usr/bin/env python3
"""
Script to update immunity suggestions in Firestore with concise version.
This will DELETE all existing suggestions and replace with new ones.
"""

import os
import sys
import csv
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from google.cloud import firestore
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Firestore with service account
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'servicekey.json'
db = firestore.Client()

# Collection name with veetwo prefix
COLLECTION_NAME = 'veetwo_immunity_suggestions'

def delete_existing_suggestions():
    """Delete all existing immunity suggestions."""
    print("🗑️  Deleting existing immunity suggestions...")
    
    # Get all documents in the collection
    docs = db.collection(COLLECTION_NAME).stream()
    
    # Delete each document
    batch = db.batch()
    count = 0
    
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        
        # Commit every 500 deletes (Firestore batch limit)
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
            print(f"   Deleted {count} documents...")
    
    # Commit remaining deletes
    if count % 500 != 0:
        batch.commit()
    
    print(f"✅ Deleted {count} existing suggestions")
    return count

def upload_concise_suggestions():
    """Upload the concise immunity suggestions to Firestore."""
    # Read the concise CSV
    csv_path = Path(__file__).parent.parent / 'database' / 'immunity_resilience_suggestions_concise.csv'
    
    if not csv_path.exists():
        print(f"❌ Error: CSV file not found at {csv_path}")
        sys.exit(1)
    
    # Read CSV file
    suggestions = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        csv_reader = csv.DictReader(f)
        suggestions = list(csv_reader)
    
    print(f"📊 Loaded {len(suggestions)} concise suggestions from CSV")
    
    # Upload each row as a document
    batch = db.batch()
    count = 0
    
    for row in suggestions:
        # Create document data
        doc_data = {
            'archetype': row['archetype'],
            'trait_name': row['trait_name'],
            'suggestion_type': row['suggestion_type'],
            'suggestion': row['suggestion'],
            'rationale': row['rationale']
        }
        
        # Create a document with auto-generated ID
        doc_ref = db.collection(COLLECTION_NAME).document()
        batch.set(doc_ref, doc_data)
        count += 1
        
        # Commit every 500 writes
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
            print(f"   Uploaded {count} documents...")
    
    # Commit remaining writes
    if count % 500 != 0:
        batch.commit()
    
    print(f"✅ Successfully uploaded {count} concise suggestions")
    
    # Verify the upload
    verify_count = len(list(db.collection(COLLECTION_NAME).stream()))
    print(f"📋 Verification: {verify_count} documents now in collection")
    
    # Show sample of what was uploaded
    print("\n📝 Sample of uploaded suggestions:")
    sample_docs = db.collection(COLLECTION_NAME).limit(3).stream()
    for doc in sample_docs:
        data = doc.to_dict()
        print(f"   - {data['trait_name']} ({data['suggestion_type']}): {data['suggestion'][:60]}...")

def main():
    """Main function to update immunity suggestions."""
    print("🚀 Starting immunity suggestions update...")
    print(f"📍 Target collection: {COLLECTION_NAME}")
    print("⚠️  This will DELETE all existing suggestions and replace with concise version.")
    print("✅ Proceeding with update...")
    
    try:
        # Step 1: Delete existing suggestions
        deleted_count = delete_existing_suggestions()
        
        # Step 2: Upload new concise suggestions
        upload_concise_suggestions()
        
        print("\n✨ Update complete!")
        print(f"   - Removed {deleted_count} verbose suggestions")
        print(f"   - Added 8 concise suggestions")
        
    except Exception as e:
        print(f"\n❌ Error during update: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()