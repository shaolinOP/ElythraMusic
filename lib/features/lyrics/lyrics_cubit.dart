import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';

// Lyrics States
abstract class LyricsState {}

class LyricsInitial extends LyricsState {}

class LyricsLoading extends LyricsState {}

class LyricsLoaded extends LyricsState {
  final String lyrics;
  final List<LyricLine>? syncedLyrics;
  final String source;

  LyricsLoaded({
    required this.lyrics,
    this.syncedLyrics,
    required this.source,
  });
}

class LyricsError extends LyricsState {
  final String message;
  LyricsError(this.message);
}

// Lyric Line Model
class LyricLine {
  final int timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});
}

// Lyrics Cubit
class LyricsCubit extends Cubit<LyricsState> {
  final ElythraPlayerCubit playerCubit;

  LyricsCubit(this.playerCubit) : super(LyricsInitial()) {
    // Listen to player state changes
    playerCubit.stream.listen((playerState) {
      if (playerState.currentMedia != null) {
        fetchLyrics(
          playerState.currentMedia!.title ?? '',
          playerState.currentMedia!.artist ?? '',
        );
      }
    });
  }

  Future<void> fetchLyrics(String title, String artist) async {
    emit(LyricsLoading());
    
    try {
      // This would integrate with the enhanced lyrics service
      // For now, emit a placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      emit(LyricsLoaded(
        lyrics: "Lyrics for $title by $artist\n\nLyrics will be fetched from multiple sources:\n- LRCLib\n- Genius\n- Musixmatch\n- AZLyrics",
        source: "Enhanced Lyrics Service",
      ));
    } catch (e) {
      emit(LyricsError("Failed to fetch lyrics: $e"));
    }
  }

  void searchLyrics(String query) {
    emit(LyricsLoading());
    // Implement lyrics search
  }

  void setCustomLyrics(String lyrics) {
    emit(LyricsLoaded(
      lyrics: lyrics,
      source: "Custom",
    ));
  }
}