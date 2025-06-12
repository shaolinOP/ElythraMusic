// Stub database implementation for web platform
import 'dart:developer';

// Stub classes for web compatibility
class AppSettingsStrDB {
  String settingName = '';
  String settingValue = '';
  
  AppSettingsStrDB({this.settingName = '', this.settingValue = ''});
}

class AppSettingsIntDB {
  String settingName = '';
  int settingValue = 0;
  
  AppSettingsIntDB({this.settingName = '', this.settingValue = 0});
}

class AppSettingsBoolDB {
  String settingName = '';
  bool settingValue = false;
  
  AppSettingsBoolDB({this.settingName = '', this.settingValue = false});
}

class MediaPlaylistDB {
  String playlistName = '';
  List<String> mediaItems = [];
  DateTime lastUpdated = DateTime.now();
  
  MediaPlaylistDB({this.playlistName = '', this.mediaItems = const [], DateTime? lastUpdated})
      : lastUpdated = lastUpdated ?? DateTime.now();
}

class MediaItemDB {
  String title = '';
  String artist = '';
  String album = '';
  String artUri = '';
  String mediaID = '';
  String permaURL = '';
  String source = '';
  
  MediaItemDB({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.artUri = '',
    this.mediaID = '',
    this.permaURL = '',
    this.source = '',
  });
}

// Stub Isar class for web
class Isar {
  static Future<Isar> open(List<dynamic> schemas, {String? directory, String? name}) async {
    return Isar._();
  }
  
  Isar._();
  
  Future<void> close() async {}
}

// Stub database service
class ElythraDBService {
  static late Future<Isar> db;
  static late String appSuppDir;
  static late String appDocDir;
  static final ElythraDBService _instance = ElythraDBService._internal();
  
  ElythraDBService._internal();
  
  factory ElythraDBService() => _instance;
  
  static Future<void> initialize() async {
    log("Database not available on web platform", name: "ElythraDBService");
    db = Future.value(Isar._());
    appSuppDir = '/tmp';
    appDocDir = '/tmp';
  }
  
  static Future<void> putAppSettings(String key, dynamic value) async {
    log("Database operation not available on web", name: "ElythraDBService");
  }
  
  static Future<T?> getAppSettings<T>(String key) async {
    log("Database operation not available on web", name: "ElythraDBService");
    return null;
  }
  
  static Future<void> addMediaPlaylist(MediaPlaylistDB playlist) async {
    log("Database operation not available on web", name: "ElythraDBService");
  }
  
  static Future<List<MediaPlaylistDB>> getAllMediaPlaylists() async {
    log("Database operation not available on web", name: "ElythraDBService");
    return [];
  }
  
  static Future<void> addMediaItem(MediaItemDB mediaItem) async {
    log("Database operation not available on web", name: "ElythraDBService");
  }
  
  static Future<List<MediaItemDB>> getAllMediaItems() async {
    log("Database operation not available on web", name: "ElythraDBService");
    return [];
  }
}

// Stub hash function
int fastHash(String string) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < string.length; i++) {
    final codeUnit = string.codeUnitAt(i);
    hash ^= codeUnit;
    hash *= 0x01000193;
    hash = hash & 0x7FFFFFFF;
  }
  return hash;
}