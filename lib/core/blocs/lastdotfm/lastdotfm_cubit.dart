import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:elythra_music/core/blocs/mediaPlayer/elythra_player_cubit.dart';
import 'package:elythra_music/core/model/media_playlist_model.dart' as core_playlist;
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/core/repository/LastFM/lastfmapi.dart';
import 'package:elythra_music/core/repository/MixedAPI/mixed_api.dart';
import 'package:elythra_music/core/routes_and_consts/global_conts.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/subjects.dart';
import 'package:url_launcher/url_launcher.dart';

part 'lastdotfm_state.dart';

class LastdotfmCubit extends Cubit<LastdotfmState> {
  LastFmAPI lastFmAPI = LastFmAPI();
  StreamSubscription? scrobbleSub;
  ElythraPlayerCubit playerCubit;
  MediaItemModel lastPlayed = mediaItemModelNull;
  Stopwatch stopwatch = Stopwatch();
  Stream<dynamic>? playerProgres;
  BehaviorSubject<MediaItemModel> playedMedia =
      BehaviorSubject<MediaItemModel>.seeded(mediaItemModelNull);

  LastdotfmCubit({
    required this.playerCubit,
  }) : super(LastdotfmInitial()) {
    initializeFromDB();
    songTimeTracker();
  }
  @override
  close() async {
    playedMedia.close();
    scrobbleSub?.cancel();
    super.close();
  }

  Future<void> songTimeTracker() async {
    while (playerCubit.playerInitState != PlayerInitState.initialized) {
      log("Waiting for player to be intialized.", name: "Last.FM");
      await Future.delayed(const Duration(seconds: 2));
    }

    scrobbleSub = playerCubit.progressStreams.listen((event) {
      if (playerCubit.bloomeePlayer.audioPlayer.playing &&
          event.currentPlaybackState.processingState == ProcessingState.ready) {
        final currentMediaModel = playerCubit.bloomeePlayer.currentMedia;
        if (lastPlayed != currentMediaModel ||
            !stopwatch.isRunning) {
          if (stopwatch.isRunning) {
            stopwatch.stop();
            stopwatch.reset();
          }
          stopwatch.start();
          if (currentMediaModel != null) {
            lastPlayed = currentMediaModel;
          }
        } else if ((stopwatch.elapsed.inSeconds > 30 ||
                (stopwatch.elapsed.inSeconds /
                        (playerCubit.bloomeePlayer.currentMedia?.duration ?? const Duration(
                                    hours:
                                        1)).inSeconds) >
                    0.5) &&
            currentMediaModel == lastPlayed &&
            currentMediaModel != playedMedia.value) {
          if (currentMediaModel != null) {
            playedMedia.add(currentMediaModel);
          }
          log("Scrobbling: ${playerCubit.bloomeePlayer.currentMedia?.title}",
              name: "Last.FM");
          scrobble(lastPlayed).then(
            (value) {
              if (value) {
                log("Scrobble success.", name: "Last.FM");
              } else {
                log("Scrobble failed.", name: "Last.FM");
              }
            },
          );
        }
      } else if (lastPlayed != playerCubit.bloomeePlayer.currentMedia) {
        stopwatch.stop();
        stopwatch.reset();
      } else {
        stopwatch.stop();
      }
    });
  }

  Future<void> initializeFromDB() async {
    log("Getting Last.FM Keys from DB", name: "Last.FM");
    final username =
        await ElythraDBService.getApiTokenDB(GlobalStrConsts.lFMUsername);
    final apiKey =
        await ElythraDBService.getApiTokenDB(GlobalStrConsts.lFMApiKey);
    final apiSecret =
        await ElythraDBService.getApiTokenDB(GlobalStrConsts.lFMSecret);
    final session =
        await ElythraDBService.getApiTokenDB(GlobalStrConsts.lFMSession);

    if (apiKey != null &&
        apiSecret != null &&
        username != null &&
        apiKey.isNotEmpty &&
        username.isNotEmpty &&
        apiSecret.isNotEmpty) {
      LastFmAPI.setAPIKey(apiKey);
      LastFmAPI.setAPISecret(apiSecret);
      if (session != null && session.isNotEmpty) {
        LastFmAPI.sessionKey = session;
        LastFmAPI.username = username;
        LastFmAPI.initialized = true;
        emit(LastdotfmIntialized(
            apiKey: apiKey,
            apiSecret: apiSecret,
            sessionKey: session,
            username: username));
      }
    }
    startUpCheck();
    log("Last.FM Keys from DB: $apiKey, $apiSecret, $session", name: "Last.FM");
  }

  Future<void> fetchSessionkey(
      {required String token,
      required String secret,
      required String apiKey}) async {
    try {
      final sessionMap = await LastFmAPI.fetchSessionKey(token);
      final session = sessionMap["key"]!;
      final name = sessionMap["name"]!;
      ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMUsername, name, "0");
      ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMSecret, secret, "0");
      ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMApiKey, apiKey, "0");
      ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMSession, session, "0");
      log('Session Key: $session', name: 'LastFM API');

      if (session.isNotEmpty && apiKey.isNotEmpty && secret.isNotEmpty) {
        LastFmAPI.sessionKey = session;
        LastFmAPI.username = name;
        LastFmAPI.initialized = true;
        emit(LastdotfmIntialized(
          apiKey: apiKey,
          apiSecret: secret,
          sessionKey: session,
          username: name,
        ));
      }
    } catch (e) {
      log("Error: $e", name: "Last.FM");
      emit(LastdotfmFailed(message: e.toString()));
    }
  }

  Future<String> startAuth(
      {required String apiKey, required String secret}) async {
    // Start the authentication process
    LastFmAPI.setAPIKey(apiKey);
    LastFmAPI.setAPISecret(secret);
    final token = await LastFmAPI.fetchRequestToken();
    final url = LastFmAPI.getAuthUrl(token);
    log('Auth URL: $url', name: 'LastFM API');
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return token;
  }

  Future<void> remove() async {
    LastFmAPI.initialized = false;
    LastFmAPI.sessionKey = null;
    LastFmAPI.apiKey = null;
    LastFmAPI.apiSecret = null;
    LastFmAPI.username = null;
    emit(LastdotfmInitial());
    ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMSecret, "", "0");
    ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMApiKey, "", "0");
    ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMSession, "", "0");
    ElythraDBService.putApiTokenDB(GlobalStrConsts.lFMUsername, "", "0");
  }

  startUpCheck() async {
    final lastUnScrobbled = await getLFMTrackedCache();
    if (lastUnScrobbled.isNotEmpty) {
      final isSuccess = await scrobbleTrackList(lastUnScrobbled);
      log("Scrobble ${isSuccess ? "success" : "failed"}!", name: "Last.FM");
      if (!isSuccess) {
        lFMCacheTrack(lastUnScrobbled);
      }
    }
  }

  Future<bool> scrobbleTrackList(List<ScrobbleTrack> trackList) async {
    if (LastFmAPI.initialized) {
      try {
        final response = await LastFmAPI.scrobble(trackList);
        log('Scrobble response: $response', name: 'LastFM API');
        return response;
      } catch (e) {
        log('Scrobble failed: $e', name: 'LastFM API');
        lFMCacheTrack(trackList);
      }
    }
    return false;
  }

  Future<bool> scrobble(MediaItemModel mediaItem) async {
    final shouldScrobble = await ElythraDBService.getSettingBool(
        GlobalStrConsts.lFMScrobbleSetting,
        defaultValue: false);

    final durationMin = mediaItem.duration?.inMinutes ?? 20000;
    final durationSec = mediaItem.duration?.inSeconds ?? 20000;

    final track = ScrobbleTrack(
      artist: mediaItem.artist ?? 'Unknown',
      trackName: mediaItem.title,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      album: mediaItem.album ?? 'Unknown',
      duration: mediaItem.duration?.inSeconds ?? 0,
      chosenByUser: false,
    );
    if (shouldScrobble ?? false) {
      List<ScrobbleTrack> trackList = await getLFMTrackedCache();
      trackList.add(track);
      try {
        if (LastFmAPI.initialized &&
            mediaItem != mediaItemModelNull &&
            durationMin < 15 &&
            durationSec > 30) {
          final response = await LastFmAPI.scrobble(trackList);
          log('Scrobble response: $response', name: 'LastFM API');
          return response;
        }
      } catch (e) {
        log('Scrobble failed: $e', name: 'LastFM API');
        lFMCacheTrack(trackList);
      }
    }
    return false;
  }

  void lFMCacheTrack(List<ScrobbleTrack> trackList) {
    final trackListMap = trackList.map((e) => e.toJson()).toList();
    ElythraDBService.getAPICache(GlobalStrConsts.lFMTrackedCache).then((value) {
      if (value != null && value != "null") {
        log("Cache found: ${trackListMap.toString()}", name: "Last.FM");
        final trackList2 = value as List;
        trackList2.addAll(trackListMap);
        ElythraDBService.putAPICache(
            GlobalStrConsts.lFMTrackedCache, trackList2.toString());
      } else {
        log("No cache found", name: "Last.FM");
        ElythraDBService.putAPICache(
            GlobalStrConsts.lFMTrackedCache, trackListMap.toString());
      }
    });
  }

  Future<List<ScrobbleTrack>> getLFMTrackedCache() async {
    final trackList =
        await ElythraDBService.getAPICache(GlobalStrConsts.lFMTrackedCache);
    await ElythraDBService.putAPICache(GlobalStrConsts.lFMTrackedCache, "null");
    if (trackList != null && trackList.isNotEmpty && trackList != "null") {
      final trackListMap = jsonDecode(trackList) as List;
      List<ScrobbleTrack> trackListObj = [];
      for (var element in trackListMap) {
        trackListObj.add(ScrobbleTrack.fromJson(element));
      }
      return trackListObj;
    }
    return [];
  }

  Future<core_playlist.MediaPlaylist> getRecommendedTracks() async {
    if (!LastFmAPI.initialized) {
      while (!LastFmAPI.initialized) {
        await Future.delayed(const Duration(seconds: 10));
      }
    }
    final response = await LastFmAPI.getUserRecommendedList();
    List<MediaItemModel> mediaItems = [];
    for (var track in response['playlist']) {
      String title = track['name'];
      List<String> artists = [];
      if (track['artists'] != null) {
        for (var aItem in track['artists']) {
          artists.add(aItem['name']);
        }
      }
      final mediaItem =
          await MixedAPI().getYtTrackByMeta("$title ${artists.join(' ')}");
      if (mediaItem != null) {
        mediaItems.add(mediaItem);
      }
    }
    return core_playlist.MediaPlaylist(mediaItems: mediaItems, playlistName: 'Last.FM Picks');
  }
}
