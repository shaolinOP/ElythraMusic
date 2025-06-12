import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Advanced music recommendation engine with multiple algorithms
class RecommendationEngine {
  static final RecommendationEngine _instance = RecommendationEngine._internal();
  factory RecommendationEngine() => _instance;
  RecommendationEngine._internal();

  // User listening data
  final Map<String, UserListeningProfile> _userProfiles = {};
  final Map<String, SongMetadata> _songDatabase = {};
  // ignore: unused_field
  final Map<String, List<String>> _artistSimilarity = {};
  final Map<String, List<String>> _genreSimilarity = {};

  /// Initialize recommendation engine
  Future<void> initialize() async {
    try {
      await _loadUserProfile();
      await _loadSongDatabase();
      await _buildSimilarityMaps();
      log('✅ Recommendation Engine: Initialized successfully');
    } catch (e) {
      log('❌ Recommendation Engine: Initialization failed: $e');
    }
  }

  /// Record a song play for learning user preferences
  Future<void> recordPlay({
    required String songId,
    required String title,
    required String artist,
    String? album,
    String? genre,
    Duration? duration,
    double? completionRate,
    bool wasSkipped = false,
    bool wasLiked = false,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      
      // Update user profile
      final profile = _userProfiles[userId] ?? UserListeningProfile(userId: userId);
      profile.recordPlay(
        songId: songId,
        artist: artist,
        genre: genre,
        duration: duration,
        completionRate: completionRate,
        wasSkipped: wasSkipped,
        wasLiked: wasLiked,
      );
      _userProfiles[userId] = profile;

      // Update song metadata
      _songDatabase[songId] = SongMetadata(
        id: songId,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        duration: duration,
      );

      // Save to persistent storage
      await _saveUserProfile(profile);
      
      log('📊 Recommendation Engine: Recorded play for $title by $artist');
    } catch (e) {
      log('❌ Recommendation Engine: Failed to record play: $e');
    }
  }

  /// Get personalized recommendations
  Future<List<RecommendationResult>> getRecommendations({
    int limit = 20,
    RecommendationType type = RecommendationType.mixed,
    String? seedSongId,
    String? seedArtist,
    String? seedGenre,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final profile = _userProfiles[userId];
      
      if (profile == null || profile.totalPlays < 5) {
        // Not enough data, return trending/popular songs
        return _getTrendingRecommendations(limit);
      }

      List<RecommendationResult> recommendations = [];

      switch (type) {
        case RecommendationType.similar:
          recommendations = await _getSimilarSongs(profile, seedSongId, limit);
          break;
        case RecommendationType.discovery:
          recommendations = await _getDiscoveryRecommendations(profile, limit);
          break;
        case RecommendationType.mood:
          recommendations = await _getMoodBasedRecommendations(profile, limit);
          break;
        case RecommendationType.mixed:
          // Mix of different recommendation types
          final similar = await _getSimilarSongs(profile, seedSongId, limit ~/ 3);
          final discovery = await _getDiscoveryRecommendations(profile, limit ~/ 3);
          final mood = await _getMoodBasedRecommendations(profile, limit ~/ 3);
          
          recommendations = [...similar, ...discovery, ...mood];
          break;
      }

      // Remove duplicates and songs already in user's library
      recommendations = _filterAndRankRecommendations(recommendations, profile);
      
      // Limit results
      if (recommendations.length > limit) {
        recommendations = recommendations.take(limit).toList();
      }

      log('🎯 Recommendation Engine: Generated ${recommendations.length} recommendations');
      return recommendations;

    } catch (e) {
      log('❌ Recommendation Engine: Failed to get recommendations: $e');
      return [];
    }
  }

  /// Get similar songs based on user's listening history
  Future<List<RecommendationResult>> _getSimilarSongs(
    UserListeningProfile profile,
    String? seedSongId,
    int limit,
  ) async {
    final recommendations = <RecommendationResult>[];

    // If seed song provided, find similar songs
    if (seedSongId != null && _songDatabase.containsKey(seedSongId)) {
      final seedSong = _songDatabase[seedSongId]!;
      
      // Find songs by same artist
      final sameArtistSongs = _songDatabase.values
          .where((song) => song.artist == seedSong.artist && song.id != seedSongId)
          .take(limit ~/ 3)
          .map((song) => RecommendationResult(
                songId: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre,
                confidence: 0.8,
                reason: 'Same artist as ${seedSong.title}',
                type: RecommendationType.similar,
              ));
      recommendations.addAll(sameArtistSongs);

      // Find songs in same genre
      if (seedSong.genre != null) {
        final sameGenreSongs = _songDatabase.values
            .where((song) => 
                song.genre == seedSong.genre && 
                song.artist != seedSong.artist)
            .take(limit ~/ 3)
            .map((song) => RecommendationResult(
                  songId: song.id,
                  title: song.title,
                  artist: song.artist,
                  album: song.album,
                  genre: song.genre,
                  confidence: 0.6,
                  reason: 'Similar genre (${seedSong.genre})',
                  type: RecommendationType.similar,
                ));
        recommendations.addAll(sameGenreSongs);
      }
    }

    // Find songs similar to user's top artists
    final topArtists = profile.getTopArtists(5);
    for (final artist in topArtists) {
      final artistSongs = _songDatabase.values
          .where((song) => song.artist == artist)
          .where((song) => !profile.hasPlayed(song.id))
          .take(2)
          .map((song) => RecommendationResult(
                songId: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre,
                confidence: 0.7,
                reason: 'You like $artist',
                type: RecommendationType.similar,
              ));
      recommendations.addAll(artistSongs);
    }

    return recommendations;
  }

  /// Get discovery recommendations (new artists/genres)
  Future<List<RecommendationResult>> _getDiscoveryRecommendations(
    UserListeningProfile profile,
    int limit,
  ) async {
    final recommendations = <RecommendationResult>[];
    final userGenres = profile.getTopGenres(3);
    final userArtists = profile.getTopArtists(10);

    // Find new artists in familiar genres
    for (final genre in userGenres) {
      final newArtistSongs = _songDatabase.values
          .where((song) => 
              song.genre == genre && 
              !userArtists.contains(song.artist))
          .take(limit ~/ userGenres.length)
          .map((song) => RecommendationResult(
                songId: song.id,
                title: song.title,
                artist: song.artist,
                album: song.album,
                genre: song.genre,
                confidence: 0.5,
                reason: 'New artist in $genre',
                type: RecommendationType.discovery,
              ));
      recommendations.addAll(newArtistSongs);
    }

    // Find songs in related genres
    for (final genre in userGenres) {
      final relatedGenres = _genreSimilarity[genre] ?? [];
      for (final relatedGenre in relatedGenres.take(2)) {
        final relatedSongs = _songDatabase.values
            .where((song) => song.genre == relatedGenre)
            .where((song) => !profile.hasPlayed(song.id))
            .take(2)
            .map((song) => RecommendationResult(
                  songId: song.id,
                  title: song.title,
                  artist: song.artist,
                  album: song.album,
                  genre: song.genre,
                  confidence: 0.4,
                  reason: 'Similar to $genre',
                  type: RecommendationType.discovery,
                ));
        recommendations.addAll(relatedSongs);
      }
    }

    return recommendations;
  }

  /// Get mood-based recommendations
  Future<List<RecommendationResult>> _getMoodBasedRecommendations(
    UserListeningProfile profile,
    int limit,
  ) async {
    final recommendations = <RecommendationResult>[];
    final currentMood = _detectCurrentMood(profile);

    // Get songs that match the detected mood
    final moodSongs = _songDatabase.values
        .where((song) => _songMatchesMood(song, currentMood))
        .where((song) => !profile.hasPlayed(song.id))
        .take(limit)
        .map((song) => RecommendationResult(
              songId: song.id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              genre: song.genre,
              confidence: 0.6,
              reason: 'Matches your ${currentMood.name} mood',
              type: RecommendationType.mood,
            ));

    recommendations.addAll(moodSongs);
    return recommendations;
  }

  /// Get trending recommendations for new users
  List<RecommendationResult> _getTrendingRecommendations(int limit) {
    // This would typically come from a backend service
    // For now, return a mix of popular songs
    final trending = _songDatabase.values
        .take(limit)
        .map((song) => RecommendationResult(
              songId: song.id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              genre: song.genre,
              confidence: 0.3,
              reason: 'Trending now',
              type: RecommendationType.discovery,
            ))
        .toList();

    return trending;
  }

  /// Filter and rank recommendations
  List<RecommendationResult> _filterAndRankRecommendations(
    List<RecommendationResult> recommendations,
    UserListeningProfile profile,
  ) {
    // Remove duplicates
    final seen = <String>{};
    final filtered = recommendations.where((rec) {
      if (seen.contains(rec.songId)) return false;
      seen.add(rec.songId);
      return true;
    }).toList();

    // Remove songs user has already played
    final unplayed = filtered
        .where((rec) => !profile.hasPlayed(rec.songId))
        .toList();

    // Sort by confidence score
    unplayed.sort((a, b) => b.confidence.compareTo(a.confidence));

    return unplayed;
  }

  /// Detect user's current mood based on recent listening
  MoodType _detectCurrentMood(UserListeningProfile profile) {
    final recentPlays = profile.getRecentPlays(10);
    
    // Analyze recent listening patterns
    // This is a simplified mood detection algorithm
    final genreCounts = <String, int>{};
    for (final play in recentPlays) {
      if (play.genre != null) {
        genreCounts[play.genre!] = (genreCounts[play.genre!] ?? 0) + 1;
      }
    }

    // Map genres to moods (simplified)
    if (genreCounts.containsKey('rock') || genreCounts.containsKey('metal')) {
      return MoodType.energetic;
    } else if (genreCounts.containsKey('classical') || genreCounts.containsKey('ambient')) {
      return MoodType.calm;
    } else if (genreCounts.containsKey('pop') || genreCounts.containsKey('dance')) {
      return MoodType.happy;
    } else if (genreCounts.containsKey('blues') || genreCounts.containsKey('sad')) {
      return MoodType.melancholic;
    }

    return MoodType.neutral;
  }

  /// Check if song matches mood
  bool _songMatchesMood(SongMetadata song, MoodType mood) {
    if (song.genre == null) return false;

    switch (mood) {
      case MoodType.energetic:
        return ['rock', 'metal', 'electronic', 'punk'].contains(song.genre!.toLowerCase());
      case MoodType.calm:
        return ['classical', 'ambient', 'jazz', 'acoustic'].contains(song.genre!.toLowerCase());
      case MoodType.happy:
        return ['pop', 'dance', 'funk', 'reggae'].contains(song.genre!.toLowerCase());
      case MoodType.melancholic:
        return ['blues', 'folk', 'indie', 'alternative'].contains(song.genre!.toLowerCase());
      case MoodType.neutral:
        return true;
    }
  }

  /// Load user profile from storage
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getCurrentUserId();
      final profileJson = prefs.getString('user_profile_$userId');
      
      if (profileJson != null) {
        final data = json.decode(profileJson) as Map<String, dynamic>;
        _userProfiles[userId] = UserListeningProfile.fromJson(data);
      }
    } catch (e) {
      log('❌ Recommendation Engine: Failed to load user profile: $e');
    }
  }

  /// Save user profile to storage
  Future<void> _saveUserProfile(UserListeningProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      await prefs.setString('user_profile_${profile.userId}', profileJson);
    } catch (e) {
      log('❌ Recommendation Engine: Failed to save user profile: $e');
    }
  }

  /// Load song database (would typically come from backend)
  Future<void> _loadSongDatabase() async {
    // This would typically load from a backend service
    // For now, we'll populate with sample data as songs are played
  }

  /// Build similarity maps
  Future<void> _buildSimilarityMaps() async {
    // This would typically be pre-computed on the backend
    // For now, we'll use simple similarity rules
    _genreSimilarity['rock'] = ['metal', 'punk', 'alternative'];
    _genreSimilarity['pop'] = ['dance', 'electronic', 'funk'];
    _genreSimilarity['jazz'] = ['blues', 'classical', 'ambient'];
    _genreSimilarity['classical'] = ['ambient', 'jazz', 'acoustic'];
  }

  /// Get current user ID
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id') ?? 'default_user';
  }

  /// Get recommendation statistics
  Map<String, dynamic> getStats() {
    final userId = _userProfiles.keys.isNotEmpty ? _userProfiles.keys.first : 'none';
    final profile = _userProfiles[userId];

    return {
      'total_songs_in_db': _songDatabase.length,
      'user_total_plays': profile?.totalPlays ?? 0,
      'user_unique_songs': profile?.uniqueSongs ?? 0,
      'user_top_artists': profile?.getTopArtists(5) ?? [],
      'user_top_genres': profile?.getTopGenres(5) ?? [],
    };
  }
}

/// User listening profile for personalization
class UserListeningProfile {
  final String userId;
  final Map<String, PlayData> _songPlays = {};
  final Map<String, int> _artistCounts = {};
  final Map<String, int> _genreCounts = {};
  final List<PlayRecord> _playHistory = [];

  UserListeningProfile({required this.userId});

  int get totalPlays => _playHistory.length;
  int get uniqueSongs => _songPlays.length;

  void recordPlay({
    required String songId,
    required String artist,
    String? genre,
    Duration? duration,
    double? completionRate,
    bool wasSkipped = false,
    bool wasLiked = false,
  }) {
    // Update song play data
    final playData = _songPlays[songId] ?? PlayData(songId: songId);
    playData.recordPlay(
      completionRate: completionRate,
      wasSkipped: wasSkipped,
      wasLiked: wasLiked,
    );
    _songPlays[songId] = playData;

    // Update artist counts
    _artistCounts[artist] = (_artistCounts[artist] ?? 0) + 1;

    // Update genre counts
    if (genre != null) {
      _genreCounts[genre] = (_genreCounts[genre] ?? 0) + 1;
    }

    // Add to play history
    _playHistory.add(PlayRecord(
      songId: songId,
      artist: artist,
      genre: genre,
      timestamp: DateTime.now(),
      duration: duration,
      completionRate: completionRate,
      wasSkipped: wasSkipped,
      wasLiked: wasLiked,
    ));

    // Keep only recent history (last 1000 plays)
    if (_playHistory.length > 1000) {
      _playHistory.removeAt(0);
    }
  }

  List<String> getTopArtists(int limit) {
    final sorted = _artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> getTopGenres(int limit) {
    final sorted = _genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<PlayRecord> getRecentPlays(int limit) {
    return _playHistory.reversed.take(limit).toList();
  }

  bool hasPlayed(String songId) => _songPlays.containsKey(songId);

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'songPlays': _songPlays.map((k, v) => MapEntry(k, v.toJson())),
    'artistCounts': _artistCounts,
    'genreCounts': _genreCounts,
    'playHistory': _playHistory.map((p) => p.toJson()).toList(),
  };

  factory UserListeningProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserListeningProfile(userId: json['userId']);
    
    // Load song plays
    final songPlaysJson = json['songPlays'] as Map<String, dynamic>? ?? {};
    for (final entry in songPlaysJson.entries) {
      profile._songPlays[entry.key] = PlayData.fromJson(entry.value);
    }

    // Load counts
    profile._artistCounts.addAll(Map<String, int>.from(json['artistCounts'] ?? {}));
    profile._genreCounts.addAll(Map<String, int>.from(json['genreCounts'] ?? {}));

    // Load play history
    final historyJson = json['playHistory'] as List? ?? [];
    for (final recordJson in historyJson) {
      profile._playHistory.add(PlayRecord.fromJson(recordJson));
    }

    return profile;
  }
}

/// Individual song play data
class PlayData {
  final String songId;
  int playCount = 0;
  double averageCompletion = 0.0;
  int skipCount = 0;
  bool isLiked = false;
  DateTime lastPlayed = DateTime.now();

  PlayData({required this.songId});

  void recordPlay({
    double? completionRate,
    bool wasSkipped = false,
    bool wasLiked = false,
  }) {
    playCount++;
    lastPlayed = DateTime.now();
    
    if (completionRate != null) {
      averageCompletion = (averageCompletion * (playCount - 1) + completionRate) / playCount;
    }
    
    if (wasSkipped) skipCount++;
    if (wasLiked) isLiked = true;
  }

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'playCount': playCount,
    'averageCompletion': averageCompletion,
    'skipCount': skipCount,
    'isLiked': isLiked,
    'lastPlayed': lastPlayed.toIso8601String(),
  };

  factory PlayData.fromJson(Map<String, dynamic> json) {
    final playData = PlayData(songId: json['songId']);
    playData.playCount = json['playCount'] ?? 0;
    playData.averageCompletion = json['averageCompletion'] ?? 0.0;
    playData.skipCount = json['skipCount'] ?? 0;
    playData.isLiked = json['isLiked'] ?? false;
    playData.lastPlayed = DateTime.tryParse(json['lastPlayed'] ?? '') ?? DateTime.now();
    return playData;
  }
}

/// Individual play record
class PlayRecord {
  final String songId;
  final String artist;
  final String? genre;
  final DateTime timestamp;
  final Duration? duration;
  final double? completionRate;
  final bool wasSkipped;
  final bool wasLiked;

  const PlayRecord({
    required this.songId,
    required this.artist,
    this.genre,
    required this.timestamp,
    this.duration,
    this.completionRate,
    this.wasSkipped = false,
    this.wasLiked = false,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'artist': artist,
    'genre': genre,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration?.inMilliseconds,
    'completionRate': completionRate,
    'wasSkipped': wasSkipped,
    'wasLiked': wasLiked,
  };

  factory PlayRecord.fromJson(Map<String, dynamic> json) => PlayRecord(
    songId: json['songId'],
    artist: json['artist'],
    genre: json['genre'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: json['duration'] != null ? Duration(milliseconds: json['duration']) : null,
    completionRate: json['completionRate'],
    wasSkipped: json['wasSkipped'] ?? false,
    wasLiked: json['wasLiked'] ?? false,
  );
}

/// Song metadata
class SongMetadata {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final Duration? duration;

  const SongMetadata({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    this.duration,
  });
}

/// Recommendation result
class RecommendationResult {
  final String songId;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final double confidence;
  final String reason;
  final RecommendationType type;

  const RecommendationResult({
    required this.songId,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    required this.confidence,
    required this.reason,
    required this.type,
  });
}

enum RecommendationType { similar, discovery, mood, mixed }
enum MoodType { energetic, calm, happy, melancholic, neutral }