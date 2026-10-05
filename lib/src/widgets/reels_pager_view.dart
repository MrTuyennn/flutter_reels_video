import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../bloc/reels_bloc.dart';
import '../bloc/reels_event.dart';
import '../bloc/reels_state.dart';
import '../controller/reel_video_controller.dart';
import '../models/reel_video.dart';

/// Vertical, swipeable video reels. Pass in [videos] — paging, preloading,
/// playback and mute state are all handled internally.
class ReelsPagerView extends StatefulWidget {
  const ReelsPagerView({
    super.key,
    required this.videos,
    this.initialIndex = 0,
    this.placeholderBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 3,
  });

  /// The videos to render, one per page. Pass a longer list later (same
  /// prefix) to append without resetting playback; pass a different list to
  /// fully reset to a new feed.
  final List<ReelVideo> videos;

  /// Which page to show first.
  final int initialIndex;

  /// Shown for a page while its video is not yet initialized. Defaults to
  /// the video's [ReelVideo.thumbnailUrl], or a black background.
  final Widget Function(BuildContext context, ReelVideo video)? placeholderBuilder;

  /// Called once when the viewer gets within [loadMoreThreshold] pages of
  /// the end of [videos] — fetch your next page here and pass a longer
  /// [videos] list back in (same items + appended ones) to extend the pager
  /// in place, without resetting playback position.
  final VoidCallback? onLoadMore;

  /// How many pages before the end of the list [onLoadMore] fires.
  final int loadMoreThreshold;

  @override
  State<ReelsPagerView> createState() => _ReelsPagerViewState();
}

class _ReelsPagerViewState extends State<ReelsPagerView> {
  late final ReelsBloc _bloc;
  late final PageController _pageController;
  int? _loadMoreRequestedAtLength;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _bloc = ReelsBloc()..add(LoadReels(widget.videos, initialIndex: widget.initialIndex));
  }

  @override
  void didUpdateWidget(covariant ReelsPagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_listEquals(oldWidget.videos, widget.videos)) return;

    if (_isAppend(oldWidget.videos, widget.videos)) {
      // Same items up front, just extended — keep position & controllers.
      _bloc.add(AppendReels(widget.videos.sublist(oldWidget.videos.length)));
    } else {
      // A genuinely different list (new feed/category) — full reset.
      _loadMoreRequestedAtLength = null;
      _bloc.add(LoadReels(widget.videos, initialIndex: widget.initialIndex));
    }
  }

  bool _listEquals(List<ReelVideo> a, List<ReelVideo> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isAppend(List<ReelVideo> oldList, List<ReelVideo> newList) {
    if (newList.length <= oldList.length) return false;
    for (var i = 0; i < oldList.length; i++) {
      if (oldList[i] != newList[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bloc.close();
    super.dispose();
  }

  Widget _placeholder(BuildContext context, ReelVideo video) {
    if (widget.placeholderBuilder != null) {
      return widget.placeholderBuilder!(context, video);
    }
    if (video.thumbnailUrl != null) {
      return Image.network(video.thumbnailUrl!, fit: BoxFit.cover);
    }
    return const ColoredBox(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ReelsBloc, ReelsState>(
        listenWhen: (previous, current) =>
            widget.onLoadMore != null &&
            (previous.currentIndex != current.currentIndex ||
                previous.videos.length != current.videos.length),
        listener: (context, state) {
          if (state.videos.isEmpty) return;
          final remaining = state.videos.length - 1 - state.currentIndex;
          if (remaining <= widget.loadMoreThreshold &&
              _loadMoreRequestedAtLength != state.videos.length) {
            _loadMoreRequestedAtLength = state.videos.length;
            widget.onLoadMore!();
          }
        },
        child: BlocBuilder<ReelsBloc, ReelsState>(
          builder: (context, state) {
            if (state.videos.isEmpty) return const SizedBox.shrink();
            return PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              pageSnapping: true,
              itemCount: state.videos.length,
              onPageChanged: (index) => _bloc.add(ChangePage(index)),
              itemBuilder: (context, index) {
                final video = state.videos[index];
                final controller = index == state.currentIndex ? state.controllers[index] : null;
                return _ReelItem(
                  video: video,
                  controller: controller,
                  placeholder: _placeholder(context, video),
                  onTap: () => _bloc.add(const TogglePlayPause()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  const _ReelItem({
    required this.video,
    required this.controller,
    required this.placeholder,
    required this.onTap,
  });

  final ReelVideo video;
  final ReelVideoController? controller;
  final Widget placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: activeController == null || !activeController.value.isInitialized
            ? placeholder
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: activeController,
                builder: (context, value, _) {
                  return Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: value.size.width,
                          height: value.size.height,
                          child: VideoPlayer(activeController),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: VideoProgressIndicator(
                          activeController,
                          allowScrubbing: true,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      if (!value.isPlaying)
                        const Icon(Icons.play_arrow, size: 72, color: Colors.white70),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
