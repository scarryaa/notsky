import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';

class BlueskyFeedRepository implements FeedRepository {
  final BlueskyService _blueskyService;

  BlueskyFeedRepository(this._blueskyService);

  @override
  Future<Feed> getTimeline() async {
    return await _blueskyService.getTimeline();
  }

  @override
  Future<Feed> getFeed({required AtUri generatorUri}) async {
    try {
      final feeds = await _blueskyService.getFeed(generatorUri: generatorUri);

      return feeds;
    } catch (e) {
      rethrow;
    }
  }
}
