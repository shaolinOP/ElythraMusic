import 'dart:developer';
import 'package:elythra_music/core/model/song_model.dart';

class DiscordService {
  static int? _startTimeStamp; // Persisting timestamp

  /// Initializes Discord RPC once (stub for web)
  static void initialize() {
    log("Discord RPC not available on web platform", name: "DiscordService");
  }

  /// Updates Discord Rich Presence with current song info (stub for web)
  static void updatePresence(MediaItemModel song) {
    log("Discord RPC not available on web platform", name: "DiscordService");
  }

  /// Clears Discord Rich Presence (stub for web)
  static void clearPresence() {
    log("Discord RPC not available on web platform", name: "DiscordService");
  }

  /// Shuts down Discord RPC (stub for web)
  static void shutdown() {
    log("Discord RPC not available on web platform", name: "DiscordService");
  }
}