import 'dart:ui';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart' as player;
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/features/player/screens/screen/library_views/cubit/current_playlist_cubit.dart';
import 'package:elythra_music/features/player/screens/screen/library_views/more_opts_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/play_pause_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/snackbar.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:elythra_music/core/services/db/global_db.dart';
import 'package:elythra_music/core/services/db/cubit/bloomee_db_cubit.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/imgurl_formator.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:just_audio/just_audio.dart';

part 'playlist_info_dialog.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  final double titleScale = 1.5;

  final double titleFontSize = 16;

  Color _adjustColor(Color color, bool darken, {double amount = 0.1}) {
    final hsl = HSLColor.fromColor(color);
    HSLColor adjustedHsl = darken
        ? hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        : hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    if (!darken && adjustedHsl.lightness < 0.75) {
      adjustedHsl = adjustedHsl.withLightness(0.85);
    }
    return adjustedHsl.toColor();
  }

  List<Color> getFBColor(BuildContext context) {
    // get foreground and background color from current playlist pallete
    Color? color = context
        .read<CurrentPlaylistCubit>()
        .getCurrentPlaylistPallete()
        ?.lightVibrantColor
        ?.color;
    Color? bgColor = context
        .read<CurrentPlaylistCubit>()
        .getCurrentPlaylistPallete()
        ?.darkMutedColor
        ?.color;
    if (bgColor != null && color != null) {
      //calculate contrast between two color and bgcolor
      final double contrast =
          bgColor.computeLuminance() / color.computeLuminance();
      if (contrast > 0.05) {
        color = _adjustColor(color, false);
        bgColor = _adjustColor(bgColor, true);
      }
      return [color, bgColor];
    }
    return [Colors.white, Colors.black];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: DefaultTheme.themeColor,
        body: BlocBuilder<CurrentPlaylistCubit, CurrentPlaylistState>(
          builder: (context, state) {
            const double maxExtent = 300;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: (state is! CurrentPlaylistInitial &&
                      state.mediaPlaylist.mediaItems.isNotEmpty)
                  ? CustomScrollView(
                      key: const ValueKey('1'),
                      physics: const BouncingScrollPhysics(),
                      primary: true,
                      slivers: [
                        SliverAppBar(
                          leading: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                            ),
                            hoverColor: getFBColor(context)[1].withOpacity(0.3),
                            highlightColor:
                                getFBColor(context)[0].withOpacity(0.6),
                            color: getFBColor(context)[0],
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                  getFBColor(context)[1].withOpacity(0.1)),
                            ),
                            onPressed: () {
                              context.pop();
                            },
                          ),
                          backgroundColor: DefaultTheme.themeColor,
                          surfaceTintColor: DefaultTheme.themeColor,
                          expandedHeight: maxExtent,
                          floating: false,
                          pinned: true,
                          centerTitle: false,
                          flexibleSpace:
                              LayoutBuilder(builder: (context, constraints) {
                            final double percentage =
                                (constraints.maxHeight - kToolbarHeight) /
                                    (maxExtent - kToolbarHeight);
                            const double startPadding = 20.0;
                            const double endPadding = 60.0;
                            final double horizontalPadding = startPadding +
                                (endPadding - startPadding) *
                                    (1.0 - percentage);
                            final bool isCollapsed = percentage < 0.4;

                            final span = TextSpan(
                              text: state.mediaPlaylist.playlistName,
                              style:
                                  DefaultTheme.secondoryTextStyleMedium.merge(
                                TextStyle(
                                  fontSize: titleFontSize,
                                  color: getFBColor(context)[0],
                                ),
                              ),
                            );

                            final textPainter = TextPainter(
                                text: span,
                                textDirection: TextDirection.ltr,
                                maxLines: 3,
                                textScaler: TextScaler.linear(titleScale))
                              ..layout(
                                  maxWidth:
                                      constraints.maxWidth - horizontalPadding);

                            final textHeight = textPainter.height;

                            return FlexibleSpaceBar(
                              expandedTitleScale: titleScale,
                              titlePadding: EdgeInsets.only(
                                  left: horizontalPadding,
                                  bottom: isCollapsed ? 16 : 10),
                              title: Text(
                                state.mediaPlaylist.playlistName,
                                maxLines: isCollapsed ? 1 : 3,
                                style: DefaultTheme.secondoryTextStyleMedium
                                    .merge(
                                  TextStyle(
                                    fontSize: titleFontSize,
                                    overflow: TextOverflow.ellipsis,
                                    color: getFBColor(context)[0],
                                  ),
                                ),
                              ),
                              background: LayoutBuilder(
                                  builder: (context, constraints) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    LoadImageCached(
                                        imageUrl: formatImgURL(
                                            state.mediaPlaylist.mediaItems.first
                                                .artUri
                                                .toString(),
                                            ImageQuality.low)),
                                    Positioned(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            getFBColor(context)[1]
                                                .withOpacity(0.0),
                                            getFBColor(context)[1]
                                                .withOpacity(1),
                                          ],
                                          stops: const [0.5, 1],
                                        ),
                                      ),
                                    )),

                                    // Lower portion with blur
                                    Positioned.fill(
                                      top: MediaQuery.of(context).size.height *
                                          0.6, // Adjust this position as needed
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 30, sigmaY: 30),
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 
                                              0), // Keep the container color transparent
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      top: 10,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: SizedBox(
                                          height: constraints.maxHeight -
                                              (textHeight + 30),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 80, right: 80),
                                              child: Container(
                                                // shadow effect
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          getFBColor(context)[1]
                                                              .withOpacity(0.2),
                                                      spreadRadius: 5,
                                                      blurRadius: 7,
                                                      offset: const Offset(0,
                                                          3), // changes position of shadow
                                                    ),
                                                  ],
                                                ),
                                                child: LoadImageCached(
                                                    imageUrl: formatImgURL(
                                                        state
                                                            .mediaPlaylist
                                                            .mediaItems
                                                            .first
                                                            .artUri
                                                            .toString(),
                                                        ImageQuality.high)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                        right: 8,
                                        top: 8,
                                        child: IconButton(
                                          icon: const Icon(
                                            MingCute.information_line,
                                          ),
                                          hoverColor: getFBColor(context)[1]
                                              .withOpacity(0.2),
                                          color: getFBColor(context)[0],
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStatePropertyAll(
                                                    getFBColor(context)[1]
                                                        .withOpacity(0.05)),
                                          ),
                                          onPressed: () {
                                            // dialog to show all infromation about the playlist (playlist name, source, description, original link, type, etc  )
                                            showPlaylistInfo(context, state,
                                                fgColor: getFBColor(context)[0],
                                                bgColor:
                                                    getFBColor(context)[1]);
                                          },
                                        )),
                                    // blur fade effect bottom edge
                                  ],
                                );
                              }),
                            );
                          }),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 12,
                              left: 20,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${state.mediaPlaylist.isAlbum ? "Album" : "Playlist"} • ${state.mediaPlaylist.mediaItems.length} Songs \nby ${state.mediaPlaylist.artists ?? 'You'}",
                                    style: DefaultTheme.secondoryTextStyle
                                        .merge(TextStyle(
                                      color: DefaultTheme.primaryColor1
                                          .withOpacity(0.8),
                                      fontSize: 12,
                                    )),
                                  ),
                                ),
                                OverflowBar(
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          context
                                              .read<player.ElythraPlayerCubit>()
                                              .bloomeePlayer
                                              .loadPlaylist(
                                                  player.MediaPlaylist(
                                                      name: state
                                                          .mediaPlaylist
                                                          .playlistName,
                                                      items: state
                                                          .mediaPlaylist
                                                          .mediaItems.map((item) => player.ElythraMediaItem.fromMediaItemModel(item)).toList()));
                                        },
                                        padding: EdgeInsets.zero,
                                        icon: Icon(MingCute.shuffle_line,
                                            color: DefaultTheme.primaryColor1
                                                .withOpacity(0.8))),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 2, left: 5),
                                      child: BlocBuilder<CurrentPlaylistCubit,
                                          CurrentPlaylistState>(
                                        builder: (context, state) {
                                          return StreamBuilder<String>(
                                              stream: context
                                                  .watch<player.ElythraPlayerCubit>()
                                                  .bloomeePlayer
                                                  .queueTitle,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData &&
                                                    snapshot.data ==
                                                        state.mediaPlaylist
                                                            .playlistName) {
                                                  return StreamBuilder<
                                                          PlayerState>(
                                                      stream: context
                                                          .read<
                                                              player.ElythraPlayerCubit>()
                                                          .bloomeePlayer
                                                          .audioPlayer
                                                          .playerStateStream,
                                                      builder:
                                                          (context, snapshot2) {
                                                        if (snapshot2.hasData &&
                                                            (snapshot2.data
                                                                    ?.playing ?? false)) {
                                                          return PlayPauseButton(
                                                            onPause: () => context
                                                                .read<
                                                                    player.ElythraPlayerCubit>()
                                                                .bloomeePlayer
                                                                .pause(),
                                                            onPlay: () => context
                                                                .read<
                                                                    player.ElythraPlayerCubit>()
                                                                .bloomeePlayer
                                                                .audioPlayer
                                                                .play(),
                                                            isPlaying: true,
                                                            size: 40,
                                                          );
                                                        } else {
                                                          return PlayPauseButton(
                                                            onPause: () => context
                                                                .read<
                                                                    player.ElythraPlayerCubit>()
                                                                .bloomeePlayer
                                                                .pause(),
                                                            onPlay: () => context
                                                                .read<
                                                                    player.ElythraPlayerCubit>()
                                                                .bloomeePlayer
                                                                .audioPlayer
                                                                .play(),
                                                            isPlaying: false,
                                                            size: 40,
                                                          );
                                                        }
                                                      });
                                                } else {
                                                  return PlayPauseButton(
                                                    onPause: () => context
                                                        .read<
                                                            player.ElythraPlayerCubit>()
                                                        .bloomeePlayer
                                                        .pause(),
                                                    onPlay: () {
                                                      context
                                                          .read<
                                                              player.ElythraPlayerCubit>()
                                                          .bloomeePlayer
                                                          .updateQueue(state.mediaPlaylist.mediaItems, doPlay: true, idx: 0);
                                                    },
                                                    size: 40,
                                                  );
                                                }
                                              });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                        onPressed: () {
                                          showPlaylistOptsInrSheet(
                                              context, player.MediaPlaylist(
                                                name: state.mediaPlaylist.playlistName,
                                                items: state.mediaPlaylist.mediaItems.map((item) => player.ElythraMediaItem.fromMediaItemModel(item)).toList()));
                                        },
                                        icon: Icon(MingCute.more_2_line,
                                            color: DefaultTheme.primaryColor1
                                                .withOpacity(0.8))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPrototypeExtentList.builder(
                          itemBuilder: (context, index) {
                            return SongCardWidget(
                              key: ValueKey(
                                  state.mediaPlaylist.mediaItems[index]),
                              song: state.mediaPlaylist.mediaItems[index],
                              onTap: () {
                                context
                                    .read<player.ElythraPlayerCubit>()
                                    .bloomeePlayer
                                    .updateQueue(state.mediaPlaylist.mediaItems, idx: index, doPlay: true);
                              },
                              onOptionsTap: () {
                                showMoreBottomSheet(
                                  context,
                                  state.mediaPlaylist.mediaItems[index],
                                  onDelete: () {
                                    context
                                        .read<elythraDBCubit>()
                                        .removeMediaFromPlaylist(
                                          state.mediaPlaylist.mediaItems[index],
                                          MediaPlaylistDB(
                                              playlistName: state
                                                  .mediaPlaylist.playlistName),
                                        );
                                  },
                                  showDelete: true,
                                  showSinglePlay: true,
                                );
                              },
                            );
                          },
                          itemCount: state.mediaPlaylist.mediaItems.length,
                          prototypeItem: SongCardWidget(
                            song: MediaItemModel(
                                id: "prototype",
                                artist: "prototype",
                                title: "prototype"),
                          ),
                        ),
                      ],
                    )
                  : ((state is CurrentPlaylistInitial ||
                          state is CurrentPlaylistLoading)
                      ? const CustomScrollView(
                          key: ValueKey('2'),
                          slivers: [
                            SliverAppBar(),
                            SliverFillRemaining(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          ],
                        )
                      : const CustomScrollView(
                          key: ValueKey('3'),
                          slivers: [
                            SliverAppBar(),
                            SliverFillRemaining(
                              child: Center(
                                child: SignBoardWidget(
                                  message: "No Songs Yet!",
                                  icon: MingCute.playlist_line,
                                ),
                              ),
                            )
                          ],
                        )),
            );
          },
        ),
      ),
    );
  }
}
