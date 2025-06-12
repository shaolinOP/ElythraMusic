import 'package:elythra_music/core/model/album_onl_model.dart';
import 'package:elythra_music/features/player/screens/screen/common_views/album_view.dart';
import 'package:elythra_music/core/theme_data/default.dart';
import 'package:elythra_music/core/utils/imgurl_formator.dart';
import 'package:elythra_music/core/utils/load_image.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final ValueNotifier<bool> hovering = ValueNotifier(false);
  AlbumCard({
    super.key,
    required this.album,
  });

  void setHovering(bool isHovering) {
    hovering.toARGB32 = isHovering;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          top: 10,
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            width: ResponsiveBreakpoints.of(context).isMobile
                ? constraints.maxWidth * 0.9
                : 220,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AlbumView(
                            album: album,
                          )),
                );
              },
              child: MouseRegion(
                onEnter: (event) {
                  setHovering(true);
                },
                onExit: (event) {
                  setHovering(false);
                },
                child: Card(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        child: Hero(
                          tag: album.sourceId,
                          child: Stack(
                            children: [
                              LoadImageCached(
                                imageUrl: formatImgURL(
                                    album.imageURL, ImageQuality.medium),
                              ),
                              ValueListenableBuilder(
                                valueListenable: hovering,
                                builder: (context, child, value) {
                                  return Positioned.fill(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      color: hovering.toARGB32
                                          ? Colors.black.withOpacity(0.5)
                                          : Colors.transparent,
                                      child: Center(
                                        child: AnimatedOpacity(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          opacity: hovering.toARGB32 ? 1 : 0,
                                          child: const Icon(
                                            MingCute.play_circle_line,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                        ),
                        child: Text(
                          album.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: DefaultTheme.secondoryTextStyleMedium
                              .merge(TextStyle(
                            fontSize: 14,
                            color: DefaultTheme.primaryColor1.withOpacity(0.9),
                          )),
                        ),
                      ),
                      Text(album.artists,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: DefaultTheme.secondoryTextStyleMedium
                              .merge(TextStyle(
                            fontSize: 12,
                            color: DefaultTheme.primaryColor1.withOpacity(0.7),
                            overflow: TextOverflow.ellipsis,
                          ))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }));
  }
}
