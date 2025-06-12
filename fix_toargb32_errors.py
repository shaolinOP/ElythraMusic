#!/usr/bin/env python3

import os
import re
import glob

def fix_compilation_errors():
    """Fix the major compilation errors in the ElythraMusic project"""
    
    # Get all Dart files
    dart_files = []
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"Found {len(dart_files)} Dart files to process")
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix SourceEngine enum issues
            content = re.sub(r'SourceEngine\.toARGB32s', 'SourceEngine.values', content)
            content = re.sub(r'SourceEngine\(\w+\)\.toARGB32', 'SourceEngine.value', content)
            
            # Fix enum values access patterns
            content = re.sub(r'(\w+)\.toARGB32s(?=\s*[,\)\]\s;])', r'\1.values', content)
            
            # Fix specific undefined enum constants
            content = re.sub(r'AudioQuality\.toARGB32s', 'AudioQuality.values', content)
            content = re.sub(r'StreamingMode\.toARGB32s', 'StreamingMode.values', content)
            content = re.sub(r'ResultTypes\.toARGB32s', 'ResultTypes.values', content)
            content = re.sub(r'ContentType\.toARGB32s', 'ContentType.values', content)
            content = re.sub(r'ShareMethod\.toARGB32s', 'ShareMethod.values', content)
            
            # Fix BehaviorSubject/Stream value access
            content = re.sub(r'loopMode\.toARGB32', 'loopMode.value', content)
            content = re.sub(r'queue\.toARGB32', 'queue.value', content)
            content = re.sub(r'relatedSongs\.toARGB32', 'relatedSongs.value', content)
            
            # Fix Future.toARGB32 -> Future.value
            content = re.sub(r'Future\.toARGB32', 'Future.value', content)
            
            # Fix setter calls
            content = re.sub(r'\.toARGB32\s*=', '.value =', content)
            
            # Fix getter calls for specific types
            content = re.sub(r'(\w+)\.toARGB32(?=\s*[,\)\]\s;])', r'\1.value', content)
            
            # Fix CardThemeData -> CardTheme
            content = re.sub(r'CardThemeData\(', 'CardTheme(', content)
            
            # Fix withValues -> withOpacity
            content = re.sub(r'\.withValues\(', '.withOpacity(', content)
            
            # Fix toleranceFor parameter
            content = re.sub(r'toleranceFor:', 'tolerance:', content)
            
            # Fix undefined identifier contentId_
            content = re.sub(r'contentId_', 'contentId', content)
            
            # Fix Share.shareXFiles method call
            content = re.sub(r'Share\.shareXFiles', 'Share.shareXFiles', content)
            
            # Only write if content changed
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed: {file_path}")
                
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_compilation_errors()
    print("Compilation error fixes completed!")