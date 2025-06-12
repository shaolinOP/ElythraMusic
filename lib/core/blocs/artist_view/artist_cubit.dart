import 'package:elythra_music/core/model/album_onl_model.dart';
import 'package:elythra_music/core/model/artist_onl_model.dart';
import 'package:elythra_music/core/model/saavn_model.dart';
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/core/model/source_engines.dart';
import 'package:elythra_music/core/model/yt_music_model.dart';
import 'package:elythra_music/core/repository/Saavn/saavn_api.dart';
import 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'artist_state.dart';

class ArtistCubit extends Cubit<ArtistState> {
  final ArtistModel artist;
  final SourceEngine sourceEngine;
  ArtistCubit({
    required this.artist,
    required this.sourceEngine,
  }) : super(ArtistInitial()) {
    emit(ArtistLoading(artist: artist));
    checkIsSaved();
    switch (sourceEngine) {
      case SourceEngine.engJis:
        SaavnAPI()
            .fetchArtistDetails(Uri.parse(artist.sourceURL).pathSegments.last)
            .then((value) {
          final songs = fromSaavnSongMapList2MediaItemList(value['songs']);
          final albums = saavnMap2Albums({'Albums': value['albums']});
          emit(ArtistLoaded(
            artist: artist.copyWith(
              songs: List<MediaItemModel>.from(songs),
              description: value['subtitle'] ?? artist.description,
              albums: List<AlbumModel>.from(albums),
            ),
            isSavedCollection: state.isSavedCollection,
          ));
        });
        break;
      case SourceEngine.engYtm:
        YTMusic().getArtistFull(artist.sourceId).then((value) {
          List<AlbumModel> albums = [];
          if (value != null && value['albums'] != null) {
            albums = ytmMap2Albums(value['albums']);
            emit(
              ArtistLoaded(
                artist: artist.copyWith(
                  albums: List<AlbumModel>.from(albums),
                ),
                isSavedCollection: state.isSavedCollection,
              ),
            );
          }
          if (value != null && value['songs'] != null) {
            final songsFull = ytmMapList2MediaItemList(value['songs']);
            emit(
              ArtistLoaded(
                artist: artist.copyWith(
                  songs: List<MediaItemModel>.from(songsFull),
                  albums: List<AlbumModel>.from(albums),
                ),
                isSavedCollection: state.isSavedCollection,
              ),
            );
          }
        });
        break;
      case SourceEngine.engYtv:
      // TODO: Handle this case.
    }
  }
  Future<void> checkIsSaved() async {
    bool isSaved = await ElythraDBService.isInSavedCollections(artist.sourceId);
    if (state.isSavedCollection != isSaved) {
      emit(
        state.copyWith(isSavedCollection: isSaved),
      );
    }
  }

  Future<void> addToSavedCollections() async {
    if (!state.isSavedCollection) {
      await ElythraDBService.putOnlArtistModel(artist);
      SnackbarService.showMessage("Artist added to Library!");
    } else {
      await ElythraDBService.removeFromSavedCollecs(artist.sourceId);
      SnackbarService.showMessage("Artist removed from Library!");
    }
    checkIsSaved();
  }
}
