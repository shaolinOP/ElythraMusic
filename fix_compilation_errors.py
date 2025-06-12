#!/usr/bin/env python3
"""
Script to systematically fix compilation errors in Elythra Music
"""

import os
import re
import glob

def fix_import_conflicts():
    """Fix import conflicts between audio_service and custom MediaItem"""
    
    # Files that need audio_service alias
    files_to_fix = [
        'lib/core/blocs/mini_player/mini_player_bloc.dart',
        'lib/features/player/screens/widgets/song_tile.dart',
        'lib/features/player/screens/screen/explore_screen.dart',
        'lib/features/player/screens/screen/library_views/more_opts_sheet.dart',
    ]
    
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Add alias to audio_service import
            content = content.replace(
                "import 'package:audio_service/audio_service.dart';",
                "import 'package:audio_service/audio_service.dart' as audio_service;"
            )
            
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed import conflicts in {file_path}")

def fix_mediaplaylist_conflicts():
    """Fix MediaPlaylist import conflicts"""
    
    files_to_fix = [
        'lib/features/player/screens/screen/explore_screen.dart',
        'lib/features/player/screens/screen/library_views/more_opts_sheet.dart',
    ]
    
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Add alias to MediaPlaylistModel import
            content = content.replace(
                "import 'package:elythra_music/core/model/MediaPlaylistModel.dart';",
                "import 'package:elythra_music/core/model/MediaPlaylistModel.dart' as core_playlist;"
            )
            
            # Update MediaPlaylist usage
            content = re.sub(
                r'\bMediaPlaylist\(',
                'core_playlist.MediaPlaylist(',
                content
            )
            
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed MediaPlaylist conflicts in {file_path}")

def fix_method_signatures():
    """Fix method signature issues"""
    
    # Fix loadPlaylist calls to updateQueue
    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Fix loadPlaylist calls with extra parameters
        content = re.sub(
            r'\.loadPlaylist\(\s*MediaPlaylist\([^)]+\),\s*doPlay:\s*true,?\s*\)',
            '.updateQueue(mediaitems, doPlay: true, idx: 0)',
            content
        )
        
        content = re.sub(
            r'\.loadPlaylist\(\s*MediaPlaylist\([^)]+\),\s*idx:\s*(\w+),\s*doPlay:\s*true\)',
            r'.updateQueue(mediaitems, idx: \1, doPlay: true)',
            content
        )
        
        # Remove doPlay parameter from updateQueue calls where it doesn't belong
        content = re.sub(
            r'\.updateQueue\([^)]+\),\s*doPlay:\s*true\)',
            '.updateQueue(mediaitems, doPlay: true, idx: 0)',
            content
        )
        
        if content != original_content:
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed method signatures in {file_path}")

def fix_type_conversions():
    """Fix type conversion issues"""
    
    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    
    for file_path in dart_files:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Fix MediaItemModel to MediaItem conversions
        content = re.sub(
            r'\.addQueueItem\((\w+)\)',
            r'.addQueueItem(MediaItem.fromMediaItemModel(\1))',
            content
        )
        
        # Fix Stream.value access
        content = re.sub(
            r'\.queueTitle\.value',
            '.queueTitle',
            content
        )
        
        if content != original_content:
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed type conversions in {file_path}")

def main():
    print("Starting systematic compilation error fixes...")
    
    fix_import_conflicts()
    fix_mediaplaylist_conflicts()
    fix_method_signatures()
    fix_type_conversions()
    
    print("Compilation error fixes completed!")

if __name__ == "__main__":
    main()