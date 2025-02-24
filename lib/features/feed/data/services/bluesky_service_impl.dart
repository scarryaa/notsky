import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
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
}
