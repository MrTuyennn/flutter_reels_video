# reels_player

A minimal, reusable vertical video reels pager for Flutter — think
TikTok/Reels/Shorts scrolling. Pass in a list of videos and it handles
paging, autoplay, preloading the next video, pause/resume on tap, mute and
pagination for you.

Built on `PageView` for the scroll mechanics and `flutter_bloc` internally
to manage playback state — you don't need to know bloc to use it.

## Features

* Vertical, swipeable paging with snap-to-page.
* Autoplay on the focused page; the next page preloads one video ahead so
  playback starts instantly on swipe.
* Controllers outside the current window are disposed automatically to
  keep memory bounded on long feeds.
* Tap to play/pause.
* `onLoadMore` callback for paginated feeds — append new videos without
  losing scroll position or restarting playback.
* Customizable placeholder (thumbnail or your own widget) shown while a
  video initializes.

## Getting started

```yaml
dependencies:
  reels_player: ^0.0.1
```

## Usage

```dart
import 'package:reels_player/reels_player.dart';

ReelsPagerView(
  videos: const [
    ReelVideo(id: '1', url: 'https://example.com/video1.mp4'),
    ReelVideo(id: '2', url: 'https://example.com/video2.mp4'),
  ],
)
```

### Pagination

Fetch the next page when the viewer gets close to the end, then pass back
a **new** list — the existing items plus the appended ones. `ReelsPagerView`
detects an append (same prefix, longer list) and keeps playback position
and already-initialized controllers intact instead of doing a full reset.

```dart
ReelsPagerView(
  videos: _videos, // grows via setState(() => _videos = [..._videos, ...more])
  loadMoreThreshold: 3, // fire onLoadMore 3 pages before the end
  onLoadMore: _loadNextPage,
)
```

### Custom placeholder

```dart
ReelsPagerView(
  videos: _videos,
  placeholderBuilder: (context, video) => Image.network(
    video.thumbnailUrl ?? '',
    fit: BoxFit.cover,
  ),
)
```

See `example/` for a complete, runnable app using public sample videos.

## Additional information

Issues and contributions are welcome. This package only plays videos from
a URL you provide — it does not fetch, cache or upload media itself.
