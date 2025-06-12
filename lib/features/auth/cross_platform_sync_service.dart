import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elythra_music/features/auth/webview_auth_service.dart';

/// Comprehensive cross-platform synchronization service
/// Supports both Firebase Auth and WebView Auth for maximum compatibility
class CrossPlatformSyncService {
  static final CrossPlatformSyncService _instance = CrossPlatformSyncService._internal();
  factory CrossPlatformSyncService() => _instance;
  CrossPlatformSyncService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WebViewAuthService _webViewAuth = WebViewAuthService();

  // Sync status stream
  final StreamController<SyncStatus> _syncStatusController = 
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle();
  SyncStatus get currentStatus => _currentStatus;

  // Local storage keys
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncDataKey = 'cached_sync_data';
  static const String _conflictResolutionKey = 'conflict_resolution_strategy';

  /// Initialize the sync service
  Future<void> initialize() async {
    try {
      await _webViewAuth.initialize();
      _setupAuthListeners();
      await _performInitialSync();
      log('✅ CrossPlatform Sync: Service initialized');
    } catch (e) {
      log('❌ CrossPlatform Sync: Initialization failed - $e');
    }
  }

  /// Set up authentication state listeners
  void _setupAuthListeners() {
    // Firebase Auth listener
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        log('🔐 CrossPlatform Sync: Firebase user signed in');
        _triggerSync(SyncTrigger.firebaseAuth);
      }
    });

    // WebView Auth listener
    _webViewAuth.authStateChanges.listen((WebViewAuthState state) {
      if (state.isAuthenticated) {
        log('🔐 CrossPlatform Sync: WebView user signed in');
        _triggerSync(SyncTrigger.webViewAuth);
      }
    });
  }

  /// Trigger synchronization
  Future<void> _triggerSync(SyncTrigger trigger) async {
    if (_currentStatus.isActive) {
      log('⏳ CrossPlatform Sync: Sync already in progress, skipping');
      return;
    }

    _updateStatus(SyncStatus.syncing(trigger: trigger));

    try {
      await _performFullSync();
      _updateStatus(SyncStatus.completed(
        trigger: trigger,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _updateStatus(SyncStatus.failed(
        trigger: trigger,
        error: e.toString(),
      ));
    }
  }

  /// Perform initial sync on app startup
  Future<void> _performInitialSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);
      
      if (lastSync != null) {
        final lastSyncTime = DateTime.parse(lastSync);
        final timeSinceSync = DateTime.now().difference(lastSyncTime);
        
        // Auto-sync if last sync was more than 1 hour ago
        if (timeSinceSync.inHours >= 1) {
          await _triggerSync(SyncTrigger.automatic);
        }
      } else {
        // First time setup
        await _triggerSync(SyncTrigger.firstTime);
      }
    } catch (e) {
      log('❌ CrossPlatform Sync: Initial sync failed - $e');
    }
  }

  /// Perform full synchronization
  Future<void> _performFullSync() async {
    log('🔄 CrossPlatform Sync: Starting full sync...');

    // Collect data from all sources
    final localData = await _collectLocalData();
    final firebaseData = await _collectFirebaseData();
    final webViewData = await _collectWebViewData();

    // Merge and resolve conflicts
    final mergedData = await _mergeData(localData, firebaseData, webViewData);

    // Upload merged data to all platforms
    await _uploadToAllPlatforms(mergedData);

    // Update local cache
    await _updateLocalCache(mergedData);

    log('✅ CrossPlatform Sync: Full sync completed');
  }

  /// Collect local data
  Future<Map<String, dynamic>> _collectLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_syncDataKey);
      
      if (cachedData != null) {
        return json.decode(cachedData) as Map<String, dynamic>;
      }
      
      return {
        'playlists': [],
        'favorites': [],
        'history': [],
        'settings': {},
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('❌ CrossPlatform Sync: Failed to collect local data - $e');
      return {};
    }
  }

  /// Collect Firebase data
  Future<Map<String, dynamic>> _collectFirebaseData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return {};

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return {};

      // Get playlists
      final playlistsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('playlists')
          .get();

      // Get favorites
      final favoritesDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('favorites')
          .get();

      // Get history
      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('playedAt', descending: true)
          .limit(1000)
          .get();

      return {
        'playlists': playlistsSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList(),
        'favorites': favoritesDoc.exists ? favoritesDoc.data() : {},
        'history': historySnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList(),
        'settings': userDoc.data() ?? {},
        'source': 'firebase',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('❌ CrossPlatform Sync: Failed to collect Firebase data - $e');
      return {};
    }
  }

  /// Collect WebView data
  Future<Map<String, dynamic>> _collectWebViewData() async {
    try {
      final webViewState = _webViewAuth.currentState;
      if (!webViewState.isAuthenticated) return {};

      final syncData = await _webViewAuth.getSyncData();
      return syncData ?? {};
    } catch (e) {
      log('❌ CrossPlatform Sync: Failed to collect WebView data - $e');
      return {};
    }
  }

  /// Merge data from all sources and resolve conflicts
  Future<Map<String, dynamic>> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> firebaseData,
    Map<String, dynamic> webViewData,
  ) async {
    try {
      log('🔄 CrossPlatform Sync: Merging data from all sources...');

      final mergedData = <String, dynamic>{};

      // Merge playlists (keep most recent, merge unique items)
      mergedData['playlists'] = _mergePlaylists([
        localData['playlists'] ?? [],
        firebaseData['playlists'] ?? [],
        webViewData['playlists'] ?? [],
      ]);

      // Merge favorites (union of all favorites)
      mergedData['favorites'] = _mergeFavorites([
        localData['favorites'] ?? {},
        firebaseData['favorites'] ?? {},
        webViewData['favorites'] ?? {},
      ]);

      // Merge history (keep most recent, deduplicate)
      mergedData['history'] = _mergeHistory([
        localData['history'] ?? [],
        firebaseData['history'] ?? [],
        webViewData['history'] ?? [],
      ]);

      // Merge settings (most recent wins, with user preference)
      mergedData['settings'] = _mergeSettings([
        localData['settings'] ?? {},
        firebaseData['settings'] ?? {},
        webViewData['settings'] ?? {},
      ]);

      mergedData['lastMerged'] = DateTime.now().toIso8601String();
      mergedData['sources'] = ['local', 'firebase', 'webview'];

      log('✅ CrossPlatform Sync: Data merged successfully');
      return mergedData;
    } catch (e) {
      log('❌ CrossPlatform Sync: Data merge failed - $e');
      rethrow;
    }
  }

  /// Merge playlists from multiple sources
  List<Map<String, dynamic>> _mergePlaylists(List<List<dynamic>> playlistSources) {
    final Map<String, Map<String, dynamic>> playlistMap = {};

    for (final source in playlistSources) {
      for (final playlist in source) {
        if (playlist is Map<String, dynamic>) {
          final id = playlist['id'] ?? playlist['name'] ?? '';
          if (id.isNotEmpty) {
            // Keep the most recently updated playlist
            if (!playlistMap.containsKey(id) ||
                _isMoreRecent(playlist, playlistMap[id]!)) {
              playlistMap[id] = playlist;
            }
          }
        }
      }
    }

    return playlistMap.values.toList();
  }

  /// Merge favorites from multiple sources
  Map<String, dynamic> _mergeFavorites(List<Map<String, dynamic>> favoritesSources) {
    final Set<String> allFavorites = {};
    DateTime? latestUpdate;

    for (final source in favoritesSources) {
      final songIds = source['songIds'];
      if (songIds is List) {
        allFavorites.addAll(songIds.cast<String>());
      }

      final updatedAt = source['updatedAt'];
      if (updatedAt != null) {
        final updateTime = _parseTimestamp(updatedAt);
        if (latestUpdate == null || updateTime.isAfter(latestUpdate)) {
          latestUpdate = updateTime;
        }
      }
    }

    return {
      'songIds': allFavorites.toList(),
      'updatedAt': latestUpdate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Merge history from multiple sources
  List<Map<String, dynamic>> _mergeHistory(List<List<dynamic>> historySources) {
    final Map<String, Map<String, dynamic>> historyMap = {};

    for (final source in historySources) {
      for (final item in source) {
        if (item is Map<String, dynamic>) {
          final songId = item['songId'] ?? item['id'] ?? '';
          final playedAt = item['playedAt'];
          
          if (songId.isNotEmpty && playedAt != null) {
            final key = '$songId-${_parseTimestamp(playedAt).millisecondsSinceEpoch}';
            historyMap[key] = item;
          }
        }
      }
    }

    // Sort by played time (most recent first)
    final sortedHistory = historyMap.values.toList();
    sortedHistory.sort((a, b) {
      final aTime = _parseTimestamp(a['playedAt']);
      final bTime = _parseTimestamp(b['playedAt']);
      return bTime.compareTo(aTime);
    });

    // Keep only the most recent 1000 items
    return sortedHistory.take(1000).toList();
  }

  /// Merge settings from multiple sources
  Map<String, dynamic> _mergeSettings(List<Map<String, dynamic>> settingsSources) {
    final mergedSettings = <String, dynamic>{};

    for (final source in settingsSources) {
      for (final entry in source.entries) {
        if (!mergedSettings.containsKey(entry.key) ||
            _isMoreRecent(source, mergedSettings)) {
          mergedSettings[entry.key] = entry.value;
        }
      }
    }

    return mergedSettings;
  }

  /// Upload merged data to all platforms
  Future<void> _uploadToAllPlatforms(Map<String, dynamic> mergedData) async {
    final futures = <Future>[];

    // Upload to Firebase
    if (_firebaseAuth.currentUser != null) {
      futures.add(_uploadToFirebase(mergedData));
    }

    // Upload to WebView storage
    if (_webViewAuth.currentState.isAuthenticated) {
      futures.add(_uploadToWebView(mergedData));
    }

    await Future.wait(futures);
  }

  /// Upload data to Firebase
  Future<void> _uploadToFirebase(Map<String, dynamic> data) async {
    try {
      final user = _firebaseAuth.currentUser!;
      final batch = _firestore.batch();

      // Update user document
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, data['settings'], SetOptions(merge: true));

      // Update favorites
      final favoritesRef = userRef.collection('preferences').doc('favorites');
      batch.set(favoritesRef, data['favorites'], SetOptions(merge: true));

      await batch.commit();
      log('✅ CrossPlatform Sync: Data uploaded to Firebase');
    } catch (e) {
      log('❌ CrossPlatform Sync: Firebase upload failed - $e');
    }
  }

  /// Upload data to WebView storage
  Future<void> _uploadToWebView(Map<String, dynamic> data) async {
    try {
      await _webViewAuth.saveSyncData(data);
      log('✅ CrossPlatform Sync: Data uploaded to WebView storage');
    } catch (e) {
      log('❌ CrossPlatform Sync: WebView upload failed - $e');
    }
  }

  /// Update local cache
  Future<void> _updateLocalCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncDataKey, json.encode(data));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      log('✅ CrossPlatform Sync: Local cache updated');
    } catch (e) {
      log('❌ CrossPlatform Sync: Local cache update failed - $e');
    }
  }

  /// Helper methods
  bool _isMoreRecent(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aTime = _parseTimestamp(a['updatedAt'] ?? a['lastUpdated']);
    final bTime = _parseTimestamp(b['updatedAt'] ?? b['lastUpdated']);
    return aTime.isAfter(bTime);
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      return (timestamp as dynamic).toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Public API methods
  Future<void> forceSyncNow() async {
    await _triggerSync(SyncTrigger.manual);
  }

  Future<Map<String, dynamic>?> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_syncDataKey);
    if (cachedData != null) {
      return json.decode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  void dispose() {
    _syncStatusController.close();
  }
}

/// Sync status tracking
class SyncStatus {
  final SyncState state;
  final SyncTrigger? trigger;
  final DateTime? timestamp;
  final String? error;

  const SyncStatus._({
    required this.state,
    this.trigger,
    this.timestamp,
    this.error,
  });

  factory SyncStatus.idle() => const SyncStatus._(state: SyncState.idle);
  
  factory SyncStatus.syncing({required SyncTrigger trigger}) => 
      SyncStatus._(state: SyncState.syncing, trigger: trigger);
  
  factory SyncStatus.completed({
    required SyncTrigger trigger,
    required DateTime timestamp,
  }) => SyncStatus._(
    state: SyncState.completed,
    trigger: trigger,
    timestamp: timestamp,
  );
  
  factory SyncStatus.failed({
    required SyncTrigger trigger,
    required String error,
  }) => SyncStatus._(
    state: SyncState.failed,
    trigger: trigger,
    error: error,
  );

  bool get isActive => state == SyncState.syncing;
  bool get isCompleted => state == SyncState.completed;
  bool get isFailed => state == SyncState.failed;
}

enum SyncState { idle, syncing, completed, failed }

enum SyncTrigger {
  manual,
  automatic,
  firebaseAuth,
  webViewAuth,
  firstTime,
}