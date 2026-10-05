import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/reel_video_controller.dart';
import 'reels_event.dart';
import 'reels_state.dart';

/// Drives a reels pager: owns the [ReelVideoController] lifecycle for the
/// currently visible video plus a one-ahead/two-behind window, so playback
/// starts instantly when the user swipes and far-off controllers are freed.
class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  ReelsBloc() : super(const ReelsState()) {
    on<LoadReels>(_onLoadReels);
    on<AppendReels>(_onAppendReels);
    on<ChangePage>(_onChangePage);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<ToggleMute>(_onToggleMute);
    on<DisposeAllReels>(_onDisposeAll);
  }

  Future<void> _onLoadReels(LoadReels event, Emitter<ReelsState> emit) async {
    for (final controller in state.controllers.values) {
      controller.dispose();
    }

    final index = event.initialIndex;
    final controllers = <int, ReelVideoController>{};

    emit(state.copyWith(
      videos: event.videos,
      currentIndex: index,
      controllers: controllers,
    ));

    if (event.videos.isEmpty) return;

    await _initializeAt(index, controllers, autoPlay: true);
    await _initializeAt(index + 1, controllers, autoPlay: false);

    emit(state.copyWith(controllers: Map.of(controllers)));
  }

  void _onAppendReels(AppendReels event, Emitter<ReelsState> emit) {
    if (event.videos.isEmpty) return;
    emit(state.copyWith(videos: [...state.videos, ...event.videos]));
  }

  Future<void> _onChangePage(ChangePage event, Emitter<ReelsState> emit) async {
    final index = event.index;
    final previous = state.currentIndex;
    final controllers = Map<int, ReelVideoController>.of(state.controllers);

    if (index > previous) {
      _disposeAt(index - 2, controllers);
      _pauseAt(index - 1, controllers);
    } else if (index < previous) {
      _disposeAt(index + 2, controllers);
      _pauseAt(index + 1, controllers);
    }

    emit(state.copyWith(currentIndex: index, controllers: Map.of(controllers)));

    if (controllers.containsKey(index)) {
      controllers[index]?.play();
    } else {
      await _initializeAt(index, controllers, autoPlay: true);
    }

    final lookahead = index > previous ? index + 1 : index - 1;
    await _initializeAt(lookahead, controllers, autoPlay: false);

    emit(state.copyWith(controllers: Map.of(controllers)));
  }

  void _onTogglePlayPause(TogglePlayPause event, Emitter<ReelsState> emit) {
    final controller = state.controllers[state.currentIndex];
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    emit(state.copyWith(controllers: Map.of(state.controllers)));
  }

  void _onToggleMute(ToggleMute event, Emitter<ReelsState> emit) {
    final muted = !state.muted;
    state.controllers[state.currentIndex]?.setVolume(muted ? 0 : 1);
    emit(state.copyWith(muted: muted));
  }

  Future<void> _onDisposeAll(DisposeAllReels event, Emitter<ReelsState> emit) async {
    for (final controller in state.controllers.values) {
      controller.dispose();
    }
    emit(const ReelsState());
  }

  Future<void> _initializeAt(
    int index,
    Map<int, ReelVideoController> controllers, {
    required bool autoPlay,
  }) async {
    if (index < 0 || index >= state.videos.length) return;
    if (controllers.containsKey(index)) return;

    final video = state.videos[index];
    final controller = ReelVideoController(
      url: video.url,
      autoPlay: autoPlay,
      loop: video.loop,
      muted: state.muted,
    );
    controllers[index] = controller;
    await controller.initialize();
  }

  void _pauseAt(int index, Map<int, ReelVideoController> controllers) {
    final controller = controllers[index];
    if (controller == null) return;
    controller.pause();
    controller.seekTo(Duration.zero);
  }

  void _disposeAt(int index, Map<int, ReelVideoController> controllers) {
    final controller = controllers.remove(index);
    controller?.dispose();
  }

  @override
  Future<void> close() {
    for (final controller in state.controllers.values) {
      controller.dispose();
    }
    return super.close();
  }
}
