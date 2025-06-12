import 'package:elythra_music/core/blocs/library/cubit/library_items_cubit.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart' as player;
import 'package:elythra_music/core/blocs/offline/offline_cubit.dart';
import 'package:elythra_music/core/model/MediaPlaylistModel.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider(
        create: (context) =>
            OfflineCubit(libraryItemsCubit: context.read<LibraryItemsCubit>()),
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              customDiscoverBar(context), //AppBar
              SliverList(
                  delegate: SliverChildListDelegate([
                BlocBuilder<OfflineCubit, OfflineState>(
                    builder: (context, state) {
                  if (state is OfflineInitial) {
                    return const CircularProgressIndicator();
                  } else if (state is OfflineEmpty) {
                    return const SignBoardWidget(
                      message: "No Downloads",
                      icon: FontAwesome.download_solid,
                    );
                  } else {
                    return Column(
                      children: state.songs
                          .map((e) => SongCardWidget(
                                song: e,
                                showOptions: true,
                                delDownBtn: true,
                                onTap: () {
                                  context
                                      .read<player.ElythraPlayerCubit>()
                                      .bloomeePlayer
                                      .loadPlaylist(
                                          player.MediaPlaylist(
                                              name: "Offline",
                                              items: state.songs.map((item) => player.ElythraMediaItem.fromMediaItemModel(item)).toList()));
                                },
                                onOptionsTap: () {
                                  showMoreBottomSheet(context, e,
                                      showDelete: false);
                                },
                              ))
                          .toList(),
                    );
                  }
                })
              ]))
            ],
          ),
          backgroundColor: Default_Theme.themeColor,
        ),
      ),
    );
  }

  SliverAppBar customDiscoverBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      surfaceTintColor: Default_Theme.themeColor,
      backgroundColor: Default_Theme.themeColor,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Offline",
              style: Default_Theme.primaryTextStyle.merge(const TextStyle(
                  fontSize: 34, color: Default_Theme.primaryColor1))),
          const Spacer(),
          // IconButton(
          //     onPressed: () {
          //       context.read<OfflineCubit>().getSongs();
          //     },
          //     icon: const Icon(MingCute.refresh_1_line)),
        ],
      ),
    );
  }
}
