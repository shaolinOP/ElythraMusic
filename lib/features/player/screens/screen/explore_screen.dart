import 'dart:developer';
import 'package:elythra_music/core/blocs/explore/cubit/explore_cubits.dart';
import 'package:elythra_music/core/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
// import 'package:elythra_music/core/blocs/lastdotfm/lastdotfm_cubit.dart'; // Disabled
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:elythra_music/core/blocs/notification/notification_cubit.dart';
import 'package:elythra_music/core/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:elythra_music/core/model/media_playlist_model.dart' as core_playlist;
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/recents_view.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:elythra_music/core/services/db/cubit/bloomee_db_cubit.dart';
import 'package:elythra_music/core/utils/app_updater.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/notification_view.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_view.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/timer_view.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'chart/carousal_widget.dart';
import '../widgets/horizontal_card_view.dart';
import '../widgets/tab_list_widget.dart';
import 'package:badges/badges.dart' as badges;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => ExploreScreenStateState();
}

class ExploreScreenStateState extends State<ExploreScreen> {
  bool isUpdateChecked = false;
  YTMusicCubit yTMusicCubit = YTMusicCubit();
  Future<core_playlist.MediaPlaylist> lFMData =
      Future.value(const core_playlist.MediaPlaylist(mediaItems: [], playlistName: ""));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!isUpdateChecked) {
        if (await context
                .read<elythraDBCubit>()
                .getSettingBool(GlobalStrConsts.autoUpdateNotify) ??
            false) {
          updateDialog(context);
        }
      }
    });
  }

  Future<core_playlist.MediaPlaylist> fetchLFMPicks(bool state, BuildContext ctx) async {
    if (state) {
      try {
        final data = await lFMData;
        if (data.mediaItems.isNotEmpty) {
          return data;
        }
        // lFMData = ctx.read<LastdotfmCubit>().getRecommendedTracks(); // Disabled
        return (await lFMData);
      } catch (e) {
        log(e.toString(), name: "ExploreScreen");
      }
    }
    return const core_playlist.MediaPlaylist(mediaItems: [], playlistName: "");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RecentlyCubit>(
            create: (context) => RecentlyCubit(),
            lazy: false,
          ),
          BlocProvider(
            create: (context) => yTMusicCubit,
            lazy: false,
          ),
          BlocProvider(
            create: (context) => FetchChartCubit(),
            lazy: false,
          ),
        ],
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await yTMusicCubit.fetchYTMusic();
            },
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                const CustomDiscoverBar(),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      CaraouselWidget(),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: SizedBox(
                          child: BlocBuilder<RecentlyCubit, RecentlyCubitState>(
                            builder: (context, state) {
                              if (state is RecentlyCubitInitial) {
                                return const Center(
                                  child: SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: CircularProgressIndicator(
                                        color: DefaultTheme.accentColor2,
                                      )),
                                );
                              }
                              if (state.mediaPlaylist.mediaItems.isNotEmpty) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HistoryView()));
                                  },
                                  child: TabSongListWidget(
                                    list:
                                        state.mediaPlaylist.mediaItems.map((e) {
                                      return SongCardWidget(
                                        song: e,
                                        onTap: () {
                                          context
                                              .read<ElythraPlayerCubit>()
                                              .bloomeePlayer
                                              .updateQueue(
                                            [e],
                                            doPlay: true,
                                          );
                                        },
                                        onOptionsTap: () =>
                                            showMoreBottomSheet(context, e),
                                      );
                                    }).toList(),
                                    category: "Recently",
                                    columnSize: 3,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          if (state.lFMPicks) {
                            return FutureBuilder(
                                future: fetchLFMPicks(state.lFMPicks, context),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      (snapshot.data?.mediaItems.isNotEmpty ?? false)) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 15.0),
                                      child: TabSongListWidget(
                                          list: snapshot.data!.mediaItems
                                              .map((e) {
                                            return SongCardWidget(
                                              song: e,
                                              onTap: () {
                                                context
                                                    .read<ElythraPlayerCubit>()
                                                    .bloomeePlayer
                                                    .loadPlaylist(
                                                      MediaPlaylist(
                                                        name: snapshot.data!.playlistName,
                                                        items: snapshot.data!.mediaItems.map((item) => 
                                                          ElythraMediaItem.fromMediaItemModel(item)).toList(),
                                                      ),
                                                    );
                                              },
                                              onOptionsTap: () =>
                                                  showMoreBottomSheet(
                                                      context, e),
                                            );
                                          }).toList(),
                                          category: "Last.Fm Picks",
                                          columnSize: 3),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                });
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      BlocBuilder<YTMusicCubit, YTMusicCubitState>(
                        builder: (context, state) {
                          if (state is YTMusicCubitInitial) {
                            return BlocBuilder<ConnectivityCubit,
                                ConnectivityState>(
                              builder: (context, state2) {
                                if (state2 == ConnectivityState.disconnected) {
                                  return const SignBoardWidget(
                                    message: "No Internet Connection!",
                                    icon: MingCute.wifi_off_line,
                                  );
                                }
                                return const SizedBox();
                              },
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemExtent: 275,
                            padding: const EdgeInsets.only(top: 0),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.ytmData["body"]!.length,
                            itemBuilder: (context, index) {
                              return HorizontalCardView(
                                  data: state.ytmData["body"]![index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          backgroundColor: DefaultTheme.themeColor,
        ),
      ),
    );
  }
}

class CustomDiscoverBar extends StatelessWidget {
  const CustomDiscoverBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      surfaceTintColor: DefaultTheme.themeColor,
      backgroundColor: DefaultTheme.themeColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Discover",
              style: DefaultTheme.primaryTextStyle.merge(const TextStyle(
                  fontSize: 34, color: DefaultTheme.primaryColor1))),
          const Spacer(),
          const NotificationIcon(),
          const TimerIcon(),
          const SettingsIcon(),
        ],
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationInitial || state.notifications.isEmpty) {
          return IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationView()));
            },
            icon: const Icon(MingCute.notification_line,
                color: DefaultTheme.primaryColor1, size: 30.0),
          );
        }
        return badges.Badge(
          badgeContent: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Text(
              state.notifications.length.toString(),
              style: DefaultTheme.primaryTextStyle.merge(const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: DefaultTheme.primaryColor2)),
            ),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: DefaultTheme.accentColor2,
            shape: badges.BadgeShape.circle,
          ),
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          child: IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationView()));
            },
            icon: const Icon(MingCute.notification_line,
                color: DefaultTheme.primaryColor1, size: 30.0),
          ),
        );
      },
    );
  }
}

class TimerIcon extends StatelessWidget {
  const TimerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const TimerView()));
      },
      icon: const Icon(MingCute.stopwatch_line,
          color: DefaultTheme.primaryColor1, size: 30.0),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingsView()));
      },
      icon: const Icon(MingCute.settings_3_line,
          color: DefaultTheme.primaryColor1, size: 30.0),
    );
  }
}
