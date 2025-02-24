import 'package:bluesky/bluesky.dart';

abstract class FeedRepository {
  Future<Feed> getFeed();
}
