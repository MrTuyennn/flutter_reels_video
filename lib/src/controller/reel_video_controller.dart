import 'package:video_player/video_player.dart';

class ReelVideoController extends VideoPlayerController {
  ReelVideoController({
    required this.url,
    this.autoPlay = false,
    this.loop = true,
    this.muted = false,
  }) : super.networkUrl(Uri.parse(url));

  /// Direct, playable network URL for the video.
  final String url;

  /// Whether to start playing as soon as the controller initializes.
  final bool autoPlay;

  /// Whether the video should loop when it reaches the end.
  final bool loop;

  /// Whether the video should start with volume muted.
  final bool muted;

  @override
  Future<void> initialize() async {
    if (value.isInitialized) return;

    value = value.copyWith(
      isPlaying: autoPlay,
      isLooping: loop,
      volume: muted ? 0 : 1,
    );

    await super.initialize();
  }
}
