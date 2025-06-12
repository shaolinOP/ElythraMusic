// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:just_audio/just_audio.dart';

class ElythraPlayerState {
  bool isReady;
  bool showLyrics;
  ElythraPlayerState({required this.isReady, this.showLyrics = false});
}

final class ElythraPlayerInitial extends ElythraPlayerState {
  ElythraPlayerInitial() : super(isReady: false);
}

class ProgressBarStreams {
  late Duration currentPos;
  late PlaybackEvent currentPlaybackState;
  late PlayerState currentPlayerState;
  ProgressBarStreams({
    required this.currentPos,
    required this.currentPlaybackState,
    required this.currentPlayerState,
  });
}
