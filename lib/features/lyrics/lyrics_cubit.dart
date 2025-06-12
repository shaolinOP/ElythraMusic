import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:elythra_music/core/model/lyrics_models.dart' as lyrics_models;

// Lyric Line Model with Duration for start time
class LyricLine {
  final Duration start;
  final String text;

  LyricLine({required this.start, required this.text});
  
  // Legacy constructor for timestamp in milliseconds
  LyricLine.fromTimestamp({required int timestamp, required this.text}) 
    : start = Duration(milliseconds: timestamp);
}

// Lyrics model classes
class LyricsModel {
  final String lyricsPlain;
  final ParsedLyrics? parsedLyrics;
  
  const LyricsModel({
    required this.lyricsPlain,
    this.parsedLyrics,
  });
}

class ParsedLyrics {
  final List<LyricLine> lyrics;
  
  const ParsedLyrics({required this.lyrics});
}

// Lyrics state
class LyricsState {
  final bool isLoading;
  final String? error;
  final LyricsModel lyrics;
  final MediaItem mediaItem;
  
  const LyricsState({
    this.isLoading = false,
    this.error,
    required this.lyrics,
    required this.mediaItem,
  });
  
  // Factory constructor for initial state
  factory LyricsState.initial() {
    return LyricsState(
      lyrics: const LyricsModel(lyricsPlain: ''),
      mediaItem: const MediaItem(
        id: '',
        title: '',
        artist: '',
      ),
    );
  }
  
  // Copy with method for state updates
  LyricsState copyWith({
    bool? isLoading,
    String? error,
    LyricsModel? lyrics,
    MediaItem? mediaItem,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lyrics: lyrics ?? this.lyrics,
      mediaItem: mediaItem ?? this.mediaItem,
    );
  }
}

// Lyrics Cubit
class LyricsCubit extends Cubit<LyricsState> {
  final ElythraPlayerCubit? playerCubit;

  LyricsCubit([this.playerCubit]) : super(LyricsState.initial()) {
    // Listen to player state changes if playerCubit is provided
    playerCubit?.stream.listen((playerState) {
      if (playerState is ElythraPlayerPlaying || playerState is ElythraPlayerPaused) {
        final mediaItem = playerCubit!.currentMedia;
        if (mediaItem != null) {
          updateMediaItem(mediaItem);
          fetchLyrics(mediaItem.title, mediaItem.artist);
        }
      }
    });
  }

  void updateMediaItem(MediaItem mediaItem) {
    emit(state.copyWith(mediaItem: mediaItem));
  }

  Future<void> fetchLyrics(String title, String artist) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // This would integrate with the enhanced lyrics service
      // For now, emit a placeholder
      await Future.delayed(const Duration(seconds: 1));
      
      final lyricsText = "Lyrics for $title by $artist\n\nLyrics will be fetched from multiple sources:\n- LRCLib\n- Genius\n- Musixmatch\n- AZLyrics";
      
      // Create sample synced lyrics
      final syncedLyrics = [
        LyricLine(start: const Duration(seconds: 0), text: "Verse 1: $title"),
        LyricLine(start: const Duration(seconds: 10), text: "By $artist"),
        LyricLine(start: const Duration(seconds: 20), text: "Chorus coming up..."),
        LyricLine(start: const Duration(seconds: 30), text: "This is the chorus"),
      ];
      
      final lyricsModel = LyricsModel(
        lyricsPlain: lyricsText,
        parsedLyrics: ParsedLyrics(lyrics: syncedLyrics),
      );
      
      emit(state.copyWith(
        isLoading: false,
        lyrics: lyricsModel,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: "Failed to fetch lyrics: $e",
      ));
    }
  }

  void searchLyrics(String query) {
    emit(state.copyWith(isLoading: true, error: null));
    // Implement lyrics search
    fetchLyrics("Search Result", query);
  }

  void setCustomLyrics(String lyrics) {
    final lyricsModel = LyricsModel(
      lyricsPlain: lyrics,
      parsedLyrics: null, // No sync for custom lyrics
    );
    
    emit(state.copyWith(
      isLoading: false,
      lyrics: lyricsModel,
      error: null,
    ));
  }

  // Methods expected by the UI
  Future<void> setLyricsToDB(lyrics_models.Lyrics lyrics, String mediaId) async {
    // Implementation for saving lyrics to database
    try {
      // Convert to LyricsModel and save
      final lyricsModel = LyricsModel(
        lyricsPlain: lyrics.lyricsPlain,
        parsedLyrics: lyrics.parsedLyrics,
      );
      
      // Save to local database
      print('Saving lyrics for media ID: $mediaId');
      emit(state.copyWith(lyrics: lyricsModel));
      // Implementation would go here
    } catch (e) {
      emit(state.copyWith(error: "Failed to save lyrics: $e"));
    }
  }

  Future<void> deleteLyricsFromDB(MediaItem mediaItem) async {
    // Implementation for deleting lyrics from database
    try {
      // Delete from local database
      print('Deleting lyrics for media ID: ${mediaItem.id}');
      // Implementation would go here
      
      // Reset lyrics state
      emit(state.copyWith(
        lyrics: const LyricsModel(lyricsPlain: ''),
      ));
    } catch (e) {
      emit(state.copyWith(error: "Failed to delete lyrics: $e"));
    }
  }
}