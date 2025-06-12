// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:elythra_music/core/services/db/global_db.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';

class MediaItemModel extends MediaItem {

  MediaItemModel({
    required String id,
    required String title,
    String? album,
    Uri? artUri,
    String? artist,
    Map<String, dynamic>? extras,
    String? genre,
    Duration? duration,
  }) : super(
            id: id,
            title: title,
            album: album,
            artUri: artUri,
            artist: artist,
            extras: extras,
            genre: genre,
            duration: duration);

  @override
  bool operator ==(covariant MediaItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.album == album &&
        other.artUri == artUri &&
        other.artist == artist &&
        mapEquals(other.extras, extras) &&
        other.genre == genre;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        album.hashCode ^
        artUri.hashCode ^
        artist.hashCode ^
        extras.hashCode ^
        genre.hashCode;
  }
}

MediaItemModel mediaItem2MediaItemModel(MediaItem mediaItem) {
  return MediaItemModel(
    id: mediaItem.id,
    title: mediaItem.title,
    album: mediaItem.album,
    artUri: mediaItem.artUri,
    artist: mediaItem.artist,
    extras: mediaItem.extras,
    genre: mediaItem.genre,
    duration: mediaItem.duration,
  );
}

MediaItemDB mediaItem2MediaItemDB(MediaItem mediaItem) {
  return MediaItemDB(
      title: mediaItem.title,
      album: mediaItem.album ?? "Unknown",
      artist: mediaItem.artist ?? "Unknown",
      artURL: mediaItem.artUri.toString(),
      genre: mediaItem.genre ?? "Unknown",
      mediaID: mediaItem.id,
      duration: mediaItem.duration?.inSeconds,
      streamingURL: mediaItem.extras?["url"],
      permaURL: mediaItem.extras?["perma_url"],
      language: mediaItem.extras?["language"] ?? "Unknown",
      isLiked: false,
      source: mediaItem.extras?["source"] ?? "Saavn");
}

MediaItemModel mediaItemDB2MediaItem(MediaItemDB mediaItemDB) {
  return MediaItemModel(
      id: mediaItemDB.mediaID,
      title: mediaItemDB.title,
      album: mediaItemDB.album,
      artist: mediaItemDB.artist,
      duration: mediaItemDB.duration != null
          ? Duration(seconds: mediaItemDB.duration!)
          : const Duration(seconds: 120),
      artUri: Uri.parse(mediaItemDB.artURL),
      genre: mediaItemDB.genre,
      extras: {
        "url": mediaItemDB.streamingURL,
        "source": mediaItemDB.source ?? "None",
        "perma_url": mediaItemDB.permaURL,
        "language": mediaItemDB.language,
      });
}

MediaItemModel elythraMediaItem2MediaItemModel(ElythraMediaItem elythraMediaItem) {
  return MediaItemModel(
    id: elythraMediaItem.id,
    title: elythraMediaItem.title,
    album: elythraMediaItem.album,
    artUri: elythraMediaItem.artUri != null ? Uri.parse(elythraMediaItem.artUri!) : null,
    artist: elythraMediaItem.artist,
    extras: elythraMediaItem.extras,
    duration: elythraMediaItem.duration,
  );
}
