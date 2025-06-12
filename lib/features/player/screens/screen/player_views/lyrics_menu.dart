import 'package:elythra_music/features/lyrics/lyrics_cubit.dart';
import 'package:elythra_music/features/player/screens/screen/player_views/lyrics_search.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/model/lyrics_models.dart' as lyrics_models;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class LyricsMenu extends StatefulWidget {
  final LyricsState state;
  const LyricsMenu({super.key, required this.state});

  @override
  State<LyricsMenu> createState() => LyricsMenuStateState();
}

class LyricsMenuStateState extends State<LyricsMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'LyricsMenu');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(
          Color.fromARGB(255, 27, 27, 27),
        ),
      ),
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate:
                  LyricsSearchDelegate(mediaID: widget.state.mediaItem.id),
              query:
                  "${widget.state.mediaItem.title} ${widget.state.mediaItem.artist}",
            );
          },
          child: const Row(
            children: <Widget>[
              Icon(
                MingCute.search_2_fill,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Search Lyrics',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            context
                .read<LyricsCubit>()
                .deleteLyricsFromDB(widget.state.mediaItem);
          },
          child: const Row(
            children: <Widget>[
              Icon(
                MingCute.delete_fill,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Reset Lyrics',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {
            context
                .read<LyricsCubit>()
                .setLyricsToDB(
                  lyrics_models.Lyrics(
                    id: widget.state.mediaItem.id,
                    artist: widget.state.mediaItem.artist,
                    title: widget.state.mediaItem.title,
                    lyricsPlain: widget.state.lyrics.lyricsPlain,
                    provider: lyrics_models.LyricsProvider.none,
                    mediaID: widget.state.mediaItem.id,
                  ), 
                  widget.state.mediaItem.id
                );
          },
          child: const Row(
            children: <Widget>[
              Icon(
                MingCute.save_2_fill,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Save Lyrics',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        // MenuItemButton(
        //   onPressed: () {
        //     showFloatingModalBottomSheet(
        //       context: context,
        //       builder: (context) {
        //         return Container();
        //       },
        //     );
        //   },
        //   child: const Row(
        //     children: <Widget>[
        //       Icon(
        //         MingCute.time_line,
        //         color: Colors.white,
        //         size: 18,
        //       ),
        //       SizedBox(width: 8),
        //       Text('Offset Lyrics',
        //           style: TextStyle(color: Colors.white, fontSize: 13)),
        //     ],
        //   ),
        // ),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return Tooltip(
          message: 'Lyrics Menu',
          child: IconButton(
            focusNode: _buttonFocusNode,
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(
              MingCute.settings_3_fill,
              size: 20,
            ),
            color: DefaultTheme.primaryColor1.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}
