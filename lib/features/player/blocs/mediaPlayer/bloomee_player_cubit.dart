import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elythra_music/core/model/songModel.dart';

// Custom MediaItem class to avoid conflicts
class MediaItem {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artUri;
  final Duration? duration;
  final Map<String, dynamic>? extras;

  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artUri,
    this.duration,
    this.extras,
  });

  // Convert from MediaItemModel
  factory MediaItem.fromMediaItemModel(MediaItemModel model) {
    return MediaItem(
      id: model.id,
      title: model.title,
      artist: model.artist,
      album: model.album,
      artUri: model.artUri?.toString(),
      duration: model.duration,
      extras: model.extras,
    );
  }

  // Convert to MediaItemModel
  MediaItemModel toMediaItemModel() {
    return MediaItemModel(
      id: id,
      title: title,
      artist: artist,
      album: album ?? '',
      artUri: artUri != null ? Uri.parse(artUri!) : null,
      duration: duration,
      extras: extras,
    );
  }
}

// MediaPlaylist class
class MediaPlaylist {
  final String name;
  final List<MediaItem> items;
  
  const MediaPlaylist({
    required this.name,
    required this.items,
  });
}

// Progress bar streams for UI
class ProgressBarStreams {
  final Duration currentPos;
  final PlaybackEvent currentPlaybackState;
  final PlayerState currentPlayerState;

  const ProgressBarStreams({
    required this.currentPos,
    required this.currentPlaybackState,
    required this.currentPlayerState,
  });
}

// Player states
abstract class ElythraPlayerState {
  bool get showLyrics => false;
}

class ElythraPlayerInitial extends ElythraPlayerState {}

class ElythraPlayerLoading extends ElythraPlayerState {}

class ElythraPlayerPlaying extends ElythraPlayerState {
  final MediaItem mediaItem;
  final bool showLyrics;
  ElythraPlayerPlaying(this.mediaItem, {this.showLyrics = false});
}

class ElythraPlayerPaused extends ElythraPlayerState {
  final MediaItem mediaItem;
  final bool showLyrics;
  ElythraPlayerPaused(this.mediaItem, {this.showLyrics = false});
}

class ElythraPlayerError extends ElythraPlayerState {
  final String message;
  ElythraPlayerError(this.message);
}

// Player initialization states
enum PlayerInitState {
  uninitialized,
  initializing,
  initialized,
  error,
}

// Mock BloomeePlayer class to match expected interface
class BloomeePlayer {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  // Streams
  Stream<String> get queueTitle => Stream.value("Current Queue");
  Stream<MediaItem?> get mediaItem => _mediaItemController.stream;
  Stream<bool> get shuffleMode => _shuffleModeController.stream;
  bool get shuffleModeValue => _shuffleModeController.value;
  
  // Controllers
  final BehaviorSubject<MediaItem?> _mediaItemController = BehaviorSubject<MediaItem?>();
  final BehaviorSubject<MediaItem?> _currentMediaItem = BehaviorSubject<MediaItem?>();
  final BehaviorSubject<bool> _shuffleModeController = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<MediaItem>> _queueController = BehaviorSubject<List<MediaItem>>.seeded([]);
  
  // Player state
  PlayerInitState playerInitState = PlayerInitState.initialized;
  
  // Methods
  Future<void> shuffle(bool enabled) async {
    _shuffleModeController.add(enabled);
    await audioPlayer.setShuffleModeEnabled(enabled);
  }
  
  Future<void> skipToNext() async {
    // Implementation for next track
  }
  
  Future<void> skipToPrevious() async {
    // Implementation for previous track
  }
  
  Future<void> setRepeatMode(LoopMode mode) async {
    await audioPlayer.setLoopMode(mode);
  }

  // Additional seek methods
  Future<void> seekNSecForward(Duration duration) async {
    final currentPosition = audioPlayer.position;
    final newPosition = currentPosition + duration;
    await audioPlayer.seek(newPosition);
  }

  Future<void> seekNSecBackward(Duration duration) async {
    final currentPosition = audioPlayer.position;
    final newPosition = currentPosition - duration;
    await audioPlayer.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  // Queue management
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // Implementation for adding items to queue
    print('Adding to queue: ${mediaItem.title}');
  }

  // Loop mode control
  Future<void> setLoopMode(LoopMode loopMode) async {
    await audioPlayer.setLoopMode(loopMode);
  }

  // Current media getter
  MediaItem? get currentMedia => _currentMediaItem.value;

  // Loop mode stream
  Stream<LoopMode> get loopMode => audioPlayer.loopModeStream;

  // Queue stream
  Stream<List<MediaItem>> get queue => Stream.value([]);

  // Load playlist
  Future<void> loadPlaylist(MediaPlaylist playlist) async {
    // Implementation for loading playlist
    _queueController.add(playlist.items);
    if (playlist.items.isNotEmpty) {
      _currentMediaItem.add(playlist.items.first);
      _mediaItemController.add(playlist.items.first);
    }
    print('Loading playlist: ${playlist.name}');
  }

  // Missing methods from error messages
  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> play() async {
    await audioPlayer.play();
  }

  Future<void> rewind() async {
    await audioPlayer.seek(Duration.zero);
  }

  Future<void> updateQueue(List<MediaItemModel> items, {bool doPlay = false, int idx = 0}) async {
    final mediaItems = items.map((item) => MediaItem.fromMediaItemModel(item)).toList();
    _queueController.add(mediaItems);
    if (mediaItems.isNotEmpty) {
      final targetItem = idx < mediaItems.length ? mediaItems[idx] : mediaItems.first;
      _currentMediaItem.add(targetItem);
      _mediaItemController.add(targetItem);
      if (doPlay) {
        await play();
      }
    }
  }

  Future<void> addPlayNextItem(MediaItemModel item) async {
    final mediaItem = MediaItem.fromMediaItemModel(item);
    final currentQueue = _queueController.value;
    final newQueue = [mediaItem, ...currentQueue];
    _queueController.add(newQueue);
  }

  Future<void> addQueueItems(List<MediaItemModel> items) async {
    final mediaItems = items.map((item) => MediaItem.fromMediaItemModel(item)).toList();
    final currentQueue = _queueController.value;
    final newQueue = [...currentQueue, ...mediaItems];
    _queueController.add(newQueue);
  }

  Future<void> skipToQueueItem(int index) async {
    final currentQueue = _queueController.value;
    if (index >= 0 && index < currentQueue.length) {
      final targetItem = currentQueue[index];
      _currentMediaItem.add(targetItem);
      _mediaItemController.add(targetItem);
    }
  }

  Future<void> removeQueueItemAt(int index) async {
    final currentQueue = _queueController.value;
    if (index >= 0 && index < currentQueue.length) {
      final newQueue = List<MediaItem>.from(currentQueue);
      newQueue.removeAt(index);
      _queueController.add(newQueue);
    }
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    final currentQueue = _queueController.value;
    if (oldIndex >= 0 && oldIndex < currentQueue.length && 
        newIndex >= 0 && newIndex < currentQueue.length) {
      final newQueue = List<MediaItem>.from(currentQueue);
      final item = newQueue.removeAt(oldIndex);
      newQueue.insert(newIndex, item);
      _queueController.add(newQueue);
    }
  }

  Future<void> check4RelatedSongs() async {
    // Implementation for checking related songs
    print('Checking for related songs...');
  }
  
  void dispose() {
    _mediaItemController.close();
    _currentMediaItem.close();
    _shuffleModeController.close();
    _queueController.close();
    audioPlayer.dispose();
  }
}

// Main player cubit
class ElythraPlayerCubit extends Cubit<ElythraPlayerState> {
  final BloomeePlayer _bloomeePlayer = BloomeePlayer();
  MediaItem? _currentMedia;
  bool _showLyrics = false;

  ElythraPlayerCubit() : super(ElythraPlayerInitial());

  // Getters
  MediaItem? get currentMedia => _currentMedia;
  BloomeePlayer get bloomeePlayer => _bloomeePlayer;
  PlayerInitState get playerInitState => _bloomeePlayer.playerInitState;
  
  // Progress streams
  Stream<ProgressBarStreams> get progressStreams {
    return Rx.combineLatest3<Duration, PlaybackEvent, PlayerState, ProgressBarStreams>(
      _bloomeePlayer.audioPlayer.positionStream,
      _bloomeePlayer.audioPlayer.playbackEventStream,
      _bloomeePlayer.audioPlayer.playerStateStream,
      (position, playbackEvent, playerState) => ProgressBarStreams(
        currentPos: position,
        currentPlaybackState: playbackEvent,
        currentPlayerState: playerState,
      ),
    );
  }

  // Lyrics control
  void switchShowLyrics({required bool value}) {
    _showLyrics = value;
    // Re-emit current state with updated lyrics flag
    if (state is ElythraPlayerPlaying) {
      final playingState = state as ElythraPlayerPlaying;
      emit(ElythraPlayerPlaying(playingState.mediaItem, showLyrics: _showLyrics));
    } else if (state is ElythraPlayerPaused) {
      final pausedState = state as ElythraPlayerPaused;
      emit(ElythraPlayerPaused(pausedState.mediaItem, showLyrics: _showLyrics));
    }
  }

  bool get showLyrics => _showLyrics;

  // Basic playback methods
  Future<void> play() async {
    try {
      await _bloomeePlayer.audioPlayer.play();
      if (_currentMedia != null) {
        emit(ElythraPlayerPlaying(_currentMedia!, showLyrics: _showLyrics));
      }
    } catch (e) {
      emit(ElythraPlayerError('Failed to play: $e'));
    }
  }

  Future<void> pause() async {
    try {
      await _bloomeePlayer.audioPlayer.pause();
      if (_currentMedia != null) {
        emit(ElythraPlayerPaused(_currentMedia!, showLyrics: _showLyrics));
      }
    } catch (e) {
      emit(ElythraPlayerError('Failed to pause: $e'));
    }
  }

  Future<void> stop() async {
    try {
      await _bloomeePlayer.audioPlayer.stop();
      emit(ElythraPlayerInitial());
    } catch (e) {
      emit(ElythraPlayerError('Failed to stop: $e'));
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _bloomeePlayer.audioPlayer.seek(position);
    } catch (e) {
      emit(ElythraPlayerError('Failed to seek: $e'));
    }
  }

  Future<void> loadMedia(MediaItem mediaItem) async {
    try {
      emit(ElythraPlayerLoading());
      _currentMedia = mediaItem;
      _bloomeePlayer._mediaItemController.add(mediaItem);
      
      // Load audio source (placeholder implementation)
      // await _bloomeePlayer.audioPlayer.setUrl(mediaItem.artUri ?? '');
      
      emit(ElythraPlayerPaused(mediaItem));
    } catch (e) {
      emit(ElythraPlayerError('Failed to load media: $e'));
    }
  }

  @override
  Future<void> close() {
    _bloomeePlayer.dispose();
    return super.close();
  }
}