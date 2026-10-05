import 'package:equatable/equatable.dart';

import '../controller/reel_video_controller.dart';
import '../models/reel_video.dart';

/// Snapshot of what [ReelsPagerView] should render: the video list, which
/// index is focused, the live controllers for the current window, and mute.
class ReelsState extends Equatable {
  const ReelsState({
    this.videos = const [],
    this.currentIndex = 0,
    this.controllers = const {},
    this.muted = false,
  });

  final List<ReelVideo> videos;
  final int currentIndex;

  /// Controllers keyed by index, for the current page plus its small
  /// look-ahead/look-behind window.
  final Map<int, ReelVideoController> controllers;
  final bool muted;

  ReelsState copyWith({
    List<ReelVideo>? videos,
    int? currentIndex,
    Map<int, ReelVideoController>? controllers,
    bool? muted,
  }) {
    return ReelsState(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
      controllers: controllers ?? this.controllers,
      muted: muted ?? this.muted,
    );
  }

  @override
  List<Object?> get props => [videos, currentIndex, controllers, muted];
}
