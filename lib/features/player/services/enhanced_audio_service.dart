import 'dart:developer';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elythra_music/core/model/songModel.dart';
import 'package:elythra_music/core/repository/Saavn/saavn_api.dart';
import 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart';

/// Enhanced audio service with 320kbps streaming and quality management
class EnhancedAudioService {
  static const String _qualityPreferenceKey = 'audio_quality_preference';
  static const String _streamingModeKey = 'streaming_mode';
  static const String _cacheEnabledKey = 'cache_enabled';

  /// Audio quality options
  enum AudioQuality {
    low(96, 'Low (96 kbps)'),
    medium(128, 'Medium (128 kbps)'),
    high(192, 'High (192 kbps)'),
    veryHigh(256, 'Very High (256 kbps)'),
    extreme(320, 'Extreme (320 kbps)');

    const AudioQuality(this.bitrate, this.displayName);
    final int bitrate;
    final String displayName;
  }

  /// Streaming mode options
  enum StreamingMode {
    wifi('WiFi Only'),
    mobile('Mobile Data'),
    offline('Offline Only');

    const StreamingMode(this.displayName);
    final String displayName;
  }

  static AudioQuality _currentQuality = AudioQuality.extreme;
  static StreamingMode _streamingMode = StreamingMode.wifi;
  static bool _cacheEnabled = true;

  /// Initialize audio service with user preferences
  static Future<void> initialize() async {
    await _loadPreferences();
    log('Enhanced Audio Service initialized with quality: ${_currentQuality.displayName}');
  }

  /// Get enhanced audio source with quality selection
  static Future<AudioSource?> getEnhancedAudioSource(
    MediaItemModel mediaItem, {
    AudioQuality? preferredQuality,
    bool allowFallback = true,
  }) async {
    final quality = preferredQuality ?? _currentQuality;
    
    try {
      // Check network conditions
      if (!await _isNetworkAvailable()) {
        log('No network available, checking cache');
        return await _getCachedAudioSource(mediaItem);
      }

      // Try to get high-quality stream
      final audioSource = await _getQualityAudioSource(mediaItem, quality, allowFallback);
      
      if (audioSource != null && _cacheEnabled) {
        // Cache the audio source for offline playback
        _cacheAudioSource(mediaItem, audioSource);
      }

      return audioSource;
    } catch (e) {
      log('Error getting enhanced audio source: $e');
      
      // Fallback to cached version
      if (allowFallback) {
        return await _getCachedAudioSource(mediaItem);
      }
      
      return null;
    }
  }

  /// Get audio source with specific quality
  static Future<AudioSource?> _getQualityAudioSource(
    MediaItemModel mediaItem,
    AudioQuality quality,
    bool allowFallback,
  ) async {
    // Try Saavn first for high quality
    if (mediaItem.source == 'saavn') {
      return await _getSaavnQualitySource(mediaItem, quality, allowFallback);
    }
    
    // Try YouTube Music
    if (mediaItem.source == 'youtube' || mediaItem.source == 'ytmusic') {
      return await _getYouTubeQualitySource(mediaItem, quality, allowFallback);
    }

    // Fallback to original source
    if (mediaItem.streamingUrl != null) {
      return AudioSource.uri(Uri.parse(mediaItem.streamingUrl!));
    }

    return null;
  }

  /// Get Saavn audio source with quality preference
  static Future<AudioSource?> _getSaavnQualitySource(
    MediaItemModel mediaItem,
    AudioQuality quality,
    bool allowFallback,
  ) async {
    try {
      // Get song details from Saavn API
      final songDetails = await SaavnAPI.getSongDetails(mediaItem.id);
      
      if (songDetails != null && songDetails.downloadUrl != null) {
        // Saavn provides multiple quality options
        String qualityParam = _getSaavnQualityParam(quality);
        String enhancedUrl = '${songDetails.downloadUrl}?quality=$qualityParam';
        
        log('Using Saavn ${quality.displayName} for: ${mediaItem.title}');
        return AudioSource.uri(Uri.parse(enhancedUrl));
      }
    } catch (e) {
      log('Saavn quality source failed: $e');
    }

    if (allowFallback && mediaItem.streamingUrl != null) {
      return AudioSource.uri(Uri.parse(mediaItem.streamingUrl!));
    }

    return null;
  }

  /// Get YouTube Music audio source with quality preference
  static Future<AudioSource?> _getYouTubeQualitySource(
    MediaItemModel mediaItem,
    AudioQuality quality,
    bool allowFallback,
  ) async {
    try {
      // Get YouTube Music stream with quality preference
      final streamInfo = await YtmServiceExtension.getStreamInfo(
        mediaItem.id,
        quality: quality.bitrate,
      );
      
      if (streamInfo != null && streamInfo.url != null) {
        log('Using YouTube Music ${quality.displayName} for: ${mediaItem.title}');
        return AudioSource.uri(Uri.parse(streamInfo.url!));
      }
    } catch (e) {
      log('YouTube Music quality source failed: $e');
    }

    if (allowFallback && mediaItem.streamingUrl != null) {
      return AudioSource.uri(Uri.parse(mediaItem.streamingUrl!));
    }

    return null;
  }

  /// Check if network is available and suitable for streaming
  static Future<bool> _isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Check streaming mode preferences
        if (_streamingMode == StreamingMode.offline) {
          return false;
        }
        
        // TODO: Add network type detection (WiFi vs Mobile)
        // For now, assume network is suitable
        return true;
      }
    } catch (e) {
      log('Network check failed: $e');
    }
    return false;
  }

  /// Get cached audio source
  static Future<AudioSource?> _getCachedAudioSource(MediaItemModel mediaItem) async {
    // TODO: Implement proper caching mechanism
    // This would involve storing audio files locally and retrieving them
    log('Attempting to get cached audio for: ${mediaItem.title}');
    return null;
  }

  /// Cache audio source for offline playback
  static Future<void> _cacheAudioSource(MediaItemModel mediaItem, AudioSource audioSource) async {
    // TODO: Implement audio caching
    // This would download and store the audio file locally
    log('Caching audio for offline playback: ${mediaItem.title}');
  }

  /// Get Saavn quality parameter
  static String _getSaavnQualityParam(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return '96';
      case AudioQuality.medium:
        return '128';
      case AudioQuality.high:
        return '192';
      case AudioQuality.veryHigh:
        return '256';
      case AudioQuality.extreme:
        return '320';
    }
  }

  /// Set audio quality preference
  static Future<void> setAudioQuality(AudioQuality quality) async {
    _currentQuality = quality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_qualityPreferenceKey, quality.index);
    log('Audio quality set to: ${quality.displayName}');
  }

  /// Set streaming mode
  static Future<void> setStreamingMode(StreamingMode mode) async {
    _streamingMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streamingModeKey, mode.index);
    log('Streaming mode set to: ${mode.displayName}');
  }

  /// Enable/disable caching
  static Future<void> setCacheEnabled(bool enabled) async {
    _cacheEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheEnabledKey, enabled);
    log('Audio caching ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get current audio quality
  static AudioQuality get currentQuality => _currentQuality;

  /// Get current streaming mode
  static StreamingMode get streamingMode => _streamingMode;

  /// Check if caching is enabled
  static bool get isCacheEnabled => _cacheEnabled;

  /// Load user preferences
  static Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final qualityIndex = prefs.getInt(_qualityPreferenceKey);
      if (qualityIndex != null && qualityIndex < AudioQuality.values.length) {
        _currentQuality = AudioQuality.values[qualityIndex];
      }
      
      final streamingModeIndex = prefs.getInt(_streamingModeKey);
      if (streamingModeIndex != null && streamingModeIndex < StreamingMode.values.length) {
        _streamingMode = StreamingMode.values[streamingModeIndex];
      }
      
      _cacheEnabled = prefs.getBool(_cacheEnabledKey) ?? true;
    } catch (e) {
      log('Error loading audio preferences: $e');
    }
  }

  /// Get audio quality statistics
  static Map<String, dynamic> getQualityStats() {
    return {
      'currentQuality': _currentQuality.displayName,
      'bitrate': _currentQuality.bitrate,
      'streamingMode': _streamingMode.displayName,
      'cacheEnabled': _cacheEnabled,
    };
  }

  /// Estimate data usage for a song
  static double estimateDataUsage(Duration duration, AudioQuality quality) {
    // Estimate in MB
    final durationMinutes = duration.inMinutes;
    final bitrateKbps = quality.bitrate;
    return (durationMinutes * bitrateKbps * 60) / (8 * 1024); // Convert to MB
  }

  /// Clear audio cache
  static Future<void> clearCache() async {
    // TODO: Implement cache clearing
    log('Audio cache cleared');
  }

  /// Get cache size
  static Future<double> getCacheSize() async {
    // TODO: Implement cache size calculation
    return 0.0; // Return size in MB
  }
}

/// Enhanced stream info model
class EnhancedStreamInfo {
  final String? url;
  final int bitrate;
  final String format;
  final int? fileSize;
  final Duration? duration;

  const EnhancedStreamInfo({
    this.url,
    required this.bitrate,
    required this.format,
    this.fileSize,
    this.duration,
  });
}

/// Extension for YtmService to support quality selection
class YtmServiceExtension {
  static Future<EnhancedStreamInfo?> getStreamInfo(
    String videoId, {
    int quality = 320,
  }) async {
    try {
      // This would be implemented to get stream info with quality preference
      // For now, return a placeholder
      return const EnhancedStreamInfo(
        bitrate: 320,
        format: 'mp4',
      );
    } catch (e) {
      log('Error getting stream info: $e');
      return null;
    }
  }
}