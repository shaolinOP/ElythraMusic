#!/usr/bin/env python3
"""
Script to fix common Flutter analysis issues in ElythraMusic project
"""

import os
import re
import glob

def fix_constant_naming():
    """Fix constant naming to lowerCamelCase"""
    
    # Fix billboard_charts.dart
    file_path = 'lib/plugins/ext_charts/billboard_charts.dart'
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace constant declarations
            constant_replacements = [
                ('const String HOT_100', 'const String hot100'),
                ('const String BILLBOARD_200', 'const String billboard200'),
                ('const String SOCIAL_50', 'const String social50'),
                ('const String STREAMING_SONGS', 'const String streamingSongs'),
                ('const String DIGITAL_SONG_SALES', 'const String digitalSongSales'),
                ('const String RADIO_SONGS', 'const String radioSongs'),
                ('const String TOP_ALBUM_SALES', 'const String topAlbumSales'),
                ('const String CURRENT_ALBUMS', 'const String currentAlbums'),
                ('const String INDEPENDENT_ALBUMS', 'const String independentAlbums'),
                ('const String CATALOG_ALBUMS', 'const String catalogAlbums'),
                ('const String SOUNDTRACKS', 'const String soundtracks'),
                ('const String VINYL_ALBUMS', 'const String vinylAlbums'),
                ('const String HEATSEEKERS_ALBUMS', 'const String heatseekersAlbums'),
                ('const String WORLD_ALBUMS', 'const String worldAlbums'),
                ('const String CANADIAN_HOT_100', 'const String canadianHot100'),
                ('const String JAPAN_HOT_100', 'const String japanHot100'),
                ('const String KOREA_100', 'const String korea100'),
                ('const String INDIA_SONGS', 'const String indiaSongs'),
                ('const String BILLBOARD_GLOBAL_200', 'const String billboardGlobal200'),
            ]
            
            for old, new in constant_replacements:
                content = content.replace(old, new)
            
            # Replace variable assignments
            variable_replacements = [
                ('String HOT_100 =', 'String hot100 ='),
                ('String BILLBOARD_200 =', 'String billboard200 ='),
                ('String SOCIAL_50 =', 'String social50 ='),
                ('String STREAMING_SONGS =', 'String streamingSongs ='),
                ('String DIGITAL_SONG_SALES =', 'String digitalSongSales ='),
                ('String RADIO_SONGS =', 'String radioSongs ='),
                ('String TOP_ALBUM_SALES =', 'String topAlbumSales ='),
                ('String CURRENT_ALBUMS =', 'String currentAlbums ='),
                ('String INDEPENDENT_ALBUMS =', 'String independentAlbums ='),
                ('String CATALOG_ALBUMS =', 'String catalogAlbums ='),
                ('String SOUNDTRACKS =', 'String soundtracks ='),
                ('String VINYL_ALBUMS =', 'String vinylAlbums ='),
                ('String HEATSEEKERS_ALBUMS =', 'String heatseekersAlbums ='),
                ('String WORLD_ALBUMS =', 'String worldAlbums ='),
                ('String CANADIAN_HOT_100 =', 'String canadianHot100 ='),
                ('String JAPAN_HOT_100 =', 'String japanHot100 ='),
                ('String KOREA_100 =', 'String korea100 ='),
                ('String INDIA_SONGS =', 'String indiaSongs ='),
                ('String BILLBOARD_GLOBAL_200 =', 'String billboardGlobal200 ='),
            ]
            
            for old, new in variable_replacements:
                content = content.replace(old, new)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed constant naming in {file_path}")
                
        except Exception as e:
            print(f"Error fixing constants in {file_path}: {e}")

def fix_variable_naming():
    """Fix specific variable naming issues"""
    
    # Fix song_model.dart
    file_path = 'lib/core/model/song_model.dart'
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            content = content.replace('MediaItem2MediaItemDB', 'mediaItem2MediaItemDB')
            content = content.replace('MediaItemDB2MediaItem', 'mediaItemDB2MediaItem')
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed variable naming in {file_path}")
                
        except Exception as e:
            print(f"Error fixing variables in {file_path}: {e}")

def fix_class_naming():
    """Fix class naming issues"""
    
    # Fix Default_Theme class
    theme_files = [
        'lib/core/theme_data/default.dart',
        'lib/features/player/theme_data/default.dart'
    ]
    
    for file_path in theme_files:
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                content = content.replace('class Default_Theme', 'class DefaultTheme')
                content = content.replace('Default_Theme()', 'DefaultTheme()')
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed class naming in {file_path}")
                    
            except Exception as e:
                print(f"Error fixing classes in {file_path}: {e}")

def main():
    """Main function to run all fixes"""
    print("Starting ElythraMusic analysis issue fixes...")
    
    print("\n1. Fixing constant naming...")
    fix_constant_naming()
    
    print("\n2. Fixing variable naming...")
    fix_variable_naming()
    
    print("\n3. Fixing class naming...")
    fix_class_naming()
    
    print("\nBasic fixes completed!")

if __name__ == "__main__":
    main()