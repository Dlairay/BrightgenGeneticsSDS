#!/usr/bin/env python3
"""
Generate regex pattern for detecting immunity & resilience trait names in text.
Run this script whenever the immunity_resilience_suggestions.csv is updated.
"""

import pandas as pd
import re
import json

def generate_immunity_regex():
    """Generate regex pattern from immunity trait names in CSV."""
    # Read the CSV
    df = pd.read_csv('database/immunity_resilience_suggestions.csv')
    
    # Get unique trait names
    trait_names = df['trait_name'].unique()
    
    # Sort by length (longest first) to ensure longer matches take precedence
    trait_names = sorted(trait_names, key=len, reverse=True)
    
    # Escape special regex characters and create pattern
    escaped_names = [re.escape(name) for name in trait_names]
    
    # Create regex pattern with word boundaries and case-insensitive matching
    # Using \b for word boundaries to avoid partial matches
    pattern_parts = []
    
    # First add the full trait names
    for name in escaped_names:
        pattern_parts.append(f"\\b{name}\\b")
    
    # Then add key medical terms that should trigger the check
    key_terms = ['asthma', 'eczema', 'uv sensitivity', 'sun sensitivity', 'red hair']
    for term in key_terms:
        pattern_parts.append(f"\\b{re.escape(term)}\\b")
    
    # Remove duplicates while preserving order
    pattern_parts = list(dict.fromkeys(pattern_parts))
    
    # Join with OR operator
    pattern = '|'.join(pattern_parts)
    
    # Compile with case-insensitive flag
    compiled_pattern = re.compile(pattern, re.IGNORECASE)
    
    return {
        'pattern_string': pattern,
        'trait_names': list(trait_names),
        'compiled_pattern': compiled_pattern
    }

def save_regex_config(regex_data):
    """Save regex configuration to a file for use by the application."""
    config = {
        'pattern': regex_data['pattern_string'],
        'trait_names': regex_data['trait_names'],
        'generated_at': pd.Timestamp.now().isoformat()
    }
    
    with open('app/core/immunity_regex_config.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"✅ Saved regex configuration to app/core/immunity_regex_config.json")

def test_regex(compiled_pattern, trait_names):
    """Test the regex with sample texts."""
    test_texts = [
        "My child has been dealing with asthma issues lately",
        "We're concerned about eczema flare-ups",
        "The doctor mentioned UV sensitivity due to red hair",
        "No health issues mentioned here",
        "My daughter's ASTHMA SEVERITY has increased",
        "Looking for advice on managing eczema risk",
        "Questions about asthma susceptibility in children"
    ]
    
    print("\n🧪 Testing regex pattern:")
    print("=" * 60)
    
    for text in test_texts:
        matches = compiled_pattern.findall(text)
        if matches:
            print(f"✅ MATCHED: '{text}'")
            print(f"   Found: {matches}")
        else:
            print(f"❌ NO MATCH: '{text}'")
    
    print("\n📋 Trait names being matched:")
    for name in trait_names:
        print(f"  - {name}")

if __name__ == "__main__":
    print("🔧 Generating immunity trait regex pattern...")
    print("=" * 60)
    
    # Generate regex
    regex_data = generate_immunity_regex()
    
    # Save configuration
    save_regex_config(regex_data)
    
    # Test the pattern
    test_regex(regex_data['compiled_pattern'], regex_data['trait_names'])
    
    print("\n✅ Regex generation complete!")
    print(f"Pattern length: {len(regex_data['pattern_string'])} characters")