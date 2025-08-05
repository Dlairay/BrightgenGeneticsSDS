#!/usr/bin/env python3
"""
Upload reference data from CSV files to Firestore under 'reference' collection.
This script uploads:
- trait_references (from veetwo_genotype_trait_reference.csv)
- growth_milestones (from growthmilestones.csv)  
- immunity_suggestions (from immunity_resilience_suggestions.csv)
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

def upload_trait_references():
    """Upload trait references from CSV to reference/trait_references."""
    print("📋 Uploading trait references...")
    
    csv_path = "database/genotype_trait_reference.csv"
    collection_ref = db.collection("bloomie").document("reference").collection("trait_references")
    
    # Clear existing data
    docs = collection_ref.stream()
    batch = db.batch()
    count = 0
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
    if count % 500 != 0:
        batch.commit()
    print(f"   🗑️  Cleared {count} existing documents")
    
    # Upload new data
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        batch = db.batch()
        count = 0
        
        for row in reader:
            doc_ref = collection_ref.document()
            batch.set(doc_ref, {
                'rs_id': row['rs_id'],
                'gene': row['gene'],
                'genotype': row['genotype'],
                'trait_id': row['trait_id'],
                'trait_name': row['trait_name'],
                'description': row['description'],
                'confidence': float(row['confidence']) if row['confidence'] else 0.0,
                'recommendation': row['recommendation'],
                'archetype': row['archetype'],
                'created_at': firestore.SERVER_TIMESTAMP
            })
            count += 1
            
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                print(f"   📤 Uploaded {count} trait references...")
        
        if count % 500 != 0:
            batch.commit()
    
    print(f"   ✅ Uploaded {count} trait references")
    return count

def upload_growth_milestones():
    """Upload growth milestones from CSV to reference/growth_milestones."""
    print("📋 Uploading growth milestones...")
    
    csv_path = "database/growthmilestones.csv"
    collection_ref = db.collection("bloomie").document("reference").collection("growth_milestones")
    
    # Clear existing data
    docs = collection_ref.stream()
    batch = db.batch()
    count = 0
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
    if count % 500 != 0:
        batch.commit()
    print(f"   🗑️  Cleared {count} existing documents")
    
    # Upload new data
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        batch = db.batch()
        count = 0
        
        for row in reader:
            doc_ref = collection_ref.document()
            batch.set(doc_ref, {
                'gene_id': row['gene_id'],
                'trait_name': row['trait_name'],
                'age_start': int(row['age_start']) if row['age_start'] else 0,
                'age_end': int(row['age_end']) if row['age_end'] else 0,
                'focus_description': row['focus_description'],
                'graphic_icon_id': row['graphic_icon_id'],
                'food_examples': row['food_examples'],
                'created_at': firestore.SERVER_TIMESTAMP
            })
            count += 1
            
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                print(f"   📤 Uploaded {count} growth milestones...")
        
        if count % 500 != 0:
            batch.commit()
    
    print(f"   ✅ Uploaded {count} growth milestones")
    return count

def upload_immunity_suggestions():
    """Upload immunity suggestions from CSV to reference/immunity_suggestions."""
    print("📋 Uploading immunity suggestions...")
    
    csv_path = "database/immunity_resilience_suggestions.csv"
    collection_ref = db.collection("bloomie").document("reference").collection("immunity_suggestions")
    
    # Clear existing data
    docs = collection_ref.stream()
    batch = db.batch()
    count = 0
    for doc in docs:
        batch.delete(doc.reference)
        count += 1
        if count % 500 == 0:
            batch.commit()
            batch = db.batch()
    if count % 500 != 0:
        batch.commit()
    print(f"   🗑️  Cleared {count} existing documents")
    
    # Upload new data
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        batch = db.batch()
        count = 0
        
        for row in reader:
            doc_ref = collection_ref.document()
            batch.set(doc_ref, {
                'archetype': row['archetype'],
                'trait_name': row['trait_name'],
                'suggestion_type': row['suggestion_type'],
                'suggestion': row['suggestion'],
                'rationale': row['rationale'],
                'created_at': firestore.SERVER_TIMESTAMP
            })
            count += 1
            
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
                print(f"   📤 Uploaded {count} immunity suggestions...")
        
        if count % 500 != 0:
            batch.commit()
    
    print(f"   ✅ Uploaded {count} immunity suggestions")
    return count

def verify_uploads():
    """Verify the uploads completed successfully."""
    print("\n📊 Verifying uploads...")
    
    collections = [
        ("trait_references", "trait references"),
        ("growth_milestones", "growth milestones"),
        ("immunity_suggestions", "immunity suggestions")
    ]
    
    for collection_name, display_name in collections:
        collection_ref = db.collection("bloomie").document("reference").collection(collection_name)
        docs = list(collection_ref.stream())
        print(f"   bloomie/reference/{collection_name}: {len(docs)} {display_name}")

def main():
    """Main function."""
    print("🚀 Starting reference data upload to Firestore...")
    print("   Target structure: bloomie/reference/{collection_name}")
    
    try:
        total_uploaded = 0
        
        # Upload all reference data
        total_uploaded += upload_trait_references()
        total_uploaded += upload_growth_milestones() 
        total_uploaded += upload_immunity_suggestions()
        
        # Verify uploads
        verify_uploads()
        
        print(f"\n🎉 SUCCESS! Reference data upload complete")
        print(f"   📤 Total documents uploaded: {total_uploaded}")
        print(f"   📁 Data structure: bloomie/reference/{{collection_name}}")
        print(f"   🔗 User data remains at root level (users, children, logs, etc.)")
        
    except Exception as e:
        print(f"\n❌ Upload failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()