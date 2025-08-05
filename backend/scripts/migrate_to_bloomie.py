#!/usr/bin/env python3
"""
Migrate existing data to the new bloomie structure.
This will move:
- users -> bloomie/data/users
- children -> bloomie/data/children  
- user_children -> bloomie/data/user_children
- logs -> move to individual child profiles
- conversations -> move to individual child profiles
- medical_visit_logs -> move to individual child profiles
"""

import os
import sys
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

def migrate_users():
    """Migrate users from root to bloomie/data/users."""
    print("👥 Migrating users...")
    
    # Get old users
    try:
        old_users = list(db.collection("users").stream())
        if not old_users:
            print("   ⏭️  No users to migrate")
            return
        
        # Copy to new location
        new_collection = db.collection("bloomie").document("data").collection("users")
        batch = db.batch()
        
        for user in old_users:
            user_data = user.to_dict()
            new_ref = new_collection.document(user.id)
            batch.set(new_ref, user_data)
        
        batch.commit()
        print(f"   ✅ Migrated {len(old_users)} users to bloomie/data/users")
        
        # Clean up old collection
        for user in old_users:
            user.reference.delete()
        print(f"   🗑️  Cleaned up old users collection")
        
    except Exception as e:
        print(f"   ⚠️  Error migrating users: {e}")

def migrate_user_children():
    """Migrate user_children mappings."""
    print("🔗 Migrating user-children mappings...")
    
    try:
        old_mappings = list(db.collection("user_children").stream())
        if not old_mappings:
            print("   ⏭️  No user-children mappings to migrate")
            return
        
        # Copy to new location
        new_collection = db.collection("bloomie").document("data").collection("user_children")
        batch = db.batch()
        
        for mapping in old_mappings:
            mapping_data = mapping.to_dict()
            new_ref = new_collection.document(mapping.id)
            batch.set(new_ref, mapping_data)
        
        batch.commit()
        print(f"   ✅ Migrated {len(old_mappings)} mappings to bloomie/data/user_children")
        
        # Clean up old collection
        for mapping in old_mappings:
            mapping.reference.delete()
        print(f"   🗑️  Cleaned up old user_children collection")
        
    except Exception as e:
        print(f"   ⚠️  Error migrating user-children mappings: {e}")

def migrate_children_and_nested_data():
    """Migrate children and their nested data (logs, conversations, medical_visit_logs)."""
    print("👶 Migrating children and their data...")
    
    try:
        # Get all existing children from old root collections
        old_children = {}
        
        # Collect children from various places (logs might reference child_ids)
        collections_to_check = ["logs", "conversations", "medical_visit_logs"]
        
        all_child_ids = set()
        
        for collection_name in collections_to_check:
            try:
                docs = list(db.collection(collection_name).stream())
                for doc in docs:
                    data = doc.to_dict()
                    child_id = data.get('child_id')
                    if child_id:
                        all_child_ids.add(child_id)
                        if child_id not in old_children:
                            old_children[child_id] = {
                                'logs': [],
                                'conversations': [],
                                'medical_visit_logs': [],
                                'report': {},
                                'traits': []
                            }
                        old_children[child_id][collection_name].append(data)
                print(f"   📋 Found {len(docs)} documents in {collection_name}")
            except Exception as e:
                print(f"   ⚠️  No {collection_name} collection found: {e}")
        
        if not all_child_ids:
            print("   ⏭️  No children data to migrate")
            return
        
        print(f"   👶 Found {len(all_child_ids)} unique children: {list(all_child_ids)}")
        
        # Create children in new structure
        children_collection = db.collection("bloomie").document("data").collection("children")
        
        for child_id, child_data in old_children.items():
            print(f"   📝 Migrating child {child_id}...")
            
            # Create child document with all data
            child_ref = children_collection.document(child_id)
            child_doc = {
                'child_id': child_id,
                'created_at': firestore.SERVER_TIMESTAMP
            }
            
            # Add any existing data
            if child_data['logs']:
                child_doc['logs'] = child_data['logs']
            if child_data['conversations']:
                child_doc['conversations'] = child_data['conversations']  
            if child_data['medical_visit_logs']:
                child_doc['medical_visit_logs'] = child_data['medical_visit_logs']
            
            child_ref.set(child_doc)
            print(f"     ✅ Created child profile for {child_id}")
        
        # Clean up old collections
        for collection_name in collections_to_check:
            try:
                docs = list(db.collection(collection_name).stream())
                for doc in docs:
                    doc.reference.delete()
                print(f"   🗑️  Cleaned up old {collection_name} collection ({len(docs)} docs)")
            except:
                pass
                
    except Exception as e:
        print(f"   ⚠️  Error migrating children: {e}")

def verify_migration():
    """Verify the migration was successful."""
    print("\n📊 Verifying migration...")
    
    try:
        # Check bloomie structure
        bloomie_ref = db.collection("bloomie")
        data_ref = bloomie_ref.document("data")
        reference_ref = bloomie_ref.document("reference")
        
        # Check data collections
        data_collections = ["users", "user_children", "children"]
        for collection_name in data_collections:
            try:
                docs = list(data_ref.collection(collection_name).stream())
                print(f"   bloomie/data/{collection_name}: {len(docs)} documents")
            except:
                print(f"   bloomie/data/{collection_name}: 0 documents")
        
        # Check reference collections  
        reference_collections = ["trait_references", "growth_milestones", "immunity_suggestions"]
        for collection_name in reference_collections:
            try:
                docs = list(reference_ref.collection(collection_name).stream())
                print(f"   bloomie/reference/{collection_name}: {len(docs)} documents")
            except:
                print(f"   bloomie/reference/{collection_name}: 0 documents")
                
    except Exception as e:
        print(f"   ⚠️  Error verifying migration: {e}")

def main():
    """Main migration function."""
    print("🚀 Starting migration to bloomie structure...")
    
    try:
        migrate_users()
        migrate_user_children()
        migrate_children_and_nested_data()
        verify_migration()
        
        print("\n🎉 Migration to bloomie structure complete!")
        print("   📁 Structure: bloomie/data/* and bloomie/reference/*")
        print("   👥 Users moved to bloomie/data/users")
        print("   👶 Children and their data consolidated under bloomie/data/children")
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()