#!/usr/bin/env python3
"""
Script to fix SourceEngine enum references
"""

import os
import glob

def fix_enum_references():
    """Fix all SourceEngine enum references"""
    
    replacements = [
        ('SourceEngine.eng_JIS', 'SourceEngine.engJis'),
        ('SourceEngine.eng_YTM', 'SourceEngine.engYtm'),
        ('SourceEngine.eng_YTV', 'SourceEngine.engYtv'),
    ]
    
    for dart_file in glob.glob('lib/**/*.dart', recursive=True):
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            for old, new in replacements:
                content = content.replace(old, new)
            
            if content != original_content:
                with open(dart_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed enum references in {dart_file}")
                
        except Exception as e:
            print(f"Error fixing enum references in {dart_file}: {e}")

if __name__ == "__main__":
    fix_enum_references()
    print("Enum reference fixes completed!")