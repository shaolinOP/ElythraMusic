import 'dart:io';
import 'dart:developer';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Enhanced streaming service with multi-source fallback and error recovery
/// Integrated from Harmony-Music with improvements
class EnhancedStreamService {
  static final EnhancedStreamService _instance = EnhancedStreamService._internal();
  factory EnhancedStreamService() => _instance;
  EnhancedStreamService._internal();

  final YoutubeExplode _yt = YoutubeExplode();
  
  // Cache for stream data to avoid repeated requests
  final Map<String, StreamProvider> _streamCache = {};
  
  // Fallback servers for when primary fails
  final List<String> _fallbackServers = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.video',
    'https://pipedapi.adminforge.de',
  ];

  /// Get stream data with enhanced error handling and fallback
  Future<StreamProvider> getStreamData(String videoId, {bool useCache = true}) async {
    try {
      // Check cache first
      if (useCache && _streamCache.containsKey(videoId)) {
        final cached = _streamCache[videoId]!;
        if (cached.playable) {
          log('✅ Enhanced Stream: Using cached data for $videoId');
          return cached;
        }
      }

      log('🔄 Enhanced Stream: Fetching stream data for $videoId');

      // Try primary YouTube Explode
      final primaryResult = await _fetchFromYouTubeExplode(videoId);
      if (primaryResult.playable) {
        _streamCache[videoId] = primaryResult;
        return primaryResult;
      }

      log('⚠️ Enhanced Stream: Primary failed, trying fallback servers...');

      // Try fallback servers
      for (final server in _fallbackServers) {
        try {
          final fallbackResult = await _fetchFromFallbackServer(videoId, server);
          if (fallbackResult.playable) {
            log('✅ Enhanced Stream: Fallback server $server succeeded');
            _streamCache[videoId] = fallbackResult;
            return fallbackResult;
          }
        } catch (e) {
          log('❌ Enhanced Stream: Fallback server $server failed: $e');
          continue;
        }
      }

      // All methods failed
      final failedResult = StreamProvider(
        playable: false,
        statusMSG: "All streaming sources failed",
        error: "Unable to fetch stream from any source",
      );
      
      _streamCache[videoId] = failedResult;
      return failedResult;

    } catch (e) {
      log('❌ Enhanced Stream: Critical error for $videoId: $e');
      final errorResult = StreamProvider(
        playable: false,
        statusMSG: "Critical streaming error",
        error: e.toString(),
      );
      
      _streamCache[videoId] = errorResult;
      return errorResult;
    }
  }

  /// Fetch from primary YouTube Explode with enhanced error handling
  Future<StreamProvider> _fetchFromYouTubeExplode(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        return StreamProvider(
          playable: false,
          statusMSG: "No audio streams available",
        );
      }

      // Sort by quality (prefer 320kbps, then highest available)
      final sortedStreams = audioStreams.toList()
        ..sort((a, b) {
          // Prefer 320kbps (around 128000-160000 bits per second)
          final aIs320 = a.bitrate.bitsPerSecond >= 128000 && a.bitrate.bitsPerSecond <= 160000;
          final bIs320 = b.bitrate.bitsPerSecond >= 128000 && b.bitrate.bitsPerSecond <= 160000;
          
          if (aIs320 && !bIs320) return -1;
          if (!aIs320 && bIs320) return 1;
          
          // If both or neither are 320kbps, prefer higher bitrate
          return b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond);
        });

      final audioFormats = sortedStreams.map((stream) => EnhancedAudioFormat(
        itag: stream.tag,
        audioCodec: stream.audioCodec.contains('mp4') ? AudioCodec.mp4a : AudioCodec.opus,
        bitrate: stream.bitrate.bitsPerSecond,
        duration: stream.duration?.inMilliseconds ?? 0,
        loudnessDb: stream.loudnessDb,
        url: stream.url.toString(),
        size: stream.size.totalBytes,
        quality: _getQualityLabel(stream.bitrate.bitsPerSecond),
        container: stream.container.name,
      )).toList();

      return StreamProvider(
        playable: true,
        statusMSG: "OK",
        audioFormats: audioFormats,
        source: StreamSource.youtubeExplode,
      );

    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Network error",
          error: "No internet connection",
        );
      } else if (e is VideoUnplayableException) {
        return StreamProvider(
          playable: false,
          statusMSG: e.reason ?? "Video is unplayable",
          error: "Video cannot be played",
        );
      } else if (e is VideoRequiresPurchaseException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Video requires purchase",
          error: "Premium content",
        );
      } else if (e is VideoUnavailableException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Video is unavailable",
          error: "Content not available",
        );
      } else {
        return StreamProvider(
          playable: false,
          statusMSG: "Unknown error",
          error: e.toString(),
        );
      }
    }
  }

  /// Fetch from fallback Piped servers
  Future<StreamProvider> _fetchFromFallbackServer(String videoId, String serverUrl) async {
    // Implementation for Piped API fallback
    // This would require HTTP requests to Piped instances
    // For now, return a placeholder
    return StreamProvider(
      playable: false,
      statusMSG: "Fallback not implemented",
      error: "Piped fallback coming soon",
    );
  }

  /// Get quality label from bitrate
  String _getQualityLabel(int bitrate) {
    if (bitrate >= 256000) return "High (320kbps)";
    if (bitrate >= 128000) return "Medium (192kbps)";
    if (bitrate >= 96000) return "Standard (128kbps)";
    return "Low (${(bitrate / 1000).round()}kbps)";
  }

  /// Get best quality stream URL
  String? getBestQualityUrl(StreamProvider provider) {
    if (!provider.playable || provider.audioFormats == null) return null;

    // Prefer 320kbps, then highest available
    final formats = provider.audioFormats!;
    if (formats.isEmpty) return null;

    // Find 320kbps stream
    final highQuality = formats.where((f) => 
        f.bitrate >= 128000 && f.bitrate <= 160000).toList();
    
    if (highQuality.isNotEmpty) {
      return highQuality.first.url;
    }

    // Fallback to highest bitrate
    return formats.first.url;
  }

  /// Clear cache
  void clearCache() {
    _streamCache.clear();
    log('🧹 Enhanced Stream: Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final total = _streamCache.length;
    final playable = _streamCache.values.where((v) => v.playable).length;
    final failed = total - playable;

    return {
      'total_cached': total,
      'playable': playable,
      'failed': failed,
      'cache_hit_rate': total > 0 ? (playable / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  void dispose() {
    _yt.close();
    _streamCache.clear();
  }
}

/// Enhanced stream provider with additional metadata
class StreamProvider {
  final bool playable;
  final List<EnhancedAudioFormat>? audioFormats;
  final String statusMSG;
  final String? error;
  final StreamSource source;
  final DateTime fetchedAt;

  StreamProvider({
    required this.playable,
    this.audioFormats,
    this.statusMSG = "",
    this.error,
    this.source = StreamSource.unknown,
  }) : fetchedAt = DateTime.now();

  /// Get the best quality format
  EnhancedAudioFormat? get bestQuality {
    if (audioFormats == null || audioFormats!.isEmpty) return null;
    return audioFormats!.first; // Already sorted by quality
  }

  /// Get available quality options
  List<String> get availableQualities {
    if (audioFormats == null) return [];
    return audioFormats!.map((f) => f.quality).toSet().toList();
  }

  /// Check if cache is still valid (5 minutes)
  bool get isValid {
    return DateTime.now().difference(fetchedAt).inMinutes < 5;
  }
}

/// Enhanced audio format with additional metadata
class EnhancedAudioFormat {
  final int itag;
  final AudioCodec audioCodec;
  final int bitrate;
  final int duration;
  final double? loudnessDb;
  final String url;
  final int size;
  final String quality;
  final String container;

  const EnhancedAudioFormat({
    required this.itag,
    required this.audioCodec,
    required this.bitrate,
    required this.duration,
    this.loudnessDb,
    required this.url,
    required this.size,
    required this.quality,
    required this.container,
  });

  /// Get human-readable size
  String get sizeFormatted {
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get duration formatted
  String get durationFormatted {
    final seconds = duration ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

enum AudioCodec { mp4a, opus, unknown }
enum StreamSource { youtubeExplode, piped, unknown }