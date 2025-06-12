import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:elythra_music/features/lyrics/lyrics_cubit.dart';
import 'package:elythra_music/features/player/blocs/mediaPlayer/bloomee_player_cubit.dart';

class EnhancedLyricsWidget extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final bool isFullScreen;

  const EnhancedLyricsWidget({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.isFullScreen = false,
  });

  @override
  State<EnhancedLyricsWidget> createState() => _EnhancedLyricsWidgetState();
}

class _EnhancedLyricsWidgetState extends State<EnhancedLyricsWidget> {
  bool _showSyncedLyrics = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsCubit, LyricsState>(
      builder: (context, lyricsState) {
        return BlocBuilder<ElythraPlayerCubit, ElythraPlayerState>(
          builder: (context, playerState) {
            if (lyricsState is LyricsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (lyricsState is LyricsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lyrics not available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (lyricsState is! LyricsLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lyrics,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No lyrics loaded',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final lyrics = lyricsState.lyrics;
            final hasPlainLyrics = lyrics.lyricsPlain.isNotEmpty &&
                                   lyrics.lyricsPlain != "No Lyrics Found";
            final hasSyncedLyrics = lyrics.parsedLyrics != null && 
                                    lyrics.parsedLyrics!.lyrics.isNotEmpty;

            if (!hasPlainLyrics && !hasSyncedLyrics) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No lyrics found for this song',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Lyrics mode toggle
                if (hasPlainLyrics && hasSyncedLyrics)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Plain'),
                              icon: Icon(Icons.text_fields),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Synced'),
                              icon: Icon(Icons.sync),
                            ),
                          ],
                          selected: {_showSyncedLyrics},
                          onSelectionChanged: (Set<bool> selection) {
                            setState(() {
                              _showSyncedLyrics = selection.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Lyrics content
                Expanded(
                  child: _showSyncedLyrics && hasSyncedLyrics
                      ? _buildSyncedLyrics(lyrics.parsedLyrics!, playerState)
                      : _buildPlainLyrics(lyrics.lyricsPlain),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSyncedLyrics(ParsedLyrics parsedLyrics, ElythraPlayerState playerState) {
    // Get current position from player state
    Duration currentPosition = Duration.zero;
    if (playerState is ElythraPlayerPlaying) {
      // You'll need to implement getting current position from the player state
      // This is a placeholder - you'll need to adapt based on your player implementation
    }

    try {
      // Convert ParsedLyrics to string format for LyricsReader
      final lyricsString = parsedLyrics.lyrics
          .map((line) => '[${line.start.inMilliseconds}]${line.text}')
          .join('\n');
      
      return LyricsReader(
        padding: widget.padding as EdgeInsets?,
        model: LyricsModelBuilder.create()
            .bindLyricToMain(lyricsString)
            .getModel(),
        position: currentPosition.inMilliseconds,
        lyricUi: UINetease(),
        playing: playerState is ElythraPlayerPlaying,
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height * 0.6,
        ),
        emptyBuilder: () => Center(
          child: Text(
            'No synced lyrics available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback to plain lyrics if synced lyrics parsing fails
      final plainText = parsedLyrics.lyrics.map((line) => line.text).join('\n');
      return _buildPlainLyrics(plainText);
    }
  }

  Widget _buildPlainLyrics(String plainLyrics) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: widget.padding,
      child: SelectableText(
        plainLyrics.isEmpty ? 'No lyrics available' : plainLyrics,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.8,
          color: widget.isFullScreen 
              ? Colors.white 
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}

// Custom UI for synced lyrics (inspired by Harmony-Music)
class UINetease extends LyricUI {
  @override
  TextStyle getPlayingMainTextStyle() => const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  @override
  TextStyle getOtherMainTextStyle() => TextStyle(
    color: Colors.white.withOpacity(0.6),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  @override
  TextStyle getPlayingExtTextStyle() => const TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
    color: Colors.white.withOpacity(0.4),
    fontSize: 12,
  );

  @override
  double getInlineSpace() => 8;

  @override
  double getLineSpace() => 12;

  @override
  double getPlayingLineBias() => 0.5;

  Offset getBiasOffset() => const Offset(0, 0);

  @override
  LyricAlign getLyricHorizontalAlign() => LyricAlign.CENTER;
}