import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';

class BlueskyServiceImpl implements BlueskyService {
  final Bluesky _bluesky;

  BlueskyServiceImpl(Session session) : _bluesky = Bluesky.fromSession(session);

  @override
  Future<Feed> getTimeline({Map<String, String>? headers}) async {
    return (await _bluesky.feed.getTimeline(headers: headers)).data;
  }

  @override
  Future<Preferences> getPreferences() async {
    return (await _bluesky.actor.getPreferences()).data;
  }
}
