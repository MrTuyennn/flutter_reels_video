import 'package:equatable/equatable.dart';

import '../models/reel_video.dart';

/// Base class for events consumed by [ReelsBloc].
abstract class ReelsEvent extends Equatable {
  const ReelsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or replace) the list of videos the pager should render.
class LoadReels extends ReelsEvent {
  const LoadReels(this.videos, {this.initialIndex = 0});

  final List<ReelVideo> videos;
  final int initialIndex;

  @override
  List<Object?> get props => [videos, initialIndex];
}

/// Append more videos to the end of the current list — e.g. the next page
/// from a paginated API. Unlike [LoadReels], this keeps [currentIndex] and
/// every already-initialized controller untouched.
class AppendReels extends ReelsEvent {
  const AppendReels(this.videos);

  final List<ReelVideo> videos;

  @override
  List<Object?> get props => [videos];
}

/// Fired when the PageView settles on a new page.
class ChangePage extends ReelsEvent {
  const ChangePage(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// Toggle play/pause on the currently focused video.
class TogglePlayPause extends ReelsEvent {
  const TogglePlayPause();
}

/// Mute/unmute the currently focused video.
class ToggleMute extends ReelsEvent {
  const ToggleMute();
}

/// Dispose every controller. Call when leaving the pager for good.
class DisposeAllReels extends ReelsEvent {
  const DisposeAllReels();
}
