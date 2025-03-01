import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';
import 'package:notsky/features/post/domain/entities/post_action_result.dart';

abstract class BlueskyService {
  Future<Feed> getTimeline({
    Map<String, String>? headers,
    String? cursor,
    int? limit,
  });

  Future<Preferences> getPreferences();

  Future<ActorProfile> getProfile(String did);

  Future<Feed> getFeed({
    required AtUri generatorUri,
    String? cursor,
    int? limit,
  });

  Future<PostThread> getThread(AtUri uri, {int depth = 10});
  Future<Post?> getPost(AtUri uri);

  Future<FeedGenerators> getFeeds();
  Future<List<ContentLabelPreference>> getContentPreferences();

  Future<PostActionResult> like(String cid, AtUri uri);
  Future<PostActionResult> deleteRecord(AtUri uri);
  Future<PostActionResult> post(String text);
  Future<PostActionResult> reply(
    String text, {
    required String rootCid,
    required AtUri rootUri,
    required String parentCid,
    required AtUri parentUri,
  });
  Future<PostActionResult> repost(String cid, AtUri uri);
  Future<PostActionResult> quote(String cid, AtUri uri);
}
