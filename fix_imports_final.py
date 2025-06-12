#!/usr/bin/env python3
"""
Fix all import paths after file renaming
"""

import os
import re
import glob

def fix_all_imports():
    """Fix all import paths for renamed files"""
    dart_files = glob.glob('/workspace/ElythraMusic/lib/**/*.dart', recursive=True)
    
    # Map of old imports to new imports
    import_fixes = {
        'load_Image.dart': 'load_image.dart',
        'GlobalDB.dart': 'global_db.dart', 
        'GlobalDB.g.dart': 'global_db.g.dart',
        'bloomeeUpdaterTools.dart': 'bloomee_updater_tools.dart',
        'createPlaylist_bottomsheet.dart': 'create_playlist_bottomsheet.dart',
        'playPause_widget.dart': 'play_pause_widget.dart',
        'tabList_widget.dart': 'tab_list_widget.dart',
        'bloomeePlayer.dart': 'bloomee_player.dart',
    }
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix all import paths
            for old_import, new_import in import_fixes.items():
                content = content.replace(old_import, new_import)
            
            # Fix class name references
            content = content.replace('Default_Theme', 'DefaultTheme')
            content = content.replace('LoadImage', 'LoadImage')  # Keep class name
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed imports in {file_path}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def main():
    print("Fixing all import paths...")
    fix_all_imports()
    print("Done!")

if __name__ == "__main__":
    main()