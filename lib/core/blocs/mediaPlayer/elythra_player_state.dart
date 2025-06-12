part of 'elythra_player_cubit.dart';

class ElythraPlayerState {
  final bool isReady;
  final bool showLyrics;

  const ElythraPlayerState({
    this.isReady = false,
    this.showLyrics = false,
  });
}

class ElythraPlayerInitial extends ElythraPlayerState {}

class ElythraPlayerReady extends ElythraPlayerState {
  const ElythraPlayerReady({
    super.isReady = true,
    super.showLyrics = false,
  });
}