import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../controller/reel_video_controller.dart';
import '../models/reel_video.dart';

class ReelsPagerView extends StatefulWidget {
  const ReelsPagerView({
    super.key,
    required this.videos,
    this.initialIndex = 0,
    this.placeholderBuilder,
    this.onLoadMore,
    this.loadMoreThreshold = 3,
  });

  final List<ReelVideo> videos;

  final int initialIndex;

  final Widget Function(BuildContext context, ReelVideo video)?
      placeholderBuilder;

  final VoidCallback? onLoadMore;

  final int loadMoreThreshold;

  @override
  State<ReelsPagerView> createState() => _ReelsPagerViewState();
}

class _ReelsPagerViewState extends State<ReelsPagerView> {
  late final PageController _pageController;

  final Map<int, ReelVideoController> _controllers = {};

  late int _currentIndex;
  final bool _muted = false;
  int? _loadMoreRequestedAtLength;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _resetPlayback(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant ReelsPagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_listEquals(oldWidget.videos, widget.videos)) return;

    if (_isAppend(oldWidget.videos, widget.videos)) {
      _maybeRequestLoadMore();
    } else {
      _resetPlayback(widget.initialIndex);
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

  Future<void> _resetPlayback(int index) async {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _loadMoreRequestedAtLength = null;

    setState(() => _currentIndex = index);
    if (widget.videos.isEmpty) return;

    await _initializeAt(index, autoPlay: true);
    await _initializeAt(index + 1, autoPlay: false);
    if (mounted) setState(() {});
    _maybeRequestLoadMore();
  }

  Future<void> _onPageChanged(int index) async {
    final previous = _currentIndex;

    if (index > previous) {
      _disposeAt(index - 2);
      _pauseAt(index - 1);
    } else if (index < previous) {
      _disposeAt(index + 2);
      _pauseAt(index + 1);
    }

    setState(() => _currentIndex = index);
    _maybeRequestLoadMore();

    if (_controllers.containsKey(index)) {
      _controllers[index]?.play();
    } else {
      await _initializeAt(index, autoPlay: true);
    }

    final lookahead = index > previous ? index + 1 : index - 1;
    await _initializeAt(lookahead, autoPlay: false);

    if (mounted) setState(() {});
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  void _maybeRequestLoadMore() {
    final onLoadMore = widget.onLoadMore;
    if (onLoadMore == null || widget.videos.isEmpty) return;

    final remaining = widget.videos.length - 1 - _currentIndex;
    if (remaining <= widget.loadMoreThreshold &&
        _loadMoreRequestedAtLength != widget.videos.length) {
      _loadMoreRequestedAtLength = widget.videos.length;
      onLoadMore();
    }
  }

  Future<void> _initializeAt(int index, {required bool autoPlay}) async {
    if (index < 0 || index >= widget.videos.length) return;
    if (_controllers.containsKey(index)) return;

    final video = widget.videos[index];
    final controller = ReelVideoController(
      url: video.url,
      autoPlay: autoPlay,
      loop: video.loop,
      muted: _muted,
    );
    _controllers[index] = controller;
    await controller.initialize();
  }

  void _pauseAt(int index) {
    final controller = _controllers[index];
    if (controller == null) return;
    controller.pause();
    controller.seekTo(Duration.zero);
  }

  void _disposeAt(int index) {
    final controller = _controllers.remove(index);
    controller?.dispose();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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
    if (widget.videos.isEmpty) return const SizedBox.shrink();
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      pageSnapping: true,
      itemCount: widget.videos.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        final controller = index == _currentIndex ? _controllers[index] : null;
        return _ReelItem(
          video: video,
          controller: controller,
          placeholder: _placeholder(context, video),
          onTap: _togglePlayPause,
        );
      },
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
                        const Icon(Icons.play_arrow,
                            size: 72, color: Colors.white70),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
