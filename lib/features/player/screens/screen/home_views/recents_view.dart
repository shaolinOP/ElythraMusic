// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:elythra_music/core/blocs/history/cubit/history_cubit.dart';
import 'package:elythra_music/core/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:elythra_music/features/player/screens/screen/home_views/setting_views/storage_setting.dart';
import 'package:elythra_music/features/player/screens/widgets/more_bottom_sheet.dart';
import 'package:elythra_music/features/player/screens/widgets/song_tile.dart';
import 'package:flutter/material.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Default_Theme.themeColor,
        appBar: AppBar(
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                MingCute.settings_1_line,
                color: Default_Theme.primaryColor1,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackupSettings(),
                  ),
                );
              },
            ),
          ],
          backgroundColor: Default_Theme.themeColor,
          surfaceTintColor: Default_Theme.themeColor,
          foregroundColor: Default_Theme.primaryColor1,
          title: Text(
            'History',
            style: const TextStyle(
                    color: Default_Theme.primaryColor1,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)
                .merge(Default_Theme.secondoryTextStyle),
          ),
        ),
        body: BlocProvider(
          create: (context) => HistoryCubit(),
          child: BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              return (state is HistoryInitial)
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: state.mediaPlaylist.mediaItems.length,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return SongCardWidget(
                          song: state.mediaPlaylist.mediaItems[index],
                          onTap: () {
                            context
                                .read<ElythraPlayerCubit>()
                                .bloomeePlayer
                                .addQueueItem(
                                  state.mediaPlaylist.mediaItems[index],
                                );
                          },
                          onOptionsTap: () => showMoreBottomSheet(
                              context, state.mediaPlaylist.mediaItems[index]),
                        );
                      },
                    );
            },
          ),
        ),
      ),
    );
  }

  ListTile settingListTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        size: 30,
        color: Default_Theme.primaryColor1,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Default_Theme.primaryColor1, fontSize: 17)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
                color: Default_Theme.primaryColor1.withOpacity(0.5),
                fontSize: 12.5)
            .merge(Default_Theme.secondoryTextStyleMedium),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
