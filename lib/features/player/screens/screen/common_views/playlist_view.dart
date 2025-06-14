import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:elythra_music/core/blocs/playlist_view/online_playlist_cubit.dart';
import 'package:elythra_music/core/model/playlist_onl_model.dart';
import 'package:elythra_music/core/model/source_engines.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/imgurl_formator.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';

class OnlPlaylistView extends StatefulWidget {
  final PlaylistOnlModel playlist;
  final SourceEngine sourceEngine;
  const OnlPlaylistView(
      {super.key, required this.playlist, required this.sourceEngine});

  @override
  State<OnlPlaylistView> createState() => OnlPlaylistViewStateState();
}

class OnlPlaylistViewStateState extends State<OnlPlaylistView> {
  late OnlPlaylistCubit onlPlaylistCubit;
  @override
  void initState() {
    onlPlaylistCubit = OnlPlaylistCubit(
      playlist: widget.playlist,
      sourceEngine: widget.sourceEngine,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<OnlPlaylistCubit, OnlPlaylistState>(
          bloc: onlPlaylistCubit,
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight:
                      ResponsiveBreakpoints.of(context).isMobile ? 220 : 250,
                  flexibleSpace: LayoutBuilder(builder: (context, constraints) {
                    return FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 34,
                          bottom: 8,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight,
                            minWidth: 350,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.4,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  child: Hero(
                                    tag: widget.playlist.sourceId,
                                    child: LoadImageCached(
                                      imageUrl: formatImgURL(
                                          widget.playlist.imageURL,
                                          ImageQuality.high),
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Playlist by",
                                        style: DefaultTheme
                                            .secondoryTextStyleMedium
                                            .merge(
                                          TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            fontSize: 14,
                                            color: DefaultTheme.primaryColor1
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.playlist.artists,
                                        maxLines: 3,
                                        style: DefaultTheme
                                            .secondoryTextStyleMedium
                                            .merge(
                                          TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            fontSize: 14,
                                            color: DefaultTheme.primaryColor1
                                                .withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                      state.playlist.description != null
                                          ? Text(
                                              state.playlist.description ?? "",
                                              style: DefaultTheme
                                                  .secondoryTextStyle
                                                  .merge(
                                                TextStyle(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontSize: 13,
                                                  color: DefaultTheme
                                                      .primaryColor1
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    width: 2,
                                                    color: DefaultTheme
                                                        .accentColor2,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  if (context
                                                          .read<
                                                              ElythraPlayerCubit>()
                                                          .bloomeePlayer
                                                          .queueTitleValue !=
                                                      widget.playlist.name) {
                                                    context
                                                        .read<
                                                            ElythraPlayerCubit>()
                                                        .bloomeePlayer
                                                        .loadPlaylist(
                                                            state.playlist
                                                                .playlist);
                                                  } else if (!context
                                                      .read<
                                                          ElythraPlayerCubit>()
                                                      .bloomeePlayer
                                                      .audioPlayer
                                                      .playing) {
                                                    context
                                                        .read<
                                                            ElythraPlayerCubit>()
                                                        .bloomeePlayer
                                                        .play();
                                                  }
                                                },
                                                label: const Text(
                                                  "Play",
                                                  style: DefaultTheme
                                                      .secondoryTextStyleMedium,
                                                ),
                                                icon: const Icon(
                                                  MingCute.play_fill,
                                                  size: 20,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 5,
                                                ),
                                                child: IconButton(
                                                  onPressed: () {
                                                    onlPlaylistCubit
                                                        .addToSavedCollections();
                                                  },
                                                  icon: state.isSavedCollection
                                                      ? const Icon(FontAwesome
                                                          .heart_solid)
                                                      : const Icon(
                                                          FontAwesome.heart),
                                                  color: DefaultTheme
                                                      .accentColor2,
                                                ),
                                              ),
                                              Tooltip(
                                                message: "Open Original Link",
                                                child: IconButton(
                                                  onPressed: () {
                                                    SnackbarService.showMessage(
                                                        "Opening original album page.");
                                                    launchUrl(
                                                        Uri.parse(state.playlist
                                                            .sourceURL),
                                                        mode: LaunchMode
                                                            .externalApplication);
                                                  },
                                                  icon: const Icon(
                                                    MingCute.external_link_line,
                                                    size: 25,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Text(
                      widget.playlist.name,
                      maxLines: 3,
                      textAlign: TextAlign.center,
                      style: DefaultTheme.secondoryTextStyleMedium.merge(
                        TextStyle(
                          fontSize: 20,
                          color: DefaultTheme.primaryColor1.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                (state is OnlPlaylistLoaded || state.playlist.songs.isNotEmpty)
                    ? SliverList.builder(
                        itemBuilder: (context, index) {
                          return SongCardWidget(
                            song: state.playlist.songs[index],
                            onOptionsTap: () {
                              showMoreBottomSheet(
                                context,
                                state.playlist.songs[index],
                                showDelete: false,
                                showSinglePlay: true,
                              );
                            },
                            onTap: () {
                              if (context
                                          .read<ElythraPlayerCubit>()
                                          .bloomeePlayer
                                          .queueTitleValue !=
                                      widget.playlist.name ||
                                  context
                                          .read<ElythraPlayerCubit>()
                                          .bloomeePlayer
                                          .currentMedia !=
                                      state.playlist.songs[index]) {
                                context
                                    .read<ElythraPlayerCubit>()
                                    .bloomeePlayer
                                    .loadPlaylist(state.playlist.playlist);
                              } else if (!context
                                  .read<ElythraPlayerCubit>()
                                  .bloomeePlayer
                                  .audioPlayer
                                  .playing) {
                                context
                                    .read<ElythraPlayerCubit>()
                                    .bloomeePlayer
                                    .play();
                              }
                            },
                          );
                        },
                        itemCount: state.playlist.songs.length)
                    : const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(),
                        )),
              ],
            );
          },
        ),
      ),
    );
  }
}
