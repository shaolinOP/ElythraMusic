import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced lyrics service with multiple providers and improved sync
/// Integrated from Harmony-Music with additional sources and features
class EnhancedLyricsService {
  static final EnhancedLyricsService _instance = EnhancedLyricsService._internal();
  factory EnhancedLyricsService() => _instance;
  EnhancedLyricsService._internal();

  /// Initialize the enhanced lyrics service
  Future<void> initialize() async {
    // print('🎤 Enhanced Lyrics Service initialized');
    // Initialize any required services or configurations
  }

  // ignore: unused_field
  final Dio _dio = Dio();
  final Map<String, LyricsData> _lyricsCache = {};

  // Multiple lyrics providers for better coverage
  final List<LyricsProvider> _providers = [
    LRCLibProvider(),
    GeniusProvider(),
    MusixmatchProvider(),
    AZLyricsProvider(),
  ];

  /// Get lyrics with fallback to multiple providers
  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey(title, artist, album);

      // Check cache first
      if (useCache && _lyricsCache.containsKey(cacheKey)) {
        log('✅ Enhanced Lyrics: Using cached lyrics for $title by $artist');
        return _lyricsCache[cacheKey];
      }

      // Check local storage
      final localLyrics = await _getLocalLyrics(cacheKey);
      if (localLyrics != null) {
        _lyricsCache[cacheKey] = localLyrics;
        return localLyrics;
      }

      log('🔄 Enhanced Lyrics: Fetching lyrics for $title by $artist');

      // Try each provider until we get lyrics
      for (final provider in _providers) {
        try {
          final lyrics = await provider.getLyrics(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
          );

          if (lyrics != null && lyrics.hasContent) {
            log('✅ Enhanced Lyrics: Found lyrics from ${provider.name}');
            
            // Cache and save locally
            _lyricsCache[cacheKey] = lyrics;
            await _saveLocalLyrics(cacheKey, lyrics);
            
            return lyrics;
          }
        } catch (e) {
          log('❌ Enhanced Lyrics: ${provider.name} failed: $e');
          continue;
        }
      }

      log('❌ Enhanced Lyrics: No lyrics found for $title by $artist');
      return null;

    } catch (e) {
      log('❌ Enhanced Lyrics: Critical error: $e');
      return null;
    }
  }

  /// Get synced lyrics with timing adjustments
  Future<List<LyricLine>?> getSyncedLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
    int timingOffset = 0,
  }) async {
    final lyricsData = await getLyrics(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
    );

    if (lyricsData?.syncedLyrics == null) return null;

    // Apply timing offset if needed
    if (timingOffset != 0) {
      return lyricsData!.syncedLyrics!.map((line) => LyricLine(
        timestamp: line.timestamp + timingOffset,
        text: line.text,
      )).toList();
    }

    return lyricsData!.syncedLyrics;
  }

  /// Search for lyrics with fuzzy matching
  Future<List<LyricsSearchResult>> searchLyrics(String query) async {
    final results = <LyricsSearchResult>[];

    for (final provider in _providers) {
      try {
        if (provider.supportsSearch) {
          final providerResults = await provider.searchLyrics(query);
          results.addAll(providerResults);
        }
      } catch (e) {
        log('❌ Enhanced Lyrics: Search failed for ${provider.name}: $e');
      }
    }

    // Sort by relevance and remove duplicates
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return _removeDuplicateResults(results);
  }

  /// Save custom lyrics
  Future<void> saveCustomLyrics({
    required String title,
    required String artist,
    String? album,
    required String plainLyrics,
    List<LyricLine>? syncedLyrics,
  }) async {
    final cacheKey = _generateCacheKey(title, artist, album);
    final lyricsData = LyricsData(
      title: title,
      artist: artist,
      album: album,
      plainLyrics: plainLyrics,
      syncedLyrics: syncedLyrics,
      source: 'user_custom',
      isCustom: true,
    );

    _lyricsCache[cacheKey] = lyricsData;
    await _saveLocalLyrics(cacheKey, lyricsData);
    
    log('✅ Enhanced Lyrics: Saved custom lyrics for $title by $artist');
  }

  /// Generate cache key
  String _generateCacheKey(String title, String artist, String? album) {
    final normalized = '${title.toLowerCase()}_${artist.toLowerCase()}_${album?.toLowerCase() ?? ''}';
    return normalized.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  }

  /// Get lyrics from local storage
  Future<LyricsData?> _getLocalLyrics(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lyricsJson = prefs.getString('lyrics_$cacheKey');
      
      if (lyricsJson != null) {
        final data = json.decode(lyricsJson) as Map<String, dynamic>;
        return LyricsData.fromJson(data);
      }
    } catch (e) {
      log('❌ Enhanced Lyrics: Failed to get local lyrics: $e');
    }
    return null;
  }

  /// Save lyrics to local storage
  Future<void> _saveLocalLyrics(String cacheKey, LyricsData lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lyricsJson = json.encode(lyrics.toJson());
      await prefs.setString('lyrics_$cacheKey', lyricsJson);
    } catch (e) {
      log('❌ Enhanced Lyrics: Failed to save local lyrics: $e');
    }
  }

  /// Remove duplicate search results
  List<LyricsSearchResult> _removeDuplicateResults(List<LyricsSearchResult> results) {
    final seen = <String>{};
    return results.where((result) {
      final key = '${result.title.toLowerCase()}_${result.artist.toLowerCase()}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _lyricsCache.clear();
    log('🧹 Enhanced Lyrics: Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final total = _lyricsCache.length;
    final synced = _lyricsCache.toARGB32s.where((l) => l.hasSyncedLyrics).length;
    final custom = _lyricsCache.toARGB32s.where((l) => l.isCustom).length;

    return {
      'total_cached': total,
      'synced_lyrics': synced,
      'custom_lyrics': custom,
      'plain_only': total - synced,
    };
  }
}

/// Lyrics data model
class LyricsData {
  final String title;
  final String artist;
  final String? album;
  final String? plainLyrics;
  final List<LyricLine>? syncedLyrics;
  final String source;
  final bool isCustom;
  final DateTime fetchedAt;

  LyricsData({
    required this.title,
    required this.artist,
    this.album,
    this.plainLyrics,
    this.syncedLyrics,
    required this.source,
    this.isCustom = false,
  }) : fetchedAt = DateTime.now();

  bool get hasContent => plainLyrics != null || syncedLyrics != null;
  bool get hasSyncedLyrics => syncedLyrics != null && syncedLyrics!.isNotEmpty;
  bool get hasPlainLyrics => plainLyrics != null && plainLyrics!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'album': album,
    'plainLyrics': plainLyrics,
    'syncedLyrics': syncedLyrics?.map((l) => l.toJson()).toList(),
    'source': source,
    'isCustom': isCustom,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory LyricsData.fromJson(Map<String, dynamic> json) => LyricsData(
    title: json['title'],
    artist: json['artist'],
    album: json['album'],
    plainLyrics: json['plainLyrics'],
    syncedLyrics: (json['syncedLyrics'] as List?)
        ?.map((l) => LyricLine.fromJson(l))
        .toList(),
    source: json['source'],
    isCustom: json['isCustom'] ?? false,
  );
}

/// Individual lyric line with timestamp
class LyricLine {
  final int timestamp; // in milliseconds
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  String get timeFormatted {
    final seconds = timestamp ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final milliseconds = timestamp % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'text': text,
  };

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
    timestamp: json['timestamp'],
    text: json['text'],
  );
}

/// Lyrics search result
class LyricsSearchResult {
  final String title;
  final String artist;
  final String? album;
  final String source;
  final double relevance;
  final String? previewText;

  const LyricsSearchResult({
    required this.title,
    required this.artist,
    this.album,
    required this.source,
    required this.relevance,
    this.previewText,
  });
}

/// Abstract lyrics provider
abstract class LyricsProvider {
  String get name;
  bool get supportsSearch => false;
  bool get supportsSyncedLyrics => false;

  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
  });

  Future<List<LyricsSearchResult>> searchLyrics(String query) async {
    throw UnimplementedError('Search not supported by $name');
  }
}

/// LRCLib provider (primary for synced lyrics)
class LRCLibProvider extends LyricsProvider {
  @override
  String get name => 'LRCLib';
  
  @override
  bool get supportsSyncedLyrics => true;

  @override
  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
  }) async {
    try {
      final dio = Dio();
      final url = 'https://lrclib.net/api/get';
      final params = {
        'artist_name': artist,
        'track_name': title,
        if (album != null) 'album_name': album,
        if (duration != null) 'duration': duration,
      };

      final response = await dio.get(url, queryParameters: params);
      final data = response.data;

      if (data['syncedLyrics'] != null || data['plainLyrics'] != null) {
        List<LyricLine>? syncedLyrics;
        
        if (data['syncedLyrics'] != null) {
          syncedLyrics = _parseLRCFormat(data['syncedLyrics']);
        }

        return LyricsData(
          title: title,
          artist: artist,
          album: album,
          plainLyrics: data['plainLyrics'],
          syncedLyrics: syncedLyrics,
          source: name,
        );
      }
    } catch (e) {
      log('❌ LRCLib: Error fetching lyrics: $e');
    }
    return null;
  }

  List<LyricLine> _parseLRCFormat(String lrcContent) {
    final lines = <LyricLine>[];
    final lrcRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = lrcRegex.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          final timestamp = (minutes * 60 + seconds) * 1000 + centiseconds * 10;
          lines.add(LyricLine(timestamp: timestamp, text: text));
        }
      }
    }

    return lines;
  }
}

/// Genius provider (for plain lyrics)
class GeniusProvider extends LyricsProvider {
  @override
  String get name => 'Genius';
  
  @override
  bool get supportsSearch => true;

  @override
  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
  }) async {
    // Genius API implementation would go here
    // For now, return null as it requires API key
    return null;
  }

  @override
  Future<List<LyricsSearchResult>> searchLyrics(String query) async {
    // Genius search implementation
    return [];
  }
}

/// Musixmatch provider (backup)
class MusixmatchProvider extends LyricsProvider {
  @override
  String get name => 'Musixmatch';

  @override
  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
  }) async {
    // Musixmatch implementation would go here
    return null;
  }
}

/// AZLyrics provider (backup)
class AZLyricsProvider extends LyricsProvider {
  @override
  String get name => 'AZLyrics';

  @override
  Future<LyricsData?> getLyrics({
    required String title,
    required String artist,
    String? album,
    int? duration,
  }) async {
    // AZLyrics scraping implementation would go here
    return null;
  }
}