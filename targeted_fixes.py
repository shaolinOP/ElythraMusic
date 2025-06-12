#!/usr/bin/env python3
"""
Targeted fixes for Flutter analysis issues - only safe changes
"""

import os
import re
import glob

def fix_unused_imports():
    """Remove specific unused imports"""
    files_to_fix = [
        ('lib/core/utils/pallete_generator.dart', 'package:cached_network_image/cached_network_image.dart'),
        ('lib/features/auth/services/enhanced_auth_service.dart', 'package:crypto/crypto.dart'),
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
    """Fix deprecated withOpacity usage - only in safe contexts"""
    dart_files = glob.glob('/workspace/ElythraMusic/lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Only replace simple withOpacity patterns that are safe
            # Pattern: .withOpacity(number) -> .withValues(alpha: number)
            content = re.sub(r'\.withOpacity\(([0-9.]+)\)', r'.withValues(alpha: \1)', content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed withOpacity in {file_path}")
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

def fix_print_statements():
    """Comment out print statements in production code"""
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

def fix_deprecated_share():
    """Fix deprecated Share usage"""
    files_to_fix = [
        'lib/features/player/screens/screen/home_views/youtube_views/playlist.dart',
        'lib/features/player/screens/screen/library_views/more_opts_sheet.dart',
        'lib/features/player/screens/widgets/more_bottom_sheet.dart',
    ]
    
    for file_path in files_to_fix:
        full_path = os.path.join('/workspace/ElythraMusic', file_path)
        if os.path.exists(full_path):
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Replace deprecated Share usage
            content = content.replace('Share.share(', 'SharePlus.share(')
            content = content.replace('Share.shareXFiles(', 'SharePlus.shareXFiles(')
            
            if content != original_content:
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed deprecated Share usage in {file_path}")

def fix_deprecated_button_bar():
    """Fix deprecated ButtonBar usage"""
    file_path = 'lib/features/player/screens/screen/library_views/playlist_screen.dart'
    full_path = os.path.join('/workspace/ElythraMusic', file_path)
    
    if os.path.exists(full_path):
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace ButtonBar with OverflowBar
        content = content.replace('ButtonBar(', 'OverflowBar(')
        
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed deprecated ButtonBar in {file_path}")

def main():
    print("Starting targeted fixes for Flutter analysis issues...")
    
    print("\n1. Fixing unused imports...")
    fix_unused_imports()
    
    print("\n2. Fixing deprecated withOpacity usage...")
    fix_deprecated_withopacity()
    
    print("\n3. Commenting out print statements...")
    fix_print_statements()
    
    print("\n4. Fixing deprecated Share usage...")
    fix_deprecated_share()
    
    print("\n5. Fixing deprecated ButtonBar...")
    fix_deprecated_button_bar()
    
    print("\nDone! Please run 'flutter analyze' to check remaining issues.")

if __name__ == "__main__":
    main()