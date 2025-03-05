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

  Future<Feed> getAuthorFeed(String authorDid, {String? cursor, int? limit});
  Future<Feed> getAuthorReplies(String authorDid, {String? cursor, int? limit});
  Future<Feed> getAuthorMedia(String authorDid, {String? cursor, int? limit});
  Future<Feed> getAuthorVideos(String authorDid, {String? cursor, int? limit});
  Future<Feed> getActorLikes(String authorDid, {String? cursor, int? limit});
  Future<ActorFeeds> getActorFeeds(
    String authorDid, {
    String? cursor,
    int? limit,
  });

  Future<Feed> getFeed({
    required AtUri generatorUri,
    String? cursor,
    int? limit,
  });

  Future<PostThread> getThread(AtUri uri, {int depth = 10});
  Future<Post?> getPost(AtUri uri);

  Future<FeedGenerators> getFeeds();
  Future<List<ContentLabelPreference>> getContentPreferences();
  Future<List<SavedFeedsPrefV2>> getSavedFeedsPreferenceV2();
  Future<List<SavedFeedsPreference>> getSavedFeedsPreference();

  Future<List<Actor>> searchActors(String term, {int? limit});
  Future<List<Post>> searchPosts(String term, {int? limit});

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
  Future<PostActionResult> quote(String text, String cid, AtUri uri);
}
