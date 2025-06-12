import 'dart:io';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Desktop system tray integration with media controls
/// Integrated from Harmony-Music with cross-platform support
class DesktopSystemTray {
  static final DesktopSystemTray _instance = DesktopSystemTray._internal();
  factory DesktopSystemTray() => _instance;
  DesktopSystemTray._internal();

  static const MethodChannel _channel = MethodChannel('elythra_music/system_tray');
  static const MethodChannel _hotkeysChannel = MethodChannel('elythra_music/hotkeys');

  bool _isInitialized = false;
  bool _isVisible = true;

  // Current track info for tray display
  String? _currentTitle;
  String? _currentArtist;
  bool _isPlaying = false;

  /// Initialize system tray (desktop platforms only)
  Future<void> initialize() async {
    if (!_isDesktopPlatform()) {
      log('ℹ️ Desktop Tray: Not a desktop platform, skipping initialization');
      return;
    }

    try {
      log('🔄 Desktop Tray: Initializing system tray...');

      // Initialize tray icon
      await _initializeTrayIcon();
      
      // Set up context menu
      await _setupContextMenu();
      
      // Register global hotkeys
      await _registerGlobalHotkeys();
      
      // Set up method call handlers
      _channel.setMethodCallHandler(_handleMethodCall);
      _hotkeysChannel.setMethodCallHandler(_handleHotkeyCall);

      _isInitialized = true;
      log('✅ Desktop Tray: System tray initialized successfully');

    } catch (e) {
      log('❌ Desktop Tray: Failed to initialize: $e');
    }
  }

  /// Initialize tray icon
  Future<void> _initializeTrayIcon() async {
    try {
      final iconPath = _getTrayIconPath();
      await _channel.invokeMethod('initializeTray', {
        'iconPath': iconPath,
        'tooltip': 'Elythra Music',
      });
    } catch (e) {
      log('❌ Desktop Tray: Failed to initialize icon: $e');
    }
  }

  /// Set up context menu
  Future<void> _setupContextMenu() async {
    try {
      final menuItems = [
        {
          'id': 'show_hide',
          'label': _isVisible ? 'Hide Window' : 'Show Window',
          'enabled': true,
        },
        {'id': 'separator1', 'type': 'separator'},
        {
          'id': 'previous',
          'label': 'Previous Track',
          'enabled': true,
          'icon': 'previous',
        },
        {
          'id': 'play_pause',
          'label': _isPlaying ? 'Pause' : 'Play',
          'enabled': true,
          'icon': _isPlaying ? 'pause' : 'play',
        },
        {
          'id': 'next',
          'label': 'Next Track',
          'enabled': true,
          'icon': 'next',
        },
        {'id': 'separator2', 'type': 'separator'},
        {
          'id': 'current_track',
          'label': _getCurrentTrackLabel(),
          'enabled': false,
        },
        {'id': 'separator3', 'type': 'separator'},
        {
          'id': 'settings',
          'label': 'Settings',
          'enabled': true,
          'icon': 'settings',
        },
        {
          'id': 'quit',
          'label': 'Quit Elythra Music',
          'enabled': true,
          'icon': 'quit',
        },
      ];

      await _channel.invokeMethod('setupContextMenu', {
        'items': menuItems,
      });
    } catch (e) {
      log('❌ Desktop Tray: Failed to setup context menu: $e');
    }
  }

  /// Register global hotkeys
  Future<void> _registerGlobalHotkeys() async {
    try {
      final hotkeys = [
        {
          'id': 'play_pause',
          'keys': _getPlayPauseHotkey(),
          'description': 'Play/Pause',
        },
        {
          'id': 'next_track',
          'keys': _getNextTrackHotkey(),
          'description': 'Next Track',
        },
        {
          'id': 'previous_track',
          'keys': _getPreviousTrackHotkey(),
          'description': 'Previous Track',
        },
        {
          'id': 'volume_up',
          'keys': _getVolumeUpHotkey(),
          'description': 'Volume Up',
        },
        {
          'id': 'volume_down',
          'keys': _getVolumeDownHotkey(),
          'description': 'Volume Down',
        },
      ];

      await _hotkeysChannel.invokeMethod('registerHotkeys', {
        'hotkeys': hotkeys,
      });

      log('✅ Desktop Tray: Global hotkeys registered');
    } catch (e) {
      log('❌ Desktop Tray: Failed to register hotkeys: $e');
    }
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTrayIconClicked':
        await _handleTrayIconClick();
        break;
      case 'onContextMenuClicked':
        await _handleContextMenuClick(call.arguments['itemId']);
        break;
      case 'onWindowVisibilityChanged':
        _isVisible = call.arguments['visible'];
        await _updateContextMenu();
        break;
      default:
        log('⚠️ Desktop Tray: Unknown method call: ${call.method}');
    }
  }

  /// Handle hotkey calls
  Future<dynamic> _handleHotkeyCall(MethodCall call) async {
    switch (call.method) {
      case 'onHotkeyPressed':
        await _handleHotkeyPressed(call.arguments['hotkeyId']);
        break;
      default:
        log('⚠️ Desktop Tray: Unknown hotkey call: ${call.method}');
    }
  }

  /// Handle tray icon click
  Future<void> _handleTrayIconClick() async {
    try {
      await _channel.invokeMethod('toggleWindowVisibility');
      log('🖱️ Desktop Tray: Tray icon clicked');
    } catch (e) {
      log('❌ Desktop Tray: Failed to handle tray click: $e');
    }
  }

  /// Handle context menu clicks
  Future<void> _handleContextMenuClick(String itemId) async {
    try {
      switch (itemId) {
        case 'show_hide':
          await _channel.invokeMethod('toggleWindowVisibility');
          break;
        case 'previous':
          await _triggerMediaAction('previous');
          break;
        case 'play_pause':
          await _triggerMediaAction('play_pause');
          break;
        case 'next':
          await _triggerMediaAction('next');
          break;
        case 'settings':
          await _channel.invokeMethod('showSettings');
          break;
        case 'quit':
          await _channel.invokeMethod('quitApplication');
          break;
      }
      log('🖱️ Desktop Tray: Context menu item clicked: $itemId');
    } catch (e) {
      log('❌ Desktop Tray: Failed to handle context menu click: $e');
    }
  }

  /// Handle hotkey presses
  Future<void> _handleHotkeyPressed(String hotkeyId) async {
    try {
      switch (hotkeyId) {
        case 'play_pause':
          await _triggerMediaAction('play_pause');
          break;
        case 'next_track':
          await _triggerMediaAction('next');
          break;
        case 'previous_track':
          await _triggerMediaAction('previous');
          break;
        case 'volume_up':
          await _triggerMediaAction('volume_up');
          break;
        case 'volume_down':
          await _triggerMediaAction('volume_down');
          break;
      }
      log('⌨️ Desktop Tray: Hotkey pressed: $hotkeyId');
    } catch (e) {
      log('❌ Desktop Tray: Failed to handle hotkey: $e');
    }
  }

  /// Trigger media action (to be connected to player)
  Future<void> _triggerMediaAction(String action) async {
    // This would be connected to the actual player service
    // For now, just log the action
    log('🎵 Desktop Tray: Media action triggered: $action');
    
    // TODO: Connect to ElythraPlayerCubit
    // Example:
    // final player = GetIt.instance<ElythraPlayerCubit>();
    // switch (action) {
    //   case 'play_pause':
    //     player.playPause();
    //     break;
    //   case 'next':
    //     player.skipToNext();
    //     break;
    //   case 'previous':
    //     player.skipToPrevious();
    //     break;
    // }
  }

  /// Update current track info
  Future<void> updateCurrentTrack({
    String? title,
    String? artist,
    bool? isPlaying,
  }) async {
    if (!_isInitialized) return;

    try {
      _currentTitle = title;
      _currentArtist = artist;
      if (isPlaying != null) _isPlaying = isPlaying;

      await _updateContextMenu();
      await _updateTrayTooltip();

      log('🎵 Desktop Tray: Updated current track: $title by $artist');
    } catch (e) {
      log('❌ Desktop Tray: Failed to update current track: $e');
    }
  }

  /// Update context menu
  Future<void> _updateContextMenu() async {
    if (!_isInitialized) return;
    await _setupContextMenu();
  }

  /// Update tray tooltip
  Future<void> _updateTrayTooltip() async {
    if (!_isInitialized) return;

    try {
      final tooltip = _getCurrentTrackLabel();
      await _channel.invokeMethod('updateTooltip', {
        'tooltip': tooltip,
      });
    } catch (e) {
      log('❌ Desktop Tray: Failed to update tooltip: $e');
    }
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String message,
    String? iconPath,
  }) async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'message': message,
        'iconPath': iconPath ?? _getTrayIconPath(),
      });
    } catch (e) {
      log('❌ Desktop Tray: Failed to show notification: $e');
    }
  }

  /// Get current track label for display
  String _getCurrentTrackLabel() {
    if (_currentTitle != null && _currentArtist != null) {
      final status = _isPlaying ? '▶️' : '⏸️';
      return '$status $_currentTitle - $_currentArtist';
    } else if (_currentTitle != null) {
      final status = _isPlaying ? '▶️' : '⏸️';
      return '$status $_currentTitle';
    } else {
      return 'Elythra Music - No track playing';
    }
  }

  /// Get tray icon path based on platform
  String _getTrayIconPath() {
    if (Platform.isWindows) {
      return 'assets/icons/tray_icon.ico';
    } else if (Platform.isMacOS) {
      return 'assets/icons/tray_icon.png';
    } else {
      return 'assets/icons/tray_icon.png';
    }
  }

  /// Get platform-specific hotkey combinations
  List<String> _getPlayPauseHotkey() {
    if (Platform.isWindows) {
      return ['ctrl', 'alt', 'space'];
    } else if (Platform.isMacOS) {
      return ['cmd', 'alt', 'space'];
    } else {
      return ['ctrl', 'alt', 'space'];
    }
  }

  List<String> _getNextTrackHotkey() {
    if (Platform.isWindows) {
      return ['ctrl', 'alt', 'right'];
    } else if (Platform.isMacOS) {
      return ['cmd', 'alt', 'right'];
    } else {
      return ['ctrl', 'alt', 'right'];
    }
  }

  List<String> _getPreviousTrackHotkey() {
    if (Platform.isWindows) {
      return ['ctrl', 'alt', 'left'];
    } else if (Platform.isMacOS) {
      return ['cmd', 'alt', 'left'];
    } else {
      return ['ctrl', 'alt', 'left'];
    }
  }

  List<String> _getVolumeUpHotkey() {
    if (Platform.isWindows) {
      return ['ctrl', 'alt', 'up'];
    } else if (Platform.isMacOS) {
      return ['cmd', 'alt', 'up'];
    } else {
      return ['ctrl', 'alt', 'up'];
    }
  }

  List<String> _getVolumeDownHotkey() {
    if (Platform.isWindows) {
      return ['ctrl', 'alt', 'down'];
    } else if (Platform.isMacOS) {
      return ['cmd', 'alt', 'down'];
    } else {
      return ['ctrl', 'alt', 'down'];
    }
  }

  /// Check if current platform supports system tray
  bool _isDesktopPlatform() {
    return !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('dispose');
      await _hotkeysChannel.invokeMethod('unregisterAllHotkeys');
      _isInitialized = false;
      log('✅ Desktop Tray: Disposed successfully');
    } catch (e) {
      log('❌ Desktop Tray: Failed to dispose: $e');
    }
  }
}

/// Desktop notification data
class DesktopNotification {
  final String title;
  final String message;
  final String? iconPath;
  final Duration? duration;
  final List<NotificationAction>? actions;

  const DesktopNotification({
    required this.title,
    required this.message,
    this.iconPath,
    this.duration,
    this.actions,
  });
}

/// Notification action
class NotificationAction {
  final String id;
  final String label;
  final String? iconPath;

  const NotificationAction({
    required this.id,
    required this.label,
    this.iconPath,
  });
}

/// System tray menu item
class TrayMenuItem {
  final String id;
  final String label;
  final bool enabled;
  final String? iconPath;
  final List<TrayMenuItem>? submenu;
  final bool isSeparator;

  const TrayMenuItem({
    required this.id,
    required this.label,
    this.enabled = true,
    this.iconPath,
    this.submenu,
    this.isSeparator = false,
  });

  factory TrayMenuItem.separator() => const TrayMenuItem(
    id: 'separator',
    label: '',
    isSeparator: true,
  );
}