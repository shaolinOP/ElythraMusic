import 'package:elythra_music/core/blocs/library/cubit/library_items_cubit.dart';
import 'package:elythra_music/core/routes_and_consts/global_str_consts.dart';
import 'package:elythra_music/features/player/screens/widgets/sign_board_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:elythra_music/core/blocs/add_to_playlist/cubit/add_to_playlist_cubit.dart';
import 'package:elythra_music/core/model/song_model.dart';
import 'package:elythra_music/features/player/screens/widgets/create_playlist_bottomsheet.dart';
import 'package:elythra_music/features/player/screens/widgets/libitem_tile.dart';
import 'package:elythra_music/core/services/db/global_db.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/routes_and_consts/global_conts.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:icons_plus/icons_plus.dart';

class AddToPlaylistScreen extends StatefulWidget {
  const AddToPlaylistScreen({super.key});

  @override
  State<AddToPlaylistScreen> createState() => AddToPlaylistScreenStateState();
}

class AddToPlaylistScreenStateState extends State<AddToPlaylistScreen> {
  List<PlaylistItemProperties> playlistsItems = List.empty(growable: true);

  List<PlaylistItemProperties> filteredPlaylistsItems =
      List.empty(growable: true);
  final TextEditingController _searchController = TextEditingController();

  Future<void> searchFilter(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        filteredPlaylistsItems = playlistsItems.where((element) {
          return element.playlistName
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      });
    } else {
      setState(() {
        filteredPlaylistsItems = playlistsItems;
      });
    }
  }

  MediaItemModel currentMediaModel = mediaItemModelNull;
  @override
  Widget build(BuildContext context) {
    // context.read<AddToPlaylistCubit>().getAndEmitPlaylists();
    return Scaffold(
      backgroundColor: DefaultTheme.themeColor,
      appBar: AppBar(
        backgroundColor: DefaultTheme.themeColor,
        foregroundColor: DefaultTheme.primaryColor1,
        centerTitle: true,
        title: Text(
          'Add to Playlist',
          style: const TextStyle(
                  color: DefaultTheme.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
              .merge(DefaultTheme.secondoryTextStyle),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<AddToPlaylistCubit, AddToPlaylistState>(
            builder: (context, state) {
              if (state is AddToPlaylistInitial) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: DefaultTheme.accentColor2,
                ));
              } else {
                if (state.mediaItemModel != mediaItemModelNull) {
                  currentMediaModel = state.mediaItemModel;
                  return Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: LoadImageCached(
                                    imageUrl:
                                        state.mediaItemModel.artUri.toString()),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Text(
                                      state.mediaItemModel.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: DefaultTheme.secondoryTextStyle
                                          .merge(const TextStyle(
                                              color:
                                                  DefaultTheme.primaryColor2,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17)),
                                    ),
                                  ),
                                  Text(
                                    state.mediaItemModel.artist ?? "Unknown",
                                    maxLines: 2,
                                    textAlign: TextAlign.start,
                                    overflow: TextOverflow.ellipsis,
                                    style: DefaultTheme.secondoryTextStyle
                                        .merge(TextStyle(
                                            color: DefaultTheme.primaryColor2
                                                .withOpacity(0.5),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(
                        color: DefaultTheme.accentColor2,
                        thickness: 3,
                        height: 20,
                      ),
                    ],
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                searchFilter(value.toString());
              },
              style: TextStyle(
                  color: DefaultTheme.primaryColor1.withOpacity(0.55)),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: DefaultTheme.primaryColor2.withOpacity(0.07),
                  contentPadding: const EdgeInsets.only(top: 20, left: 15),
                  hintText: "Search you playlist..",
                  hintStyle: TextStyle(
                      color: DefaultTheme.primaryColor1.withOpacity(0.4),
                      fontFamily: "Gilroy"),
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(style: BorderStyle.none),
                      borderRadius: BorderRadius.circular(50)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: DefaultTheme.primaryColor1.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(50))),
            ),
          ),
          Expanded(
            child: BlocBuilder<LibraryItemsCubit, LibraryItemsState>(
              builder: (context, state) {
                if (state is LibraryItemsInitial) {
                  return const SignBoardWidget(
                      message: "No Playlists Yet",
                      icon: MingCute.playlist_line);
                } else {
                  playlistsItems = state.playlists;
                  final finalList = filteredPlaylistsItems.isEmpty ||
                          _searchController.text.isEmpty
                      ? playlistsItems
                      : filteredPlaylistsItems;
                  return ListView.builder(
                    itemCount: finalList.length,
                    itemBuilder: (context, index) {
                      if (finalList[index].playlistName == "recently_played" ||
                          finalList[index].playlistName ==
                              GlobalStrConsts.downloadPlaylist) {
                        return const SizedBox();
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, left: 10),
                          child: InkWell(
                            child: LibItemCard(
                                onTap: () {
                                  if (currentMediaModel != mediaItemModelNull) {
                                    context
                                        .read<LibraryItemsCubit>()
                                        .addToPlaylist(
                                            currentMediaModel,
                                            MediaPlaylistDB(
                                              playlistName:
                                                  finalList[index].playlistName,
                                            ));
                                    context.pop(context);
                                  }
                                },
                                title: finalList[index].playlistName,
                                coverArt:
                                    finalList[index].coverImgUrl ?? "null",
                                subtitle:
                                    finalList[index].subTitle ?? "Unverified"),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        icon: const Icon(
          MingCute.add_fill,
          size: 25,
          color: DefaultTheme.primaryColor1,
        ),
        onPressed: () {
          createPlaylistBottomSheet(context);
        },
        label: Text(
          "Create New Playlist",
          style: DefaultTheme.secondoryTextStyle.merge(const TextStyle(
              color: DefaultTheme.primaryColor1,
              fontWeight: FontWeight.bold,
              fontSize: 15)),
        ),
      ),
    );
  }
}
