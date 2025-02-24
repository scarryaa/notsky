import 'package:bluesky/bluesky.dart';

abstract class BlueskyService {
  Future<Feed> getTimeline({Map<String, String>? headers});
  Future<Preferences> getPreferences();
}
