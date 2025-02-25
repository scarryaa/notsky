import 'package:atproto_core/atproto_core.dart';
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
  Future<Feed> getTimeline({Map<String, String>? headers}) async {
    try {
      return (await _bluesky.feed.getTimeline(headers: headers)).data;
    } catch (e) {
      if (isExpiredTokenError(e)) {
        final currentSession = _bluesky.session;
        if (currentSession != null) {
          await _authCubit.refreshUserSession(currentSession.refreshJwt);
          return (await _bluesky.feed.getTimeline(headers: headers)).data;
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
  Future<PostActionResult> reply(String cid, AtUri uri) {
    // TODO: implement reply
    throw UnimplementedError();
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
