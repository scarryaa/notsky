import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';

abstract class FeedRepository {
  Future<Feed> getFeed({required AtUri generatorUri});
  Future<Feed> getTimeline();
  Future<FeedGenerators> getFeeds();
}
