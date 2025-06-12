import 'dart:developer';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Social features service for sharing and community features
class SocialFeaturesService {
  static final SocialFeaturesService _instance = SocialFeaturesService._internal();
  factory SocialFeaturesService() => _instance;
  SocialFeaturesService._internal();

  // Local storage for social data
  final Map<String, UserSocialProfile> _userProfiles = {};
  final List<SharedContent> _sharedContent = [];
  final List<TrendingItem> _trendingItems = [];

  /// Initialize social features
  Future<void> initialize() async {
    try {
      await _loadSocialData();
      await _updateTrendingContent();
      log('✅ Social Features: Initialized successfully');
    } catch (e) {
      log('❌ Social Features: Initialization failed: $e');
    }
  }

  /// Share a song
  Future<ShareResult> shareSong({
    required String songId,
    required String title,
    required String artist,
    String? album,
    String? imageUrl,
    ShareMethod method = ShareMethod.system,
  }) async {
    try {
      final shareText = _generateSongShareText(title, artist, album);
      final shareUrl = _generateSongShareUrl(songId);

      switch (method) {
        case ShareMethod.system:
          await SharePlus.instance.share(
            '$shareText\n\nListen on Elythra Music: $shareUrl',
            subject: 'Check out this song!',
          );
          break;

        case ShareMethod.link:
          await SharePlus.instance.share(shareUrl);
          break;

        case ShareMethod.social:
          await _shareToSocialMedia(shareText, shareUrl, imageUrl);
          break;

        case ShareMethod.copy:
          // This would copy to clipboard
          // For now, just return the text
          break;
      }

      // Record the share
      await _recordShare(
        contentType: ContentType.song,
        contentId: songId,
        title: title,
        artist: artist,
        method: method,
      );

      log('📤 Social Features: Shared song $title by $artist');
      return ShareResult.success(shareUrl);

    } catch (e) {
      log('❌ Social Features: Failed to share song: $e');
      return ShareResult.failure(e.toString());
    }
  }

  /// Share a playlist
  Future<ShareResult> sharePlaylist({
    required String playlistId,
    required String name,
    required String description,
    required List<String> songIds,
    String? imageUrl,
    ShareMethod method = ShareMethod.system,
  }) async {
    try {
      final shareText = _generatePlaylistShareText(name, description, songIds.length);
      final shareUrl = _generatePlaylistShareUrl(playlistId);

      switch (method) {
        case ShareMethod.system:
          await SharePlus.instance.share(
            '$shareText\n\nListen on Elythra Music: $shareUrl',
            subject: 'Check out this playlist!',
          );
          break;

        case ShareMethod.link:
          await SharePlus.instance.share(shareUrl);
          break;

        case ShareMethod.social:
          await _shareToSocialMedia(shareText, shareUrl, imageUrl);
          break;

        case ShareMethod.copy:
          // Copy to clipboard
          break;
      }

      // Record the share
      await _recordShare(
        contentType: ContentType.playlist,
        contentId: playlistId,
        title: name,
        method: method,
      );

      log('📤 Social Features: Shared playlist $name');
      return ShareResult.success(shareUrl);

    } catch (e) {
      log('❌ Social Features: Failed to share playlist: $e');
      return ShareResult.failure(e.toString());
    }
  }

  /// Get trending content
  Future<List<TrendingItem>> getTrendingContent({
    TrendingType type = TrendingType.all,
    Duration timeframe = const Duration(days: 7),
    int limit = 20,
  }) async {
    try {
      await _updateTrendingContent();

      var trending = _trendingItems.where((item) {
        // Filter by type
        if (type != TrendingType.all && item.type != type) return false;

        // Filter by timeframe
        final age = DateTime.now().difference(item.timestamp);
        if (age > timeframe) return false;

        return true;
      }).toList();

      // Sort by popularity score
      trending.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

      // Limit results
      if (trending.length > limit) {
        trending = trending.take(limit).toList();
      }

      log('📈 Social Features: Retrieved ${trending.length} trending items');
      return trending;

    } catch (e) {
      log('❌ Social Features: Failed to get trending content: $e');
      return [];
    }
  }

  /// Get user's social activity
  Future<UserSocialProfile> getUserSocialProfile(String userId) async {
    try {
      var profile = _userProfiles[userId];
      
      if (profile == null) {
        profile = UserSocialProfile(
          userId: userId,
          displayName: 'Music Lover',
          joinDate: DateTime.now(),
        );
        _userProfiles[userId] = profile;
        await _saveSocialData();
      }

      return profile;
    } catch (e) {
      log('❌ Social Features: Failed to get user profile: $e');
      return UserSocialProfile(
        userId: userId,
        displayName: 'Music Lover',
        joinDate: DateTime.now(),
      );
    }
  }

  /// Update user's social profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    try {
      final profile = await getUserSocialProfile(userId);
      
      if (displayName != null) profile.displayName = displayName;
      if (bio != null) profile.bio = bio;
      if (avatarUrl != null) profile.avatarUrl = avatarUrl;
      if (isPublic != null) profile.isPublic = isPublic;

      _userProfiles[userId] = profile;
      await _saveSocialData();

      log('👤 Social Features: Updated profile for $userId');
    } catch (e) {
      log('❌ Social Features: Failed to update profile: $e');
    }
  }

  /// Get shared content by user
  Future<List<SharedContent>> getUserSharedContent(String userId) async {
    try {
      final userContent = _sharedContent
          .where((content) => content.userId == userId)
          .toList();

      // Sort by timestamp (newest first)
      userContent.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return userContent;
    } catch (e) {
      log('❌ Social Features: Failed to get user shared content: $e');
      return [];
    }
  }

  /// Get public playlists
  Future<List<PublicPlaylist>> getPublicPlaylists({
    int limit = 20,
    String? genre,
    PlaylistSortBy sortBy = PlaylistSortBy.popular,
  }) async {
    try {
      // This would typically come from a backend service
      // For now, return sample data
      final playlists = <PublicPlaylist>[
        PublicPlaylist(
          id: 'trending_hits',
          name: 'Trending Hits',
          description: 'The most popular songs right now',
          creatorId: 'elythra_official',
          creatorName: 'Elythra Music',
          songCount: 50,
          followers: 12500,
          isOfficial: true,
          genre: 'Pop',
          imageUrl: null,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PublicPlaylist(
          id: 'chill_vibes',
          name: 'Chill Vibes',
          description: 'Relaxing music for any time of day',
          creatorId: 'user_123',
          creatorName: 'ChillMaster',
          songCount: 75,
          followers: 8200,
          isOfficial: false,
          genre: 'Ambient',
          imageUrl: null,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      // Filter by genre if specified
      var filtered = playlists;
      if (genre != null) {
        filtered = playlists.where((p) => p.genre == genre).toList();
      }

      // Sort by specified criteria
      switch (sortBy) {
        case PlaylistSortBy.popular:
          filtered.sort((a, b) => b.followers.compareTo(a.followers));
          break;
        case PlaylistSortBy.recent:
          filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case PlaylistSortBy.name:
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
      }

      // Limit results
      if (filtered.length > limit) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e) {
      log('❌ Social Features: Failed to get public playlists: $e');
      return [];
    }
  }

  /// Generate song share text
  String _generateSongShareText(String title, String artist, String? album) {
    if (album != null) {
      return '🎵 Now listening to "$title" by $artist from the album "$album"';
    } else {
      return '🎵 Now listening to "$title" by $artist';
    }
  }

  /// Generate playlist share text
  String _generatePlaylistShareText(String name, String description, int songCount) {
    return '🎶 Check out my playlist "$name" with $songCount songs!\n\n$description';
  }

  /// Generate song share URL
  String _generateSongShareUrl(String songId) {
    return 'https://elythra.music/song/$songId';
  }

  /// Generate playlist share URL
  String _generatePlaylistShareUrl(String playlistId) {
    return 'https://elythra.music/playlist/$playlistId';
  }

  /// Share to social media platforms
  Future<void> _shareToSocialMedia(String text, String url, String? imageUrl) async {
    // This would integrate with social media SDKs
    // For now, just open the system share dialog
    await SharePlus.instance.share('$text\n\n$url');
  }

  /// Record a share action
  Future<void> _recordShare({
    required ContentType contentType,
    required String contentId,
    required String title,
    String? artist,
    required ShareMethod method,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final share = SharedContent(
        id: '${contentId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        contentType: contentType,
        contentId: contentId,
        title: title,
        artist: artist,
        method: method,
        timestamp: DateTime.now(),
      );

      _sharedContent.add(share);
      
      // Update user's social profile
      final profile = await getUserSocialProfile(userId);
      profile.totalShares++;
      _userProfiles[userId] = profile;

      await _saveSocialData();
    } catch (e) {
      log('❌ Social Features: Failed to record share: $e');
    }
  }

  /// Update trending content
  Future<void> _updateTrendingContent() async {
    try {
      // This would typically fetch from a backend service
      // For now, generate sample trending data
      _trendingItems.clear();
      
      // Add sample trending songs
      _trendingItems.addAll([
        TrendingItem(
          id: 'trending_song_1',
          type: TrendingType.song,
          title: 'Viral Hit Song',
          artist: 'Popular Artist',
          popularityScore: 95.5,
          shareCount: 1250,
          playCount: 50000,
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        TrendingItem(
          id: 'trending_playlist_1',
          type: TrendingType.playlist,
          title: 'Summer Vibes 2024',
          artist: 'Various Artists',
          popularityScore: 88.2,
          shareCount: 890,
          playCount: 25000,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);

      log('📈 Social Features: Updated trending content');
    } catch (e) {
      log('❌ Social Features: Failed to update trending content: $e');
    }
  }

  /// Load social data from storage
  Future<void> _loadSocialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user profiles
      final profilesJson = prefs.getString('social_profiles');
      if (profilesJson != null) {
        final profilesData = json.decode(profilesJson) as Map<String, dynamic>;
        for (final entry in profilesData.entries) {
          _userProfiles[entry.key] = UserSocialProfile.fromJson(entry.value);
        }
      }

      // Load shared content
      final sharedJson = prefs.getString('shared_content');
      if (sharedJson != null) {
        final sharedData = json.decode(sharedJson) as List;
        _sharedContent.clear();
        for (final item in sharedData) {
          _sharedContent.add(SharedContent.fromJson(item));
        }
      }
    } catch (e) {
      log('❌ Social Features: Failed to load social data: $e');
    }
  }

  /// Save social data to storage
  Future<void> _saveSocialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user profiles
      final profilesData = _userProfiles.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('social_profiles', json.encode(profilesData));

      // Save shared content (keep only recent 100 items)
      final recentShared = _sharedContent.take(100).toList();
      final sharedData = recentShared.map((s) => s.toJson()).toList();
      await prefs.setString('shared_content', json.encode(sharedData));
    } catch (e) {
      log('❌ Social Features: Failed to save social data: $e');
    }
  }

  /// Get current user ID
  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id') ?? 'default_user';
  }

  /// Get social statistics
  Map<String, dynamic> getSocialStats() {
    final totalShares = _sharedContent.length;
    final totalUsers = _userProfiles.length;
    final totalTrending = _trendingItems.length;

    return {
      'total_shares': totalShares,
      'total_users': totalUsers,
      'trending_items': totalTrending,
      'most_shared_type': _getMostSharedContentType(),
    };
  }

  String _getMostSharedContentType() {
    final typeCounts = <ContentType, int>{};
    for (final share in _sharedContent) {
      typeCounts[share.contentType] = (typeCounts[share.contentType] ?? 0) + 1;
    }

    if (typeCounts.isEmpty) return 'none';

    final mostShared = typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostShared.key.name;
  }
}

/// User social profile
class UserSocialProfile {
  final String userId;
  String displayName;
  String? bio;
  String? avatarUrl;
  bool isPublic;
  final DateTime joinDate;
  int totalShares;
  int totalPlaylists;
  int followers;
  int following;

  UserSocialProfile({
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.isPublic = true,
    required this.joinDate,
    this.totalShares = 0,
    this.totalPlaylists = 0,
    this.followers = 0,
    this.following = 0,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'isPublic': isPublic,
    'joinDate': joinDate.toIso8601String(),
    'totalShares': totalShares,
    'totalPlaylists': totalPlaylists,
    'followers': followers,
    'following': following,
  };

  factory UserSocialProfile.fromJson(Map<String, dynamic> json) => UserSocialProfile(
    userId: json['userId'],
    displayName: json['displayName'],
    bio: json['bio'],
    avatarUrl: json['avatarUrl'],
    isPublic: json['isPublic'] ?? true,
    joinDate: DateTime.parse(json['joinDate']),
    totalShares: json['totalShares'] ?? 0,
    totalPlaylists: json['totalPlaylists'] ?? 0,
    followers: json['followers'] ?? 0,
    following: json['following'] ?? 0,
  );
}

/// Shared content item
class SharedContent {
  final String id;
  final String userId;
  final ContentType contentType;
  final String contentId;
  final String title;
  final String? artist;
  final ShareMethod method;
  final DateTime timestamp;

  const SharedContent({
    required this.id,
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.title,
    this.artist,
    required this.method,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'contentType': contentType.name,
    'contentId': contentId,
    'title': title,
    'artist': artist,
    'method': method.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SharedContent.fromJson(Map<String, dynamic> json) => SharedContent(
    id: json['id'],
    userId: json['userId'],
    contentType: ContentType.values.firstWhere((e) => e.name == json['contentType']),
    contentId: json['contentId'],
    title: json['title'],
    artist: json['artist'],
    method: ShareMethod.values.firstWhere((e) => e.name == json['method']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

/// Trending item
class TrendingItem {
  final String id;
  final TrendingType type;
  final String title;
  final String? artist;
  final double popularityScore;
  final int shareCount;
  final int playCount;
  final DateTime timestamp;

  const TrendingItem({
    required this.id,
    required this.type,
    required this.title,
    this.artist,
    required this.popularityScore,
    required this.shareCount,
    required this.playCount,
    required this.timestamp,
  });
}

/// Public playlist
class PublicPlaylist {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final int songCount;
  final int followers;
  final bool isOfficial;
  final String? genre;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PublicPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.songCount,
    required this.followers,
    required this.isOfficial,
    this.genre,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Share result
class ShareResult {
  final bool success;
  final String? url;
  final String? error;

  const ShareResult._({
    required this.success,
    this.url,
    this.error,
  });

  factory ShareResult.success(String url) => ShareResult._(success: true, url: url);
  factory ShareResult.failure(String error) => ShareResult._(success: false, error: error);
}

enum ShareMethod { system, link, social, copy }
enum ContentType { song, playlist, album, artist }
enum TrendingType { all, song, playlist, album, artist }
enum PlaylistSortBy { popular, recent, name }