#!/usr/bin/env python3
"""
Script to fix common Flutter analysis issues in Elythra Music project
"""

import os
import re
import glob

def fix_unused_imports():
    """Remove specific unused imports"""
    files_to_fix = [
        ('lib/features/auth/webview_auth_service.dart', 'package:flutter/foundation.dart'),
        ('lib/features/lyrics/services/enhanced_lyrics_service.dart', 'package:http/http.dart'),
        ('lib/features/lyrics/services/enhanced_lyrics_service.dart', 'package:elythra_music/features/lyrics/repository/lyrics.dart'),
        ('lib/features/music_intelligence/recommendation_engine.dart', 'dart:math'),
        ('lib/features/performance/performance_optimizer.dart', 'dart:isolate'),
        ('lib/features/player/screens/screen/home_views/youtube_views/playlist.dart', 'package:elythra_music/core/model/MediaPlaylistModel.dart'),
        ('lib/features/player/screens/screen/library_views/more_opts_sheet.dart', 'package:elythra_music/core/model/MediaPlaylistModel.dart'),
        ('lib/features/player/screens/screen/library_views/playlist_screen.dart', 'package:elythra_music/core/model/MediaPlaylistModel.dart'),
        ('lib/features/player/screens/screen/library_views/playlist_screen.dart', 'package:flutter/foundation.dart'),
        ('lib/features/player/screens/screen/offline_screen.dart', 'package:elythra_music/core/model/MediaPlaylistModel.dart'),
        ('lib/features/player/screens/screen/player_screen.dart', 'dart:ui'),
        ('lib/features/player/screens/screen/player_screen.dart', 'package:elythra_music/core/services/bloomeePlayer.dart'),
        ('lib/features/player/screens/widgets/createPlaylist_bottomsheet.dart', 'package:flutter/cupertino.dart'),
        ('lib/features/player/screens/widgets/song_tile.dart', 'package:audio_service/audio_service.dart'),
        ('lib/features/player/services/enhanced_audio_service.dart', 'package:audio_service/audio_service.dart'),
        ('lib/features/player/services/enhanced_audio_service.dart', 'package:elythra_music/core/repository/Saavn/saavn_api.dart'),
        ('lib/features/player/services/enhanced_audio_service.dart', 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart'),
        ('lib/features/settings/enhanced_settings_screen.dart', 'package:flutter_bloc/flutter_bloc.dart'),
        ('lib/features/social/social_features_service.dart', 'package:url_launcher/url_launcher.dart'),
        ('lib/main.dart', 'package:elythra_music/features/harmony_integration/enhanced_stream_service.dart'),
    ]
    
    for file_path, import_to_remove in files_to_fix:
        full_path = os.path.join('/workspace/ElythraMusic', file_path)
        if os.path.exists(full_path):
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Remove the specific import line
            import_pattern = f"import '{import_to_remove}';\n"
            if import_pattern in content:
                content = content.replace(import_pattern, '')
                print(f"Removed unused import {import_to_remove} from {file_path}")
            
            # Also try with double quotes
            import_pattern = f'import "{import_to_remove}";\n'
            if import_pattern in content:
                content = content.replace(import_pattern, '')
                print(f"Removed unused import {import_to_remove} from {file_path}")
            
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)

def fix_deprecated_withopacity():
    """Fix deprecated withOpacity usage"""
    dart_files = glob.glob('/workspace/ElythraMusic/lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Replace .withOpacity( with .withValues(alpha: 
            content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed withOpacity in {file_path}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def fix_print_statements():
    """Remove or comment out print statements in production code"""
    dart_files = glob.glob('/workspace/ElythraMusic/lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            modified = False
            for i, line in enumerate(lines):
                # Look for print statements that are not in comments
                if 'print(' in line and not line.strip().startswith('//'):
                    # Comment out the print statement
                    lines[i] = line.replace('print(', '// print(')
                    modified = True
            
            if modified:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                print(f"Commented out print statements in {file_path}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def fix_const_constructors():
    """Add const to constructors where suggested"""
    dart_files = glob.glob('/workspace/ElythraMusic/lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix common const constructor patterns
            patterns = [
                (r'return ([A-Z][a-zA-Z]*)\(', r'return const \1('),
                (r'emit\(([A-Z][a-zA-Z]*)\(', r'emit(const \1('),
            ]
            
            for pattern, replacement in patterns:
                content = re.sub(pattern, replacement, content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Added const constructors in {file_path}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def main():
    print("Starting to fix Flutter analysis issues...")
    
    print("\n1. Fixing unused imports...")
    fix_unused_imports()
    
    print("\n2. Fixing deprecated withOpacity usage...")
    fix_deprecated_withopacity()
    
    print("\n3. Commenting out print statements...")
    fix_print_statements()
    
    print("\n4. Adding const constructors...")
    fix_const_constructors()
    
    print("\nDone! Please run 'flutter analyze' to check remaining issues.")

if __name__ == "__main__":
    main()