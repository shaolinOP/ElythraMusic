import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:elythra_music/core/model/lyrics_models.dart';
import 'package:elythra_music/features/lyrics/repository/lrcnet_api.dart';

/// Enhanced lyrics service with multiple providers and caching
class EnhancedLyricsService {
  static const String _cachePrefix = 'lyrics_cache_';
  static const Duration _cacheExpiry = Duration(days: 7);
  
  // Multiple lyrics providers for fallback
  static const List<String> _lyricsProviders = [
    'https://lrclib.net/api',
    'https://api.lyrics.ovh/v1',
    'https://some-lyrics-api.com/api', // Placeholder for additional providers
  ];

  /// Get lyrics with caching and multiple provider fallback
  static Future<Lyrics> getEnhancedLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    bool useCache = true,
  }) async {
    final cacheKey = _generateCacheKey(title, artist, album);
    
    // Try cache first
    if (useCache) {
      final cachedLyrics = await _getCachedLyrics(cacheKey);
      if (cachedLyrics != null) {
        log('Lyrics loaded from cache for: $title - $artist');
        return cachedLyrics;
      }
    }

    // Try multiple providers
    Lyrics? lyrics;
    
    // Primary provider: LRCLib (existing)
    try {
      lyrics = await getLRCNetAPILyrics(
        title,
        artist: artist,
        album: album,
        duration: duration?.inSeconds.toString(),
      );
      
      if (lyrics.lyricsSynced != null && lyrics.lyricsSynced!.isNotEmpty) {
        await _cacheLyrics(cacheKey, lyrics);
        return lyrics;
      }
    } catch (e) {
      log('LRCLib failed: $e');
    }

    // Fallback providers
    for (final provider in _lyricsProviders.skip(1)) {
      try {
        lyrics = await _fetchFromProvider(provider, title, artist, album);
        if (lyrics != null && lyrics.lyricsPlain.isNotEmpty) {
          await _cacheLyrics(cacheKey, lyrics);
          return lyrics;
        }
      } catch (e) {
        log('Provider $provider failed: $e');
      }
    }

    // Return empty lyrics if all providers fail
    return Lyrics(
      id: '0',
      title: title,
      artist: artist,
      album: album ?? '',
      lyricsPlain: 'Lyrics not found',
      lyricsSynced: null,
      provider: LyricsProvider.none,
    );
  }

  /// Enhanced search with fuzzy matching
  static Future<List<Lyrics>> searchEnhancedLyrics(
    String query, {
    String? artist,
    String? album,
    int limit = 10,
  }) async {
    final results = <Lyrics>[];
    
    try {
      // Use existing LRCNet search
      final lrcResults = await searchLRCNetLyrics(
        query,
        artistName: artist,
        albumName: album,
      );
      results.addAll(lrcResults.take(limit));
    } catch (e) {
      log('LRCNet search failed: $e');
    }

    // TODO: Add more search providers here
    
    return results;
  }

  /// Parse LRC format lyrics into structured format
  static List<EnhancedLyricLine> parseLrcLyrics(String lrcContent) {
    final lines = <EnhancedLyricLine>[];
    final lrcLines = lrcContent.split('\n');
    
    for (final line in lrcLines) {
      final match = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!.trim();
        
        if (text.isNotEmpty) {
          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );
          
          lines.add(EnhancedLyricLine(start: timestamp, text: text));
        }
      }
    }
    
    return lines..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Get current lyric line based on playback position
  static EnhancedLyricLine? getCurrentLyricLine(
    List<EnhancedLyricLine> lyrics,
    Duration currentPosition,
  ) {
    if (lyrics.isEmpty) return null;
    
    EnhancedLyricLine? currentLine;
    for (final line in lyrics) {
      if (line.start <= currentPosition) {
        currentLine = line;
      } else {
        break;
      }
    }
    
    return currentLine;
  }

  /// Get next lyric line for preview
  static EnhancedLyricLine? getNextLyricLine(
    List<EnhancedLyricLine> lyrics,
    Duration currentPosition,
  ) {
    for (final line in lyrics) {
      if (line.start > currentPosition) {
        return line;
      }
    }
    return null;
  }

  // Private helper methods
  static String _generateCacheKey(String title, String artist, String? album) {
    final key = '$title-$artist-${album ?? ''}';
    return _cachePrefix + key.toLowerCase().replaceAll(RegExp(r'[^\w\-]'), '');
  }

  static Future<Lyrics?> _getCachedLyrics(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      final cacheTime = prefs.getInt('$cacheKey_time');
      
      if (cachedData != null && cacheTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
        if (cacheAge < _cacheExpiry.inMilliseconds) {
          final data = jsonDecode(cachedData);
          return Lyrics(
            id: data['id'] ?? '0',
            title: data['title'] ?? '',
            artist: data['artist'] ?? '',
            album: data['album'],
            lyricsPlain: data['lyricsPlain'] ?? '',
            lyricsSynced: data['lyricsSynced'],
            provider: LyricsProvider.toARGB32s.firstWhere(
              (p) => p.toString() == data['provider'],
              orElse: () => LyricsProvider.none,
            ),
          );
        }
      }
    } catch (e) {
      log('Cache read error: $e');
    }
    return null;
  }

  static Future<void> _cacheLyrics(String cacheKey, Lyrics lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'id': lyrics.id,
        'title': lyrics.title,
        'artist': lyrics.artist,
        'album': lyrics.album,
        'lyricsPlain': lyrics.lyricsPlain,
        'lyricsSynced': lyrics.lyricsSynced,
        'provider': lyrics.provider.toString(),
      });
      await prefs.setString(cacheKey, data);
      await prefs.setInt('$cacheKey_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log('Cache write error: $e');
    }
  }

  static Future<Lyrics?> _fetchFromProvider(
    String provider,
    String title,
    String artist,
    String? album,
  ) async {
    // Placeholder for additional providers
    // Each provider would have its own implementation
    return null;
  }

  /// Clear lyrics cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('$key_time');
      }
    } catch (e) {
      log('Cache clear error: $e');
    }
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).length;
    } catch (e) {
      return 0;
    }
  }
}

/// Enhanced lyric line with additional metadata
class EnhancedLyricLine {
  final Duration start;
  final String text;
  final Duration? end;
  final Map<String, dynamic>? metadata;

  EnhancedLyricLine({
    required this.start,
    required this.text,
    this.end,
    this.metadata,
  });

  // Legacy constructor for compatibility
  EnhancedLyricLine.fromTimestamp({required int timestamp, required this.text})
      : start = Duration(milliseconds: timestamp),
        end = null,
        metadata = null;

  bool isActive(Duration currentPosition) {
    if (end != null) {
      return currentPosition >= start && currentPosition < end!;
    }
    return currentPosition >= start;
  }

  Duration get duration => end != null ? end! - start : Duration.zero;
}