import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elythra_music/core/blocs/mediaPlayer/elythra_player_cubit.dart';
import 'package:elythra_music/core/model/lyrics_models.dart' as lyrics_models;
import 'package:elythra_music/core/model/song_model.dart';

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

// Lyrics state classes
abstract class LyricsState {
  // Default implementations for compatibility
  LyricsModel get lyrics => const LyricsModel(lyricsPlain: '');
  ElythraMediaItem get mediaItem => const ElythraMediaItem(id: '', title: '', artist: '');
}

class LyricsInitial extends LyricsState {}

class LyricsLoading extends LyricsState {}

class LyricsLoaded extends LyricsState {
  final LyricsModel _lyrics;
  final ElythraMediaItem _mediaItem;
  
  LyricsLoaded({
    required LyricsModel lyrics,
    required ElythraMediaItem mediaItem,
  }) : _lyrics = lyrics, _mediaItem = mediaItem;
  
  @override
  LyricsModel get lyrics => _lyrics;
  
  @override
  ElythraMediaItem get mediaItem => _mediaItem;
}

class LyricsError extends LyricsState {
  final String message;
  
  LyricsError(this.message);
}

// Legacy state class for compatibility
class LyricsStateCompat {
  final bool isLoading;
  final String? error;
  final LyricsModel lyrics;
  final ElythraMediaItem mediaItem;
  
  const LyricsStateCompat({
    this.isLoading = false,
    this.error,
    required this.lyrics,
    required this.mediaItem,
  });
  
  // Factory constructor for initial state
  factory LyricsStateCompat.initial() {
    return LyricsStateCompat(
      lyrics: const LyricsModel(lyricsPlain: ''),
      mediaItem: const ElythraMediaItem(
        id: '',
        title: '',
        artist: '',
      ),
    );
  }
  
  // Copy with method for state updates - removed as we use proper state classes now
}

// Lyrics Cubit
class LyricsCubit extends Cubit<LyricsState> {
  final ElythraPlayerCubit? playerCubit;

  LyricsCubit([this.playerCubit]) : super(LyricsInitial()) {
    // Listen to player state changes if playerCubit is provided
    playerCubit?.stream.listen((playerState) {
      if (playerState is ElythraPlayerReady) {
        final mediaItem = playerCubit!.bloomeePlayer.currentMedia;
        if (mediaItem != null) {
          updateElythraMediaItem(mediaItem);
          fetchLyrics(mediaItem.title, mediaItem.artist ?? 'Unknown Artist');
        }
      }
    });
  }

  void updateElythraMediaItem(MediaItemModel mediaItem) {
    // For now, just emit loading state
    emit(LyricsLoading());
  }

  Future<void> fetchLyrics(String title, String artist) async {
    emit(LyricsLoading());
    
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
      
      final mediaItem = ElythraMediaItem(
        id: '$title-$artist',
        title: title,
        artist: artist,
      );
      
      emit(LyricsLoaded(
        lyrics: lyricsModel,
        mediaItem: mediaItem,
      ));
    } catch (e) {
      emit(LyricsError("Failed to fetch lyrics: $e"));
    }
  }

  void searchLyrics(String query) {
    emit(LyricsLoading());
    // Implement lyrics search
    fetchLyrics("Search Result", query);
  }

  void setCustomLyrics(String lyrics) {
    final lyricsModel = LyricsModel(
      lyricsPlain: lyrics,
      parsedLyrics: null, // No sync for custom lyrics
    );
    
    final mediaItem = ElythraMediaItem(
      id: 'custom',
      title: 'Custom Lyrics',
      artist: 'User',
    );
    
    emit(LyricsLoaded(
      lyrics: lyricsModel,
      mediaItem: mediaItem,
    ));
  }

  // Methods expected by the UI
  Future<void> setLyricsToDB(lyrics_models.Lyrics lyrics, String mediaId) async {
    // Implementation for saving lyrics to database
    try {
      // Convert to LyricsModel and save
      final lyricsModel = LyricsModel(
        lyricsPlain: lyrics.lyricsPlain,
        parsedLyrics: ParsedLyrics(lyrics: []), // Convert if needed
      );
      
      final mediaItem = ElythraMediaItem(
        id: mediaId,
        title: 'Saved Lyrics',
        artist: 'Unknown',
      );
      
      // Save to local database
      // print('Saving lyrics for media ID: $mediaId');
      emit(LyricsLoaded(lyrics: lyricsModel, mediaItem: mediaItem));
      // Implementation would go here
    } catch (e) {
      emit(LyricsError("Failed to save lyrics: $e"));
    }
  }

  Future<void> deleteLyricsFromDB(ElythraMediaItem mediaItem) async {
    // Implementation for deleting lyrics from database
    try {
      // Delete from local database
      // print('Deleting lyrics for media ID: ${mediaItem.id}');
      // Implementation would go here
      
      // Reset lyrics state
      emit(LyricsInitial());
    } catch (e) {
      emit(LyricsError("Failed to delete lyrics: $e"));
    }
  }
}