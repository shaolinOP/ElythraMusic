import 'dart:developer';
import 'dart:io';
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/core/routes_and_consts/global_conts.dart';
import 'package:dart_discord_rpc/dart_discord_rpc.dart';

class DiscordService {
  static DiscordRPC? _discordRPC;
  static int? _startTimeStamp; // Persisting timestamp

  /// Initializes Discord RPC once
  static void initialize() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        DiscordRPC.initialize();
        _discordRPC = DiscordRPC(applicationId: '1339113296405725235');
        _discordRPC?.start(autoRegister: true);
        log(" Discord RPC initialized successfully", name: "DiscordService");
      } catch (e) {
        log(' Failed to initialize Discord RPC: $e', name: "DiscordService");
      }
    }
  }

  /// Updates the Discord presence
  static void updatePresence(MediaItemModel mediaItem) {
    if (_discordRPC != null && mediaItem != mediaItemModelNull) {
      try {
        _startTimeStamp ??= DateTime.now().millisecondsSinceEpoch;

        _discordRPC!.updatePresence(
          DiscordPresence(
              details: mediaItem.title,
              state: "Playing・${mediaItem.artist?.isNotEmpty == true ? mediaItem.artist : 'Unknown Artist'}",
              largeImageKey: "bloomeetunes_logo",
              largeImageText: "ElythraTunes",
              startTimeStamp: _startTimeStamp),
        );
      } catch (e) {
        log(" Discord RPC Error: $e", name: "DiscordService");
      }
    }
  }

  /// Clears Discord presence
  static void clearPresence() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        _discordRPC?.clearPresence();
        log(" Cleared Discord Presence", name: "DiscordService");
      } catch (e) {
        log(" Failed to clear Discord RPC: $e", name: "DiscordService");
      }
    }
  }
}
