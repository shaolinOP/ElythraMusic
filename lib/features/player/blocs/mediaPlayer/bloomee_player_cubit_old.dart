import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

// Player States
abstract class ElythraPlayerState {
  final bool isPlaying;
  final @override
 bool showLyrics;
  final MediaItem? currentMedia;
  final Duration position;
  final Duration duration;

  const ElythraPlayerState({
    this.isPlaying = false,
    this.showLyrics = false,
    this.currentMedia,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
}

class ElythraPlayerInitial extends ElythraPlayerState {}

class ElythraPlayerLoaded extends ElythraPlayerState {
  const ElythraPlayerLoaded({
    required bool isPlaying,
    required @override
 bool showLyrics,
    required MediaItem? currentMedia,
    required Duration position,
    required Duration duration,
  }) : super(
    isPlaying: isPlaying,
    showLyrics: showLyrics,
    currentMedia: currentMedia,
    position: position,
    duration: duration,
  );
}

class ElythraPlayerError extends ElythraPlayerState {
  final String message;
  const ElythraPlayerError(this.message);
}

// Media Item Model
class MediaItem {
  final String? id;
  final String? title;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final String? url;

  MediaItem({
    this.id,
    this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.url,
  });
}

// Progress Bar Streams Model
class ProgressBarStreams {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  ProgressBarStreams({
    required this.position,
    required this.duration,
    required this.bufferedPosition,
  });
}

// Player Cubit
class ElythraPlayerCubit extends Cubit<ElythraPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showLyrics = false;

  ElythraPlayerCubit() : super(ElythraPlayerInitial()) {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      _updateState();
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _updateState();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _updateState();
    });
  }

  void _updateState() {
    final currentMedia = _getCurrentMedia();
    emit(ElythraPlayerLoaded(
      isPlaying: _audioPlayer.playing,
      showLyrics: _showLyrics,
      currentMedia: currentMedia,
      position: _audioPlayer.position,
      duration: _audioPlayer.duration ?? Duration.zero,
    ));
  }

  MediaItem? _getCurrentMedia() {
    // This would get the current media from the audio player
    // For now, return a placeholder
    return MediaItem(
      id: "1",
      title: "Sample Song",
      artist: "Sample Artist",
      album: "Sample Album",
    );
  }

  // Player Controls
  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
    } catch (e) {
      emit(ElythraPlayerError("Failed to load audio: $e"));
    }
  }

  // Lyrics Controls
  void toggleLyrics() {
    _showLyrics = !_showLyrics;
    _updateState();
  }

  void showLyrics() {
    _showLyrics = true;
    _updateState();
  }

  void hideLyrics() {
    _showLyrics = false;
    _updateState();
  }

  // Progress Stream
  Stream<ProgressBarStreams> get progressBarStream {
    return _audioPlayer.positionStream.map((position) {
      return ProgressBarStreams(
        position: position,
        duration: _audioPlayer.duration ?? Duration.zero,
        bufferedPosition: _audioPlayer.bufferedPosition,
      );
    });
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}