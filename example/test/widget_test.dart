import 'package:flutter_test/flutter_test.dart';
import 'package:reels_player_example/main.dart';

// Playback itself needs a real platform (video_player has no test
// implementation), so this exercises the example's own paging logic —
// swipe/autoplay are checked by running the app (`flutter run`).
void main() {
  test('fetchPage pages through the sample videos then returns empty', () async {
    final api = FakeReelsApi();

    final page1 = await api.fetchPage(1);
    final page2 = await api.fetchPage(2);
    final page3 = await api.fetchPage(3);

    expect(page1, hasLength(FakeReelsApi.pageSize));
    expect(page2, hasLength(FakeReelsApi.pageSize));
    expect(page3, isEmpty);
    expect(page1.map((v) => v.id).toSet(), hasLength(FakeReelsApi.pageSize));
  });
}
