import 'dart:async';
import 'dart:developer';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart' show ElythraPlayerCubit, ElythraMediaItem;
import 'package:elythra_music/core/model/lyrics_models.dart';
import 'package:elythra_music/core/model/songModel.dart';
import 'package:elythra_music/features/lyrics/repository/lyrics.dart';
import 'package:elythra_music/core/routes_and_consts/global_conts.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'lyrics_state.dart';

class LyricsCubit extends Cubit<LyricsState> {
  StreamSubscription? _mediaItemSubscription;
  LyricsCubit(ElythraPlayerCubit playerCubit) : super(LyricsInitial()) {
    _mediaItemSubscription =
        playerCubit.bloomeePlayer.mediaItem.listen((v) {
      if (v != null) {
        getLyrics(_convertToMediaItemModel(v));
      }
    });
  }

  MediaItemModel _convertToMediaItemModel(ElythraMediaItem mediaItem) {
    return MediaItemModel(
      id: mediaItem.id,
      title: mediaItem.title,
      album: mediaItem.album,
      artUri: mediaItem.artUri != null ? Uri.parse(mediaItem.artUri!) : null,
      artist: mediaItem.artist,
      extras: mediaItem.extras,
      duration: mediaItem.duration,
    );
  }

  void getLyrics(MediaItemModel mediaItem) async {
    if (state.mediaItem == mediaItem && state is LyricsLoaded) {
      return;
    } else {
      emit(LyricsLoading(mediaItem));
      Lyrics? lyrics = await ElythraDBService.getLyrics(mediaItem.id);
      if (lyrics == null) {
        try {
          lyrics = await LyricsRepository.getLyrics(
              mediaItem.title, mediaItem.artist ?? "",
              album: mediaItem.album, duration: mediaItem.duration);
          if (lyrics.lyricsSynced == "No Lyrics Found") {
            lyrics = lyrics.copyWith(lyricsSynced: null);
          }
          lyrics = lyrics.copyWith(mediaID: mediaItem.id);
          emit(LyricsLoaded(lyrics, mediaItem));
          ElythraDBService.getSettingBool(GlobalStrConsts.autoSaveLyrics)
              .then((value) {
            if ((value ?? false) && lyrics != null) {
              ElythraDBService.putLyrics(lyrics);
              log("Lyrics saved for ID: ${mediaItem.id} Duration: ${lyrics.duration}",
                  name: "LyricsCubit");
            }
          });
          log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} [Online]",
              name: "LyricsCubit");
        } catch (e) {
          emit(LyricsError(mediaItem));
        }
      } else if (lyrics.mediaID == mediaItem.id) {
        emit(LyricsLoaded(lyrics, mediaItem));
        log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} [Offline]",
            name: "LyricsCubit");
      }
    }
  }

  void setLyricsToDB(Lyrics lyrics, String mediaID) {
    final l1 = lyrics.copyWith(mediaID: mediaID);
    ElythraDBService.putLyrics(l1).then((v) {
      emit(LyricsLoaded(l1, state.mediaItem));
    });
    log("Lyrics updated for ID: ${l1.mediaID} Duration: ${l1.duration}",
        name: "LyricsCubit");
  }

  void deleteLyricsFromDB(MediaItemModel mediaItem) {
    ElythraDBService.removeLyricsById(mediaItem.id).then((value) {
      emit(LyricsInitial());
      getLyrics(mediaItem);

      log("Lyrics deleted for ID: ${mediaItem.id}", name: "LyricsCubit");
    });
  }

  @override
  Future<void> close() {
    _mediaItemSubscription?.cancel();
    return super.close();
  }
}
