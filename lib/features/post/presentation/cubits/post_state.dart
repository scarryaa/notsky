import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';

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

  final bool isThreadLoading;
  final PostThread? postThread;
  final String? threadError;
  final bool isLoadingMore;
  final String? cursor;

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
    this.isThreadLoading = false,
    this.postThread,
    this.threadError,
    this.cursor,
    this.isLoadingMore = false,
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
    bool? isThreadLoading,
    PostThread? postThread,
    String? threadError,
    bool? isLoadingMore,
    String? cursor,
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
      isThreadLoading: isThreadLoading ?? this.isThreadLoading,
      postThread: postThread ?? this.postThread,
      threadError: threadError ?? this.threadError,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      cursor: cursor ?? this.cursor,
    );
  }
}
