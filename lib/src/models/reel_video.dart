import 'package:equatable/equatable.dart';

/// A single video entry to render inside a reels pager.
class ReelVideo extends Equatable {
  const ReelVideo({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.loop = true,
  });

  /// Unique identifier for this video. Used as a cache key only — the
  /// package never fetches anything, it just plays [url].
  final String id;

  /// Direct, playable network URL for the video (mp4, m3u8, ...).
  final String url;

  /// Optional thumbnail shown while the video is initializing.
  final String? thumbnailUrl;

  /// Whether the video should loop when it reaches the end.
  final bool loop;

  @override
  List<Object?> get props => [id, url, thumbnailUrl, loop];
}
