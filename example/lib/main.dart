import 'package:flutter/material.dart';
import 'package:flutter_reels_video/flutter_reels_video.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ReelsFeedPage());
  }
}

/// Stand-in for your real paginated reels API.
/// Swap this for your Dio/http call — it just needs to return a page of
/// [ReelVideo] given a page number.
///
/// URLs below are Google's public sample video bucket, so the example
/// actually plays something when you run it.
class FakeReelsApi {
  static const pageSize = 4;
  static const totalPages = 2;

  static const _sampleUrls = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
  ];

  Future<List<ReelVideo>> fetchPage(int page) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
    if (page > totalPages) return [];
    return List.generate(pageSize, (i) {
      final n = (page - 1) * pageSize + i;
      return ReelVideo(
        id: 'video_$n',
        url: _sampleUrls[n % _sampleUrls.length],
      );
    });
  }
}

class ReelsFeedPage extends StatefulWidget {
  const ReelsFeedPage({super.key});

  @override
  State<ReelsFeedPage> createState() => _ReelsFeedPageState();
}

class _ReelsFeedPageState extends State<ReelsFeedPage> {
  final _api = FakeReelsApi();

  // IMPORTANT: always reassign with a NEW list (`[...old, ...more]`), never
  // `_videos.addAll(more)`. ReelsPagerView detects "append vs. full reset"
  // by comparing the old/new list instance + prefix, so mutating in place
  // means it never sees a change.
  List<ReelVideo> _videos = [];

  int _nextPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNextPage(); // fetch page 1 up front
  }

  Future<void> _loadNextPage() async {
    // dedupe guard — package doesn't do this for you
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;

    final page = await _api.fetchPage(_nextPage);
    _nextPage++;

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (page.isEmpty) {
        _hasMore = false;
      } else {
        _videos = [..._videos, ...page];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ReelsPagerView(
        videos: _videos,
        loadMoreThreshold: 2, // fire onLoadMore 2 pages before the end
        onLoadMore: _loadNextPage,
      ),
    );
  }
}
