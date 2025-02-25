import 'package:atproto_core/atproto_core.dart';

enum PostActionType { none, like, unlike, repost, unrepost, reply }

enum PostActionStatus { idle, inProgress, success, failure }

class PostState {
  final bool isLiked;
  final bool isReposted;
  final PostActionType currentAction;
  final PostActionStatus actionStatus;
  final String? error;
  final AtUri? likeUri;
  final AtUri? repostUri;
  final int? likeCount;
  final int? repostCount;

  PostState({
    this.isLiked = false,
    this.isReposted = false,
    this.currentAction = PostActionType.none,
    this.actionStatus = PostActionStatus.idle,
    this.error,
    this.likeUri,
    this.repostUri,
    this.likeCount,
    this.repostCount,
  });

  PostState copyWith({
    bool? isLiked,
    bool? isReposted,
    PostActionType? currentAction,
    PostActionStatus? actionStatus,
    String? error,
    AtUri? likeUri,
    AtUri? repostUri,
    int? likeCount,
    int? repostCount,
  }) {
    return PostState(
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      currentAction: currentAction ?? this.currentAction,
      actionStatus: actionStatus ?? this.actionStatus,
      error: error,
      likeUri: likeUri ?? this.likeUri,
      repostUri: repostUri ?? this.repostUri,
      likeCount: likeCount ?? this.likeCount,
      repostCount: repostCount ?? this.repostCount,
    );
  }
}
