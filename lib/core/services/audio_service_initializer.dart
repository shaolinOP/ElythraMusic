import 'package:elythra_music/core/services/bloomee_player.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:audio_service/audio_service.dart';

class PlayerInitializer {
  static final PlayerInitializer _instance = PlayerInitializer._internal();
  factory PlayerInitializer() {
    return _instance;
  }

  PlayerInitializer._internal();

  static bool _isInitialized = false;
  static ElythraMusicPlayer? bloomeeMusicPlayer;

  Future<void> _initialize() async {
    bloomeeMusicPlayer = await AudioService.init(
      builder: () => ElythraMusicPlayer(),
      config: const AudioServiceConfig(
        androidStopForegroundOnPause: false,
        androidNotificationChannelId: 'com.elythra.music.notification.status',
        androidNotificationChannelName: 'Elythra Music',
        androidResumeOnClick: true,
        // androidNotificationIcon: 'assets/icons/elythra_logo_fore.png',
        androidShowNotificationBadge: true,
        notificationColor: Default_Theme.accentColor2,
      ),
    );
  }

  Future<ElythraMusicPlayer> getElythraMusicPlayer() async {
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }
    return bloomeeMusicPlayer!;
  }
}
