import 'package:elythra_music/core/model/playlist_onl_model.dart';
import 'package:elythra_music/core/model/saavn_model.dart';
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/core/model/source_engines.dart';
import 'package:elythra_music/core/model/youtube_vid_model.dart';
import 'package:elythra_music/core/model/yt_music_model.dart';
import 'package:elythra_music/core/repository/Saavn/saavn_api.dart';
import 'package:elythra_music/core/repository/Youtube/youtube_api.dart';
import 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'online_playlist_state.dart';

class OnlPlaylistCubit extends Cubit<OnlPlaylistState> {
  PlaylistOnlModel playlist;
  SourceEngine sourceEngine;
  OnlPlaylistCubit({
    required this.playlist,
    required this.sourceEngine,
  }) : super(OnlPlaylistInitial()) {
    emit(OnlPlaylistLoading(playlist: playlist));
    checkIsSaved();
    switch (sourceEngine) {
      case SourceEngine.eng_JIS:
        SaavnAPI()
            .fetchPlaylistDetails(
                Uri.parse(playlist.sourceURL).pathSegments.last)
            .then((value) {
          final plst = PlaylistOnlModel(
            name: value['playlistDetails']['album'],
            imageURL: value['playlistDetails']['image'],
            source: 'saavn',
            sourceId: value['playlistDetails']['id'],
            sourceURL: value['playlistDetails']['perma_url'],
            description: value['playlistDetails']['subtitle'],
            artists: value['playlistDetails']['artist'] ?? 'Various Artists',
            language: value['playlistDetails']['language'],
          );
          final songs = fromSaavnSongMapList2MediaItemList(value['songs']);
          emit(OnlPlaylistLoaded(
            playlist: playlist.copyWith(
              name: plst.name,
              imageURL: plst.imageURL,
              source: plst.source,
              sourceId: plst.sourceId,
              sourceURL: plst.sourceURL,
              description: plst.description,
              artists: plst.artists,
              songs: List<MediaItemModel>.from(songs),
            ),
            isSavedCollection: state.isSavedCollection,
          ));
        });
        break;
      case SourceEngine.eng_YTM:
        YTMusic()
            .getPlaylistFull(playlist.sourceId.replaceAll("youtubeVL", ""))
            .then(
          (value) {
            if (value != null && value['songs'] != null) {
              final songs = ytmMapList2MediaItemList(value['songs']);
              emit(OnlPlaylistLoaded(
                playlist: playlist.copyWith(
                  songs: List<MediaItemModel>.from(songs),
                ),
                isSavedCollection: state.isSavedCollection,
              ));
            }
          },
        );
        break;
      case SourceEngine.eng_YTV:
        YouTubeServices().fetchPlaylistItems(playlist.sourceId).then((value) {
          final songs = fromYtVidSongMapList2MediaItemList(value[0]['items']);
          emit(OnlPlaylistLoaded(
            playlist: playlist.copyWith(
              songs: List<MediaItemModel>.from(songs),
              artists: value[0]['metadata'].author,
            ),
            isSavedCollection: state.isSavedCollection,
          ));
        });
        break;
    }
  }

  Future<void> checkIsSaved() async {
    bool isSaved =
        await ElythraDBService.isInSavedCollections(playlist.sourceId);
    if (state.isSavedCollection != isSaved) {
      emit(
        state.copyWith(isSavedCollection: isSaved),
      );
    }
  }

  Future<void> addToSavedCollections() async {
    if (!state.isSavedCollection) {
      await ElythraDBService.putOnlPlaylistModel(playlist);
      SnackbarService.showMessage("Artist added to Library!");
    } else {
      await ElythraDBService.removeFromSavedCollecs(playlist.sourceId);
      SnackbarService.showMessage("Artist removed from Library!");
    }
    checkIsSaved();
  }
}
