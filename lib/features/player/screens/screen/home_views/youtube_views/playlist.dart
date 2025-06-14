// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:core';
import 'dart:developer';
import 'package:elythra_music/core/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart' as player;
import 'package:elythra_music/core/model/yt_music_model.dart';
import 'package:elythra_music/core/repository/Youtube/ytm/ytmusic.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/play_pause_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:elythra_music/core/services/db/bloomee_db_service.dart';
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/core/model/youtube_vid_model.dart';
import 'package:elythra_music/core/repository/Youtube/youtube_api.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:elythra_music/core/utils/imgurl_formator.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:share_plus/share_plus.dart';

class YoutubePlaylist extends StatefulWidget {
  final String imgPath;
  final String title;
  final String subtitle;
  final String type;
  final String id;
  const YoutubePlaylist({
    Key? key,
    required this.imgPath,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.id,
  }) : super(key: key);

  @override
  State<YoutubePlaylist> createState() => YoutubePlaylistStateState();
}

class YoutubePlaylistStateState extends State<YoutubePlaylist> {
  late Future<Map<dynamic, dynamic>?> data;
  late List<Map<dynamic, dynamic>> items;
  late List<MediaItemModel> mediaitems;

  Future<void> _loadData() async {
    final res = await data;
    if (res == null) {
      mediaitems = [];
      return;
    }
    items = res["songs"] as List<Map<dynamic, dynamic>>;
    mediaitems = ytmMapList2MediaItemList(items);
  }

  Future<MediaItemModel?> fetchSong(String id, String imgUrl) async {
    log("Fetching: $id", name: "YoutubePlaylist");
    final song = await YouTubeServices()
        .formatVideoFromId(id: id.replaceAll("youtube", ""));
    if (song != null) {
      final mediaItem = fromYtVidSongMap2MediaItem(song);
      return MediaItemModel(
        id: mediaItem.id,
        title: mediaItem.title,
        artist: mediaItem.artist,
        album: mediaItem.album,
        artUri: Uri.parse(imgUrl),
        duration: mediaItem.duration,
        extras: mediaItem.extras,
      );
    }
    return null;
  }

  @override
  void initState() {
    data = YTMusic().getPlaylistFull(widget.id.replaceAll("youtube", ""));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          child: state == ConnectivityState.disconnected
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(
                    child: SignBoardWidget(
                      message:
                          "No internet connection\nPlease connect to the internet.",
                      icon: MingCute.wifi_off_line,
                    ),
                  ),
                )
              : FutureBuilder(
                  future: _loadData(),
                  builder: (context, snapshot) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? Scaffold(
                              appBar: AppBar(),
                              body: const Center(
                                child: SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: CircularProgressIndicator()),
                              ),
                            )
                          : snapshot.hasError
                              ? const CustomScrollView(
                                  slivers: [
                                    SliverAppBar(
                                      backgroundColor: DefaultTheme.themeColor,
                                      surfaceTintColor:
                                          DefaultTheme.themeColor,
                                    ),
                                    SliverFillRemaining(
                                      child: Center(
                                        child: SignBoardWidget(
                                          message:
                                              "Got Error while loading data",
                                          icon: MingCute.loading_line,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : CustomScrollView(
                                  slivers: [
                                    SliverAppBar(
                                      actions: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10.0),
                                          child: IconButton(
                                            onPressed: () {
                                              Share.share(
                                                  "${widget.title} - ${widget.subtitle} \nhttps://youtube.com/playlist?list=${widget.id.replaceAll("youtube", "")}");
                                            },
                                            padding: const EdgeInsets.all(5),
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              MingCute.share_forward_line,
                                              color:
                                                  DefaultTheme.primaryColor1,
                                              size: 25,
                                            ),
                                          ),
                                        ),
                                      ],
                                      backgroundColor: DefaultTheme.themeColor,
                                      surfaceTintColor:
                                          DefaultTheme.themeColor,
                                      // expandedHeight:
                                      //     (ResponsiveBreakpoints.of(
                                      //                 context)
                                      //             .isMobile
                                      //         ? MediaQuery.of(context)
                                      //                 .size
                                      //                 .height *
                                      //             0.27
                                      //         : MediaQuery.of(context)
                                      //                 .size
                                      //                 .width *
                                      //             0.18),
                                      floating: false,
                                      pinned: true,
                                      // flexibleSpace: FlexibleSpaceBar(
                                      //   background:
                                      // ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            // mainAxisSize:
                                            //     MainAxisSize.min,

                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 16.0, right: 8.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: SizedBox.square(
                                                    dimension:
                                                        ResponsiveBreakpoints
                                                                    .of(context)
                                                                .isMobile
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.22
                                                            : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.15,
                                                    child: LoadImageCached(
                                                        imageUrl: formatImgURL(
                                                            widget.imgPath,
                                                            ImageQuality.low)),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          widget.title,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: DefaultTheme
                                                                .primaryColor1,
                                                          ).merge(DefaultTheme
                                                                  .secondoryTextStyle),
                                                        ),
                                                      ),
                                                      Text(
                                                        widget.subtitle,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: DefaultTheme
                                                              .primaryColor2
                                                              .withOpacity(0.8),
                                                        ).merge(DefaultTheme
                                                            .secondoryTextStyle),
                                                      ),
                                                      Text(
                                                        "Youtube • ${(widget.type == 'playlist') ? 'Playlist' : 'Album'}",
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: DefaultTheme
                                                              .primaryColor2
                                                              .withOpacity(0.8),
                                                        ).merge(DefaultTheme
                                                            .secondoryTextStyle),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 6.0,
                                                                bottom: 6.0,
                                                                right: 10),
                                                        child: SizedBox(
                                                          height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height <
                                                                  700
                                                              ? 45
                                                              : MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.07,
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.42,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            6.0),
                                                                child: Tooltip(
                                                                  message:
                                                                      "Shuffle & Play All",
                                                                  child:
                                                                      IconButton(
                                                                    onPressed:
                                                                        () {
                                                                      SnackbarService.showMessage(
                                                                          "Shuffling & Playing All",
                                                                          duration:
                                                                              const Duration(seconds: 2));
                                                                      context
                                                                          .read<
                                                                              player.ElythraPlayerCubit>()
                                                                          .bloomeePlayer
                                                                          .updateQueue(
                                                                            mediaitems,
                                                                            doPlay: true,
                                                                            idx: 0,
                                                                          );
                                                                    },
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            5),
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                    icon:
                                                                        const Icon(
                                                                      MingCute
                                                                          .shuffle_fill,
                                                                      color: DefaultTheme
                                                                          .primaryColor1,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Tooltip(
                                                                message:
                                                                    "Play All",
                                                                child: StreamBuilder<
                                                                        String>(
                                                                    stream: context
                                                                        .watch<
                                                                            player.ElythraPlayerCubit>()
                                                                        .bloomeePlayer
                                                                        .queueTitle,
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      if (snapshot
                                                                              .hasData &&
                                                                          snapshot.data ==
                                                                              "${widget.title} - Youtube") {
                                                                        return StreamBuilder<
                                                                                PlayerState>(
                                                                            stream:
                                                                                context.read<player.ElythraPlayerCubit>().bloomeePlayer.audioPlayer.playerStateStream,
                                                                            builder: (context, snapshot2) {
                                                                              if (snapshot2.hasData && (snapshot2.data?.playing ?? false)) {
                                                                                return PlayPauseButton(
                                                                                  onPause: () => context.read<player.ElythraPlayerCubit>().bloomeePlayer.pause(),
                                                                                  onPlay: () => context.read<player.ElythraPlayerCubit>().bloomeePlayer.play(),
                                                                                  isPlaying: true,
                                                                                  size: 45,
                                                                                );
                                                                              } else {
                                                                                return PlayPauseButton(
                                                                                  onPause: () => context.read<player.ElythraPlayerCubit>().bloomeePlayer.pause(),
                                                                                  onPlay: () => context.read<player.ElythraPlayerCubit>().bloomeePlayer.play(),
                                                                                  isPlaying: false,
                                                                                  size: 45,
                                                                                );
                                                                              }
                                                                            });
                                                                      } else {
                                                                        return PlayPauseButton(
                                                                          onPause: () => context
                                                                              .read<player.ElythraPlayerCubit>()
                                                                              .bloomeePlayer
                                                                              .pause(),
                                                                          onPlay:
                                                                              () {
                                                                            context.read<player.ElythraPlayerCubit>().bloomeePlayer.loadPlaylist(player.MediaPlaylist(
                                                                                name: "${widget.title} - Youtube",
                                                                                items: mediaitems.map((item) => player.ElythraMediaItem.fromMediaItemModel(item)).toList()));
                                                                            context.read<player.ElythraPlayerCubit>().bloomeePlayer.play();
                                                                          },
                                                                          size:
                                                                              45,
                                                                        );
                                                                      }
                                                                    }),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  left: 8,
                                                                ),
                                                                child: Tooltip(
                                                                  message:
                                                                      "Add to Library",
                                                                  child:
                                                                      IconButton(
                                                                    onPressed:
                                                                        () async {
                                                                      SnackbarService.showMessage(
                                                                          "Adding to Library",
                                                                          duration:
                                                                              const Duration(seconds: 2));
                                                                      await Future.forEach(
                                                                          mediaitems,
                                                                          (element) {
                                                                        ElythraDBService.addMediaItem(
                                                                            mediaItem2MediaItemDB(element),
                                                                            "${widget.title} - Youtube");
                                                                      });
                                                                      SnackbarService.showMessage(
                                                                          "Added to Library",
                                                                          duration:
                                                                              const Duration(seconds: 2));
                                                                    },
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            2),
                                                                    constraints:
                                                                        const BoxConstraints(),
                                                                    icon:
                                                                        const Icon(
                                                                      FontAwesome
                                                                          .square_plus,
                                                                      color: DefaultTheme
                                                                          .primaryColor1,
                                                                    ),
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: const EdgeInsets.only(
                                          top: 10, left: 3),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            return SongCardWidget(
                                              song: mediaitems[index],
                                              isWide: true,
                                              onOptionsTap: () {
                                                showMoreBottomSheet(
                                                  context,
                                                  mediaitems[index],
                                                  showSinglePlay: true,
                                                );
                                              },
                                              onTap: () {
                                                context
                                                    .read<player.ElythraPlayerCubit>()
                                                    .bloomeePlayer
                                                    .updateQueue(
                                                        mediaitems,
                                                        idx: index,
                                                        doPlay: true);
                                              },
                                            );
                                          },
                                          childCount: items.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                    );
                    // }
                  }),
        );
      },
    );
  }
}
