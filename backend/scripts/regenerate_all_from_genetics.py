#!/usr/bin/env python3
"""
STANDALONE CI/CD PIPELINE - Regenerate All Data from Genetics CSV
================================================================

This script regenerates all derivative data files from genotype_trait_reference.csv:
1. Reads genotype_trait_reference.csv (entry point)
2. Uses AI to generate growth_milestones.csv (preserving exact structure)
3. Uses AI to generate immunity_resilience_suggestions.csv (preserving exact structure)
4. Regenerates immunity regex patterns
5. Shows preview of changes (does NOT upload to Firestore)

CRITICAL: Maintains exact CSV column structure to avoid breaking backend code.

Usage:
    python scripts/regenerate_all_from_genetics.py
    
Prerequisites:
    pip install openai pandas python-dotenv
    
Environment Variables:
    OPENAI_API_KEY=your_openai_key (or set in .env file)
"""

import os
import sys
import csv
import json
import pandas as pd
import re
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

# Try to import OpenAI (user needs to install)
try:
    from openai import OpenAI
except ImportError:
    print("❌ Error: OpenAI package not installed")
    print("Please run: pip install openai")
    sys.exit(1)

# Load environment variables
load_dotenv()

class GeneticsDataPipeline:
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.database_dir = self.base_dir / "database"
        self.genetics_csv = self.database_dir / "genotype_trait_reference.csv"
        self.growth_csv = self.database_dir / "growthmilestones.csv"
        self.immunity_csv = self.database_dir / "immunity_resilience_suggestions.csv"
        self.regex_config = self.base_dir / "app" / "core" / "immunity_regex_config.json"
        
        # Initialize OpenAI client
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            print("❌ Error: OPENAI_API_KEY not found in environment variables")
            print("Please set OPENAI_API_KEY in your .env file or environment")
            sys.exit(1)
        
        self.client = OpenAI(api_key=api_key)
        
        print("🚀 Genetics Data Pipeline Initialized")
        print(f"📂 Database directory: {self.database_dir}")
    
    def load_genetics_data(self):
        """Load the entry point genetics CSV"""
        if not self.genetics_csv.exists():
            print(f"❌ Error: {self.genetics_csv} not found")
            sys.exit(1)
        
        print(f"📖 Loading genetics data from {self.genetics_csv}")
        df = pd.read_csv(self.genetics_csv)
        print(f"✅ Loaded {len(df)} genetic traits")
        
        # Show sample of data
        print("\n📊 Sample genetics data:")
        print(df.head(3).to_string())
        print(f"\n📋 Columns: {list(df.columns)}")
        
        return df
    
    def analyze_existing_structure(self, csv_path, name):
        """Analyze existing CSV structure to maintain compatibility"""
        if not csv_path.exists():
            print(f"⚠️  Warning: {csv_path} doesn't exist yet")
            return None, []
        
        df = pd.read_csv(csv_path)
        columns = list(df.columns)
        sample_data = df.head(2).to_dict('records') if len(df) > 0 else []
        
        print(f"📋 Existing {name} structure:")
        print(f"   Columns: {columns}")
        print(f"   Sample: {sample_data[:1] if sample_data else 'No data'}")
        
        return df, columns
    
    def generate_growth_milestones(self, genetics_df):
        """Generate growth milestones CSV using AI while preserving structure"""
        print("\n🌱 Generating Growth Milestones...")
        
        # Analyze existing structure
        existing_df, existing_columns = self.analyze_existing_structure(
            self.growth_csv, "Growth Milestones"
        )
        
        # Define expected structure based on your backend code
        expected_columns = [
            "gene_id", "trait_name", "age_start", "age_end", 
            "focus_description", "food_examples", "graphic_icon_id"
        ]
        
        if existing_columns and existing_columns != expected_columns:
            print(f"⚠️  Column mismatch detected!")
            print(f"   Expected: {expected_columns}")
            print(f"   Existing: {existing_columns}")
            response = input("Continue anyway? (y/n): ")
            if response.lower() != 'y':
                return None
        
        # Filter genetics data for Growth & Development archetype
        growth_traits = genetics_df[genetics_df['archetype'].str.lower() == 'growth & development']
        
        if len(growth_traits) == 0:
            print("❌ No Growth & Development traits found in genetics data")
            return None
        
        print(f"📊 Found {len(growth_traits)} Growth & Development traits")
        
        # Prepare AI prompt
        traits_summary = growth_traits[['gene', 'trait_name', 'description']].to_string()
        
        prompt = f'''
Generate growth milestone data for children based on these genetic traits.

CRITICAL: Output must be CSV format with EXACT columns: gene_id,trait_name,age_start,age_end,focus_description,food_examples,graphic_icon_id

Genetic Traits (Growth & Development):
{traits_summary}

Requirements:
1. Create age-based milestones for ages 0-1, 1-3, 3-5, 5-8, 8-12
2. gene_id = gene column from input
3. trait_name = trait_name from input  
4. age_start/age_end = numerical age ranges
5. focus_description = what to focus on for this age
6. food_examples = comma-separated food recommendations
7. graphic_icon_id = one of: brain_icon, tummy_icon, energy_icon, shield_icon, health_icon, idea_icon, school_icon, choices_icon, balance_icon, battery_icon

Generate 2-3 milestones per trait across different age ranges.
Output ONLY the CSV data, no explanations.
'''
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3
            )
            
            csv_content = response.choices[0].message.content.strip()
            
            # Save to temporary file first
            temp_file = self.database_dir / "growthmilestones_new.csv"
            with open(temp_file, 'w') as f:
                f.write(csv_content)
            
            # Validate generated CSV
            test_df = pd.read_csv(temp_file)
            print(f"✅ Generated {len(test_df)} growth milestones")
            print(f"📋 Columns: {list(test_df.columns)}")
            
            # Show preview
            print("\n📊 Preview of generated data:")
            print(test_df.head(3).to_string())
            
            return temp_file
            
        except Exception as e:
            print(f"❌ Error generating growth milestones: {e}")
            return None
    
    def generate_immunity_suggestions(self, genetics_df):
        """Generate immunity suggestions CSV using AI while preserving structure"""
        print("\n🛡️  Generating Immunity Suggestions...")
        
        # Analyze existing structure
        existing_df, existing_columns = self.analyze_existing_structure(
            self.immunity_csv, "Immunity Suggestions"
        )
        
        # Define expected structure
        expected_columns = [
            "trait_name", "suggestion_type", "suggestion", "rationale"
        ]
        
        if existing_columns and existing_columns != expected_columns:
            print(f"⚠️  Column mismatch detected!")
            print(f"   Expected: {expected_columns}")
            print(f"   Existing: {existing_columns}")
            response = input("Continue anyway? (y/n): ")
            if response.lower() != 'y':
                return None
        
        # Filter genetics data for Immunity & Resilience archetype
        immunity_traits = genetics_df[genetics_df['archetype'].str.lower() == 'immunity & resilience']
        
        if len(immunity_traits) == 0:
            print("❌ No Immunity & Resilience traits found in genetics data")
            return None
        
        print(f"📊 Found {len(immunity_traits)} Immunity & Resilience traits")
        
        # Prepare AI prompt
        traits_summary = immunity_traits[['gene', 'trait_name', 'description']].to_string()
        
        prompt = f'''
Generate immunity and resilience suggestions based on these genetic traits.

CRITICAL: Output must be CSV format with EXACT columns: trait_name,suggestion_type,suggestion,rationale

Genetic Traits (Immunity & Resilience):
{traits_summary}

Requirements:
1. trait_name = trait_name from input (exact match)
2. suggestion_type = either "Provide" or "Avoid" 
3. suggestion = specific actionable recommendation
4. rationale = scientific explanation why this helps/hurts

Generate 3-5 suggestions per trait (mix of Provide and Avoid).
Focus on nutrition, lifestyle, environmental factors.
Output ONLY the CSV data, no explanations.
'''
        
        try:
            response = self.client.chat.completions.create(
                model="gpt-4o-mini", 
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3
            )
            
            csv_content = response.choices[0].message.content.strip()
            
            # Save to temporary file first
            temp_file = self.database_dir / "immunity_resilience_suggestions_new.csv"
            with open(temp_file, 'w') as f:
                f.write(csv_content)
            
            # Validate generated CSV
            test_df = pd.read_csv(temp_file)
            print(f"✅ Generated {len(test_df)} immunity suggestions")
            print(f"📋 Columns: {list(test_df.columns)}")
            
            # Show preview
            print("\n📊 Preview of generated data:")
            print(test_df.head(3).to_string())
            
            return temp_file
            
        except Exception as e:
            print(f"❌ Error generating immunity suggestions: {e}")
            return None
    
    def generate_immunity_regex(self, immunity_csv_path):
        """Generate regex patterns for immunity trait detection"""
        print("\n🔍 Generating Immunity Regex Patterns...")
        
        if not immunity_csv_path or not immunity_csv_path.exists():
            print("❌ No immunity suggestions file to process")
            return None
        
        # Read immunity suggestions
        df = pd.read_csv(immunity_csv_path)
        
        # Extract unique trait names
        trait_names = df['trait_name'].unique()
        print(f"📊 Found {len(trait_names)} unique immunity traits")
        
        # Generate regex pattern (same logic as your existing script)
        escaped_names = [re.escape(name.strip()) for name in trait_names if name.strip()]
        pattern = '|'.join(escaped_names)
        
        # Create regex config
        regex_config = {
            "immunity_traits_pattern": pattern,
            "trait_names": sorted([name.strip() for name in trait_names if name.strip()]),
            "generated_at": datetime.now().isoformat(),
            "total_traits": len(trait_names)
        }
        
        # Save to temporary file
        temp_config = self.base_dir / "immunity_regex_config_new.json"
        with open(temp_config, 'w') as f:
            json.dump(regex_config, f, indent=2)
        
        print(f"✅ Generated regex for {len(trait_names)} traits")
        print(f"📝 Pattern length: {len(pattern)} characters")
        
        return temp_config
    
    def show_summary(self, growth_file, immunity_file, regex_file):
        """Show summary of all generated files"""
        print("\n" + "="*60)
        print("📋 PIPELINE SUMMARY")
        print("="*60)
        
        print(f"📂 Generated files:")
        if growth_file and growth_file.exists():
            growth_df = pd.read_csv(growth_file)
            print(f"   🌱 {growth_file.name}: {len(growth_df)} records")
        
        if immunity_file and immunity_file.exists():
            immunity_df = pd.read_csv(immunity_file)
            print(f"   🛡️  {immunity_file.name}: {len(immunity_df)} records")
        
        if regex_file and regex_file.exists():
            print(f"   🔍 {regex_file.name}: Generated")
        
        print(f"\n📁 Files location: {self.database_dir}")
        print(f"\n⚠️  IMPORTANT: Review generated files before replacing originals!")
        print(f"⚠️  Files are saved with '_new' suffix for safety")
        
        print(f"\n🔄 To apply changes:")
        print(f"   1. Review the generated files")
        print(f"   2. Backup your current files")
        print(f"   3. Replace originals with new versions")
        print(f"   4. Run upload_reference_data.py to update Firestore")
    
    def run(self):
        """Run the complete pipeline"""
        print("🚀 Starting Genetics Data Pipeline")
        print("="*50)
        
        # Step 1: Load genetics data
        genetics_df = self.load_genetics_data()
        
        # Step 2: Generate growth milestones
        growth_file = self.generate_growth_milestones(genetics_df)
        
        # Step 3: Generate immunity suggestions  
        immunity_file = self.generate_immunity_suggestions(genetics_df)
        
        # Step 4: Generate immunity regex
        regex_file = self.generate_immunity_regex(immunity_file)
        
        # Step 5: Show summary
        self.show_summary(growth_file, immunity_file, regex_file)
        
        return growth_file, immunity_file, regex_file

def main():
    """Main entry point"""
    print("🧬 Genetics Data CI/CD Pipeline")
    print("=" * 50)
    
    try:
        pipeline = GeneticsDataPipeline()
        pipeline.run()
        
    except KeyboardInterrupt:
        print("\n⏹️  Pipeline interrupted by user")
    except Exception as e:
        print(f"\n❌ Pipeline failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()