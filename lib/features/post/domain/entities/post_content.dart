import 'package:bluesky/bluesky.dart';

sealed class PostContent {}

class RegularPost extends PostContent {
  final Post post;

  RegularPost(this.post);
}

class MissingPost extends PostContent {
  final NotFoundPost notFoundPost;

  MissingPost(this.notFoundPost);
}

class BlockPost extends PostContent {
  final BlockedPost blockedPost;

  BlockPost(this.blockedPost);
}
