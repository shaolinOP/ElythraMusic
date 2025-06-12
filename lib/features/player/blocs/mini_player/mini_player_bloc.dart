import 'package:flutter_bloc/flutter_bloc.dart';

// Mini Player States
abstract class MiniPlayerState {
  final bool isPlaying;
  
  const MiniPlayerState({this.isPlaying = false});
}

class MiniPlayerInitial extends MiniPlayerState {}

class MiniPlayerCompleted extends MiniPlayerState {
  const MiniPlayerCompleted({required bool isPlaying}) : super(isPlaying: isPlaying);
}

class MiniPlayerWorking extends MiniPlayerState {
  const MiniPlayerWorking({required bool isPlaying}) : super(isPlaying: isPlaying);
}

class MiniPlayerError extends MiniPlayerState {
  final String message;
  const MiniPlayerError(this.message);
}

class MiniPlayerProcessing extends MiniPlayerState {
  const MiniPlayerProcessing({required bool isPlaying}) : super(isPlaying: isPlaying);
}

// Mini Player Events
abstract class MiniPlayerEvent {}

class MiniPlayerPlay extends MiniPlayerEvent {}

class MiniPlayerPause extends MiniPlayerEvent {}

class MiniPlayerNext extends MiniPlayerEvent {}

class MiniPlayerPrevious extends MiniPlayerEvent {}

class MiniPlayerSeek extends MiniPlayerEvent {
  final Duration position;
  MiniPlayerSeek(this.position);
}

// Mini Player Bloc
class MiniPlayerBloc extends Bloc<MiniPlayerEvent, MiniPlayerState> {
  MiniPlayerBloc() : super(MiniPlayerInitial()) {
    on<MiniPlayerPlay>(_onPlay);
    on<MiniPlayerPause>(_onPause);
    on<MiniPlayerNext>(_onNext);
    on<MiniPlayerPrevious>(_onPrevious);
    on<MiniPlayerSeek>(_onSeek);
  }

  void _onPlay(MiniPlayerPlay event, Emitter<MiniPlayerState> emit) {
    emit(const MiniPlayerWorking(isPlaying: true));
    // Implement play logic
    emit(const MiniPlayerCompleted(isPlaying: true));
  }

  void _onPause(MiniPlayerPause event, Emitter<MiniPlayerState> emit) {
    emit(const MiniPlayerWorking(isPlaying: false));
    // Implement pause logic
    emit(const MiniPlayerCompleted(isPlaying: false));
  }

  void _onNext(MiniPlayerNext event, Emitter<MiniPlayerState> emit) {
    emit(const MiniPlayerProcessing(isPlaying: state.isPlaying));
    // Implement next track logic
    emit(MiniPlayerCompleted(isPlaying: state.isPlaying));
  }

  void _onPrevious(MiniPlayerPrevious event, Emitter<MiniPlayerState> emit) {
    emit(const MiniPlayerProcessing(isPlaying: state.isPlaying));
    // Implement previous track logic
    emit(MiniPlayerCompleted(isPlaying: state.isPlaying));
  }

  void _onSeek(MiniPlayerSeek event, Emitter<MiniPlayerState> emit) {
    emit(const MiniPlayerProcessing(isPlaying: state.isPlaying));
    // Implement seek logic
    emit(MiniPlayerCompleted(isPlaying: state.isPlaying));
  }
}