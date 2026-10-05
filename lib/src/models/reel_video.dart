import 'package:equatable/equatable.dart';

class ReelVideo extends Equatable {
  const ReelVideo({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.loop = true,
  });

  final String id;

  /// Direct, playable network URL for the video (mp4, m3u8, ...).
  final String url;

  final String? thumbnailUrl;

  final bool loop;

  @override
  List<Object?> get props => [id, url, thumbnailUrl, loop];
}
