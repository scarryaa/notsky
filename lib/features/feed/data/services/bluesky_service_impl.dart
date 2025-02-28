import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/atproto.dart';
import 'package:bluesky/bluesky.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/post/domain/entities/post_action_result.dart';
import 'package:notsky/util/util.dart';

class BlueskyServiceImpl implements BlueskyService {
  final Bluesky _bluesky;
  final AuthCubit _authCubit;

  BlueskyServiceImpl(Session session, this._authCubit)
    : _bluesky = Bluesky.fromSession(session);

  @override
  Future<Feed> getTimeline({
    Map<String, String>? headers,
    String? cursor,
    int? limit,
  }) async {
    try {
      return (await _bluesky.feed.getTimeline(
        headers: headers,
        cursor: cursor,
        limit: limit,
      )).data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          return (await _bluesky.feed.getTimeline(
            headers: headers,
            cursor: cursor,
            limit: limit,
          )).data;
        }
      }
      rethrow;
    }
  }

  @override
  Future<Feed> getFeed({
    required AtUri generatorUri,
    String? cursor,
    int? limit,
  }) async {
    try {
      final Map<String, String> headers = {};

      if (cursor != null) {
        headers['cursor'] = cursor;
      }

      if (limit != null) {
        headers['limit'] = limit.toString();
      }

      return (await _bluesky.feed.getFeed(
        generatorUri: generatorUri,
        headers: headers.isNotEmpty ? headers : null,
      )).data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);

          final Map<String, String> headers = {};

          if (cursor != null) {
            headers['cursor'] = cursor;
          }

          if (limit != null) {
            headers['limit'] = limit.toString();
          }

          return (await _bluesky.feed.getFeed(
            generatorUri: generatorUri,
            headers: headers.isNotEmpty ? headers : null,
          )).data;
        }
      }
      rethrow;
    }
  }

  @override
  Future<Preferences> getPreferences() async {
    try {
      return (await _bluesky.actor.getPreferences()).data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          return (await _bluesky.actor.getPreferences()).data;
        }
      }
      rethrow;
    }
  }

  @override
  Future<ActorProfile> getProfile(String did) async {
    try {
      final profile = await _bluesky.actor.getProfile(actor: did);
      return profile.data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          final profile = await _bluesky.actor.getProfile(actor: did);
          return profile.data;
        }
      }
      rethrow;
    }
  }

  @override
  Future<FeedGenerators> getFeeds() async {
    try {
      final preferences = await getPreferences();

      final savedFeedUris =
          preferences.preferences
              .where((pref) => pref.data is SavedFeedsPrefV2)
              .map((pref) => pref.data as SavedFeedsPrefV2)
              .expand(
                (savedFeedsPref) =>
                    savedFeedsPref.items.map((feed) => AtUri(feed.value)),
              )
              // Skip following feed
              .skip(1)
              .toList();

      return (await _bluesky.feed.getFeedGenerators(uris: savedFeedUris)).data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);

          final preferences = await getPreferences();

          final savedFeedUris =
              preferences.preferences
                  .where((pref) => pref.data is SavedFeedsPrefV2)
                  .map((pref) => pref.data as SavedFeedsPrefV2)
                  .expand(
                    (savedFeedsPref) =>
                        savedFeedsPref.items.map((feed) => AtUri(feed.value)),
                  )
                  .toList();

          return (await _bluesky.feed.getFeedGenerators(
            uris: savedFeedUris,
          )).data;
        }
      }
      rethrow;
    }
  }

  @override
  Future<PostActionResult> like(String cid, AtUri uri) async {
    try {
      final result = await _bluesky.feed.like(cid: cid, uri: uri);
      return PostActionResult(success: true, uri: result.data.uri);
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          final result = await _bluesky.feed.like(cid: cid, uri: uri);
          return PostActionResult(success: true, uri: result.data.uri);
        }
      }
      return PostActionResult(error: e.toString());
    }
  }

  @override
  Future<PostActionResult> quote(String cid, AtUri uri) {
    // TODO: implement quote
    throw UnimplementedError();
  }

  @override
  Future<PostActionResult> post(String text) async {
    try {
      final result = await _bluesky.feed.post(text: text);
      return PostActionResult(success: true, uri: result.data.uri);
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          final result = await _bluesky.feed.post(text: text);
          return PostActionResult(success: true, uri: result.data.uri);
        }
      }
      return PostActionResult(error: e.toString());
    }
  }

  @override
  Future<PostActionResult> reply(
    String text, {
    required String rootCid,
    required AtUri rootUri,
    required String parentCid,
    required AtUri parentUri,
  }) async {
    try {
      final result = await _bluesky.feed.post(
        text: text,
        reply: ReplyRef(
          root: StrongRef(cid: rootCid, uri: rootUri),
          parent: StrongRef(cid: parentCid, uri: parentUri),
        ),
      );
      return PostActionResult(success: true, uri: result.data.uri);
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          final result = await _bluesky.feed.post(text: text);
          return PostActionResult(success: true, uri: result.data.uri);
        }
      }
      return PostActionResult(error: e.toString());
    }
  }

  @override
  Future<PostActionResult> repost(String cid, AtUri uri) async {
    try {
      final result = await _bluesky.feed.repost(cid: cid, uri: uri);
      return PostActionResult(success: true, uri: result.data.uri);
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          await _bluesky.feed.repost(cid: cid, uri: uri);
          return PostActionResult(success: true);
        }
      }
      return PostActionResult(error: e.toString());
    }
  }

  @override
  Future<PostActionResult> deleteRecord(AtUri uri) async {
    try {
      await _bluesky.atproto.repo.deleteRecord(uri: uri);
      return PostActionResult(success: true);
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          await _bluesky.atproto.repo.deleteRecord(uri: uri);
          return PostActionResult(success: true);
        }
      }
      return PostActionResult(error: e.toString());
    }
  }
}
