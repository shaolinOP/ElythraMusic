import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// Custom MediaItem class to avoid conflicts
class MediaItem {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artUri;
  final Duration? duration;

  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artUri,
    this.duration,
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
abstract class ElythraPlayerState {}

class ElythraPlayerInitial extends ElythraPlayerState {}

class ElythraPlayerLoading extends ElythraPlayerState {}

class ElythraPlayerPlaying extends ElythraPlayerState {
  final MediaItem mediaItem;
  ElythraPlayerPlaying(this.mediaItem);
}

class ElythraPlayerPaused extends ElythraPlayerState {
  final MediaItem mediaItem;
  ElythraPlayerPaused(this.mediaItem);
}

class ElythraPlayerError extends ElythraPlayerState {
  final String message;
  ElythraPlayerError(this.message);
}

// Mock BloomeePlayer class to match expected interface
class BloomeePlayer {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  // Streams
  Stream<String> get queueTitle => Stream.value("Current Queue");
  Stream<MediaItem?> get mediaItem => _mediaItemController.stream;
  Stream<bool> get shuffleMode => _shuffleModeController.stream;
  
  // Controllers
  final BehaviorSubject<MediaItem?> _mediaItemController = BehaviorSubject<MediaItem?>();
  final BehaviorSubject<bool> _shuffleModeController = BehaviorSubject<bool>.seeded(false);
  
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
  
  void dispose() {
    _mediaItemController.close();
    _shuffleModeController.close();
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
  }

  bool get showLyrics => _showLyrics;

  // Basic playback methods
  Future<void> play() async {
    try {
      await _bloomeePlayer.audioPlayer.play();
      if (_currentMedia != null) {
        emit(ElythraPlayerPlaying(_currentMedia!));
      }
    } catch (e) {
      emit(ElythraPlayerError('Failed to play: $e'));
    }
  }

  Future<void> pause() async {
    try {
      await _bloomeePlayer.audioPlayer.pause();
      if (_currentMedia != null) {
        emit(ElythraPlayerPaused(_currentMedia!));
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