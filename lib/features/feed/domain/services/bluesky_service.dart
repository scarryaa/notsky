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

  Future<Feed> getFeed({
    required AtUri generatorUri,
    String? cursor,
    int? limit,
  });

  Future<PostActionResult> like(String cid, AtUri uri);
  Future<PostActionResult> deleteRecord(AtUri uri);
  Future<PostActionResult> reply(String cid, AtUri uri);
  Future<PostActionResult> repost(String cid, AtUri uri);
  Future<PostActionResult> quote(String cid, AtUri uri);
}
