import 'package:elythra_music/core/services/audio_service_initializer.dart';
import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elythra_music/core/services/bloomee_player.dart';
import 'package:elythra_music/core/model/song_model.dart';
part 'elythra_player_state.dart';

// Custom ElythraMediaItem class to avoid conflicts
class ElythraMediaItem {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artUri;
  final Duration? duration;
  final Map<String, dynamic>? extras;

  const ElythraMediaItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artUri,
    this.duration,
    this.extras,
  });

  // Convert from MediaItemModel
  factory ElythraMediaItem.fromMediaItemModel(MediaItemModel model) {
    return ElythraMediaItem(
      id: model.id,
      title: model.title,
      artist: model.artist ?? 'Unknown Artist',
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

enum PlayerInitState { initializing, initialized, initial }

class ElythraPlayerCubit extends Cubit<ElythraPlayerState> {
  late ElythraMusicPlayer elythraPlayer;
  PlayerInitState playerInitState = PlayerInitState.initial;
  // late AudioSession audioSession;
  late Stream<ProgressBarStreams> progressStreams;
  
  // Legacy getter for compatibility
  ElythraMusicPlayer get bloomeePlayer => elythraPlayer;
  
  ElythraPlayerCubit() : super(ElythraPlayerInitial()) {
    setupPlayer().then((value) => emit(ElythraPlayerState(isReady: true)));
  }

  void switchShowLyrics({bool? value}) {
    emit(ElythraPlayerState(
        isReady: true, showLyrics: value ?? !state.showLyrics));
  }

  Future<void> setupPlayer() async {
    playerInitState = PlayerInitState.initializing;
    elythraPlayer = await PlayerInitializer().getElythraMusicPlayer();
    playerInitState = PlayerInitState.initialized;
    progressStreams = Rx.defer(
      () => Rx.combineLatest3(
          elythraPlayer.audioPlayer.positionStream,
          elythraPlayer.audioPlayer.playbackEventStream,
          elythraPlayer.audioPlayer.playerStateStream,
          (Duration a, PlaybackEvent b, PlayerState c) => ProgressBarStreams(
              currentPos: a, currentPlaybackState: b, currentPlayerState: c)),
      reusable: true,
    );
  }

  @override
  Future<void> close() {
    // EasyDebounce.cancelAll();
    elythraPlayer.stop();
    elythraPlayer.audioPlayer.dispose();
    return super.close();
  }
}

class ProgressBarStreams {
  final Duration currentPos;
  final PlaybackEvent currentPlaybackState;
  final PlayerState currentPlayerState;

  ProgressBarStreams({
    required this.currentPos,
    required this.currentPlaybackState,
    required this.currentPlayerState,
  });
}