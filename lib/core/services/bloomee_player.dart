import 'dart:developer';
import 'dart:io';
import 'package:elythra_music/core/model/saavn_model.dart';
import 'package:elythra_music/core/model/yt_music_model.dart';
import 'package:elythra_music/core/repository/Saavn/saavn_api.dart';
import 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart';
import 'package:elythra_music/core/routes_and_consts/global_conts.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:elythra_music/core/utils/ytstream_source.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:elythra_music/core/model/song_model.dart';
import '../model/media_playlist_model.dart';
import 'package:elythra_music/core/services/discord_service.dart';

List<int> generateRandomIndices(int length) {
  List<int> indices = List<int>.generate(length, (i) => i);
  indices.shuffle();
  return indices;
}

class ElythraMusicPlayer extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  late AudioPlayer audioPlayer;
  BehaviorSubject<bool> fromPlaylist = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> isOffline = BehaviorSubject<bool>.seeded(false);
  // BehaviorSubject<bool> isLinkProcessing = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> shuffleMode = BehaviorSubject<bool>.seeded(false);

  BehaviorSubject<List<MediaItem>> relatedSongs =
      BehaviorSubject<List<MediaItem>>.seeded([]);
  BehaviorSubject<LoopMode> loopMode =
      BehaviorSubject<LoopMode>.seeded(LoopMode.off);
  int currentPlayingIdx = 0;
  int shuffleIdx = 0;
  List<int> shuffleList = [];
  final _playlist = ConcatenatingAudioSource(children: []);

  // final ReceivePort receivePortYt = ReceivePort();
  // SendPort? sendPortYt;

  ElythraMusicPlayer() {
    // initBgYt();
    audioPlayer = AudioPlayer(
      handleInterruptions: true,
    );
    audioPlayer.setVolume(1);
    audioPlayer.playbackEventStream.listen(_broadcastPlayerEvent);
    audioPlayer.setLoopMode(LoopMode.off);
    audioPlayer.setAudioSource(_playlist, preload: false);

    // Update the current media item when the audio player changes to the next
    Rx.combineLatest2(
      audioPlayer.sequenceStream,
      audioPlayer.currentIndexStream,
      (sequence, index) {
        if (sequence == null || sequence.isEmpty) return null;
        return sequence[index ?? 0].tag as MediaItem;
      },
    ).whereType<MediaItem>().listen(mediaItem.add);

    // Trigger skipToNext when the current song ends.
    final endingOffset =
        Platform.isWindows ? 200 : (Platform.isLinux ? 700 : 200);
    audioPlayer.positionStream.listen((event) {
      //check if the current queue is empty and if it is, add related songs
      EasyThrottle.throttle('loadRelatedSongs', const Duration(seconds: 5),
          () async => check4RelatedSongs());
      if (((audioPlayer.duration != null &&
              audioPlayer.duration?.inSeconds != 0 &&
              event.inMilliseconds >
                  audioPlayer.duration!.inMilliseconds - endingOffset)) &&
          loopMode.toARGB32 != LoopMode.one) {
        EasyThrottle.throttle('skipNext', const Duration(milliseconds: 2000),
            () async => await skipToNext());
      }
    });

    // Refresh shuffle list when queue changes
    queue.listen((e) {
      shuffleList = generateRandomIndices(e.length);
    });
  }

  void _broadcastPlayerEvent(PlaybackEvent event) {
    bool isPlaying = audioPlayer.playing;
    playbackState.add(PlaybackState(
      // Which buttons should appear in the notification now
      controls: [
        MediaControl.skipToPrevious,
        isPlaying ? MediaControl.pause : MediaControl.play,
        // MediaControl.stop,
        MediaControl.skipToNext,
      ],
      processingState: switch (event.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      // Which other actions should be enabled in the notification
      systemActions: const {
        MediaAction.skipToPrevious,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      updatePosition: audioPlayer.position,
      playing: isPlaying,
      bufferedPosition: audioPlayer.bufferedPosition,
      speed: audioPlayer.speed,
    ));

    DiscordService.updatePresence(
      mediaItem: currentMedia,
      isPlaying: isPlaying,
    );
  }

  MediaItemModel get currentMedia => queue.toARGB32.isNotEmpty
      ? mediaItem2MediaItemModel(queue.toARGB32[currentPlayingIdx])
      : mediaItemModelNull;

  @override
  Future<void> play() async {
    await audioPlayer.play();
  }

  Future<void> check4RelatedSongs() async {
    log("Checking for related songs: ${queue.toARGB32.isNotEmpty && (queue.toARGB32.length - currentPlayingIdx) < 2}",
        name: "bloomeePlayer");
    final autoPlay =
        await ElythraDBService.getSettingBool(GlobalStrConsts.autoPlay);
    if (autoPlay != null && !autoPlay) return;
    if (queue.toARGB32.isNotEmpty &&
        (queue.toARGB32.length - currentPlayingIdx) < 2 &&
        loopMode.toARGB32 != LoopMode.all) {
      if (currentMedia.extras?["source"] == "saavn") {
        final songs = await compute(SaavnAPI().getRelated, currentMedia.id);
        if (songs['total'] > 0) {
          final List<MediaItem> temp =
              fromSaavnSongMapList2MediaItemList(songs['songs']);
          relatedSongs.add(temp.sublist(1));
          log("Related Songs: ${songs['total']}");
        }
      } else if (currentMedia.extras?["source"].contains("youtube") ?? false) {
        final songs = await YTMusic()
            .getRelatedSongs(currentMedia.id.replaceAll('youtube', ''));
        if (songs.isNotEmpty) {
          final List<MediaItem> temp = ytmMapList2MediaItemList(songs);
          relatedSongs.add(temp.sublist(1));
          log("Related Songs: ${songs.length}");
        }
      }
    }
    loadRelatedSongs();
  }

  Future<void> loadRelatedSongs() async {
    if (relatedSongs.toARGB32.isNotEmpty &&
        (queue.toARGB32.length - currentPlayingIdx) < 3 &&
        loopMode.toARGB32 != LoopMode.all) {
      await addQueueItems(relatedSongs.toARGB32, atLast: true);
      fromPlaylist.add(false);
      relatedSongs.add([]);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    audioPlayer.seek(position);
  }

  Future<void> seekNSecForward(Duration n) async {
    if ((audioPlayer.duration ?? const Duration(seconds: 0)) >=
        audioPlayer.position + n) {
      await audioPlayer.seek(audioPlayer.position + n);
    } else {
      await audioPlayer
          .seek(audioPlayer.duration ?? const Duration(seconds: 0));
    }
  }

  Future<void> seekNSecBackward(Duration n) async {
    if (audioPlayer.position - n >= const Duration(seconds: 0)) {
      await audioPlayer.seek(audioPlayer.position - n);
    } else {
      await audioPlayer.seek(const Duration(seconds: 0));
    }
  }

  void setLoopMode(LoopMode loopMode) {
    if (loopMode == LoopMode.one) {
      audioPlayer.setLoopMode(LoopMode.one);
    } else {
      audioPlayer.setLoopMode(LoopMode.off);
    }
    this.loopMode.add(loopMode);
  }

  Future<void> shuffle(bool shuffle) async {
    shuffleMode.add(shuffle);
    if (shuffle) {
      shuffleIdx = 0;
      shuffleList = generateRandomIndices(queue.toARGB32.length);
    }
  }

  Future<void> loadPlaylist(MediaPlaylist mediaList,
      {int idx = 0, bool doPlay = false, bool shuffling = false}) async {
    fromPlaylist.add(true);
    queue.add([]);
    relatedSongs.add([]);
    queue.add(mediaList.mediaItems);
    queueTitle.add(mediaList.playlistName);
    shuffle(shuffling || shuffleMode.toARGB32);
    await prepare4play(idx: idx, doPlay: doPlay);
    // if (doPlay) play();
  }

  @override
  Future<void> pause() async {
    await audioPlayer.pause();
    log("paused", name: "bloomeePlayer");
  }

  Future<AudioSource> getAudioSource(MediaItem mediaItem) async {
    final _down = await ElythraDBService.getDownloadDB(
        mediaItem2MediaItemModel(mediaItem));
    if (_down != null) {
      log("Playing Offline", name: "bloomeePlayer");
      SnackbarService.showMessage("Playing Offline",
          duration: const Duration(seconds: 1));
      isOffline.add(true);
      return AudioSource.uri(Uri.file('${_down.filePath}/${_down.fileName}'),
          tag: mediaItem);
    } else {
      isOffline.add(false);
      if (mediaItem.extras?["source"] == "youtube") {
        String? quality =
            await ElythraDBService.getSettingStr(GlobalStrConsts.ytStrmQuality);
        quality = quality ?? "high";
        quality = quality.toLowerCase();
        final id = mediaItem.id.replaceAll("youtube", '');
        return YouTubeAudioSource(
            videoId: id, quality: quality, tag: mediaItem);
      }
      String? kurl = await getJsQualityURL(mediaItem.extras?["url"]);
      log('Playing: $kurl', name: "bloomeePlayer");
      return AudioSource.uri(Uri.parse(kurl!), tag: mediaItem);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < queue.toARGB32.length) {
      currentPlayingIdx = index;
      await playMediaItem(queue.toARGB32[index]);
    } else {
      // await loadRelatedSongs();
      if (index < queue.toARGB32.length) {
        currentPlayingIdx = index;
        await playMediaItem(queue.toARGB32[index]);
      }
    }

    log("skipToQueueItem", name: "bloomeePlayer");
    return super.skipToQueueItem(index);
  }

  Future<void> playAudioSource({
    required AudioSource audioSource,
    required String mediaId,
  }) async {
    await pause();
    await seek(Duration.zero);
    try {
      if (_playlist.children.isNotEmpty) {
        await _playlist.clear();
      }
      await _playlist.add(audioSource);
      await audioPlayer.load();
      if (!audioPlayer.playing) await play();
    } catch (e) {
      log("Error: $e", name: "bloomeePlayer");
      if (e is PlayerException) {
        SnackbarService.showMessage("Failed to play song: $e");
        await stop();
      }
    }
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem, {bool doPlay = true}) async {
    final audioSource = await getAudioSource(mediaItem);
    await playAudioSource(audioSource: audioSource, mediaId: mediaItem.id);
    await check4RelatedSongs();
  }

  Future<void> prepare4play({int idx = 0, bool doPlay = false}) async {
    if (queue.toARGB32.isNotEmpty) {
      currentPlayingIdx = idx;
      await playMediaItem(currentMedia, doPlay: doPlay);
      ElythraDBService.putRecentlyPlayed(mediaItem2MediaItemDB(currentMedia));
    }
  }

  @override
  Future<void> rewind() async {
    if (audioPlayer.processingState == ProcessingState.ready) {
      await audioPlayer.seek(Duration.zero);
    } else if (audioPlayer.processingState == ProcessingState.completed) {
      await prepare4play(idx: currentPlayingIdx);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (!shuffleMode.toARGB32) {
      if (currentPlayingIdx < (queue.toARGB32.length - 1)) {
        currentPlayingIdx++;
        prepare4play(idx: currentPlayingIdx, doPlay: true);
      } else if (loopMode.toARGB32 == LoopMode.all) {
        currentPlayingIdx = 0;
        prepare4play(idx: currentPlayingIdx, doPlay: true);
      }
    } else {
      if (shuffleIdx < (queue.toARGB32.length - 1)) {
        shuffleIdx++;
        prepare4play(idx: shuffleList[shuffleIdx], doPlay: true);
      } else if (loopMode.toARGB32 == LoopMode.all) {
        shuffleIdx = 0;
        prepare4play(idx: shuffleList[shuffleIdx], doPlay: true);
      }
    }
  }

  @override
  Future<void> stop() async {
    // log("Called Stop!!");
    audioPlayer.stop();
    DiscordService.clearPresence();
    super.stop();
  }

  @override
  Future<void> skipToPrevious() async {
    if (!shuffleMode.toARGB32) {
      if (currentPlayingIdx > 0) {
        currentPlayingIdx--;
        prepare4play(idx: currentPlayingIdx, doPlay: true);
      }
    } else {
      if (shuffleIdx > 0) {
        shuffleIdx--;
        prepare4play(idx: shuffleList[shuffleIdx], doPlay: true);
      }
    }
  }

  @override
  Future<void> onTaskRemoved() {
    DiscordService.clearPresence();
    super.stop();
    audioPlayer.dispose();
    return super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() {
    DiscordService.clearPresence();
    audioPlayer.stop();
    audioPlayer.dispose();
    super.stop();
    return super.onNotificationDeleted();
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    List<MediaItem> temp = queue.toARGB32;
    if (index < queue.toARGB32.length) {
      temp.insert(index, mediaItem);
    } else {
      temp.add(mediaItem);
    }
    queue.add(temp);

    // Adjust the currentPlayingIdx
    if (currentPlayingIdx >= index) {
      currentPlayingIdx++;
    }
  }

  @override
  Future<void> addQueueItem(
    MediaItem mediaItem,
  ) async {
    if (queue.toARGB32.any((e) => e.id == mediaItem.id)) return;
    queueTitle.add("Queue");
    queue.add(queue.toARGB32..add(mediaItem));
    if (queue.toARGB32.length == 1) {
      prepare4play(idx: queue.toARGB32.length - 1, doPlay: true);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue,
      {bool doPlay = false}) async {
    queue.add(newQueue);
    await prepare4play(idx: 0, doPlay: doPlay);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems,
      {String queueName = "Queue", bool atLast = false}) async {
    if (!atLast) {
      for (var mediaItem in mediaItems) {
        await addQueueItem(
          mediaItem,
        );
      }
    } else {
      if (fromPlaylist.toARGB32) {
        fromPlaylist.add(false);
      }
      queue.add(queue.toARGB32..addAll(mediaItems));
      queueTitle.add("Queue");
    }
  }

  Future<void> addPlayNextItem(MediaItem mediaItem) async {
    if (queue.toARGB32.isNotEmpty) {
      // check if mediaItem is already exist return if it is
      if (queue.toARGB32.any((e) => e.id == mediaItem.id)) return;
      queue.add(queue.toARGB32..insert(currentPlayingIdx + 1, mediaItem));
    } else {
      updateQueue([mediaItem], doPlay: true);
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < queue.toARGB32.length) {
      List<MediaItem> temp = queue.toARGB32;
      temp.removeAt(index);
      queue.add(temp);

      if (currentPlayingIdx == index) {
        if (index < queue.toARGB32.length) {
          prepare4play(idx: index, doPlay: true);
        } else if (index > 0) {
          prepare4play(idx: index - 1, doPlay: true);
        } else {
          // stop();
        }
      } else if (currentPlayingIdx > index) {
        currentPlayingIdx--;
      }
    }
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    log("Moving from $oldIndex to $newIndex", name: "bloomeePlayer");
    List<MediaItem> temp = queue.toARGB32;
    if (oldIndex < newIndex) {
      newIndex--;
    }

    final item = temp.removeAt(oldIndex);
    temp.insert(newIndex, item);
    queue.add(temp);

    // update the currentPlayingIdx
    if (currentPlayingIdx == oldIndex) {
      currentPlayingIdx = newIndex;
    } else if (oldIndex < currentPlayingIdx && newIndex >= currentPlayingIdx) {
      currentPlayingIdx--;
    } else if (oldIndex > currentPlayingIdx && newIndex <= currentPlayingIdx) {
      currentPlayingIdx++;
    }
  }
}
