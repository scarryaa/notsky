import 'package:bluesky/bluesky.dart';
import 'package:bluesky/moderation.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';

class BlueskyFeedRepository implements FeedRepository {
  final BlueskyService _blueskyService;

  BlueskyFeedRepository(this._blueskyService);

  @override
  Future<Feed> getFeed() async {
    final preferences = await _blueskyService.getPreferences();
    final moderationPrefs = preferences.getModerationPrefs();
    final feeds = await _blueskyService.getTimeline(
      headers: getLabelerHeaders(moderationPrefs),
    );
    return feeds;
  }
}
