import 'package:atproto/core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class PostCubit extends Cubit<PostState> {
  final BlueskyService _blueskyService;

  PostCubit(this._blueskyService) : super(PostState());

  void initializePost(
    bool isLiked,
    AtUri? likeUri,
    bool isReposted,
    AtUri? repostUri,
  ) {
    emit(
      state.copyWith(
        isLiked: isLiked,
        likeUri: likeUri,
        isReposted: isReposted,
        repostUri: repostUri,
      ),
    );
  }

  Future<void> toggleRepost(String cid, AtUri postUri) async {
    try {
      emit(
        state.copyWith(
          currentAction: PostActionType.repost,
          actionStatus: PostActionStatus.inProgress,
        ),
      );

      if (state.isReposted) {
        if (state.repostUri != null) {
          // Unrepost the post
          final result = await _blueskyService.deleteRecord(state.repostUri!);
          if (result.success) {
            emit(
              state.copyWith(
                isReposted: false,
                actionStatus: PostActionStatus.success,
                repostUri: null,
              ),
            );
          } else {
            emit(
              state.copyWith(
                actionStatus: PostActionStatus.failure,
                error: result.error,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: 'Cannot unrepost: missing repost reference',
            ),
          );
        }
      } else {
        // Repost the post
        final result = await _blueskyService.repost(cid, postUri);
        if (result.success && result.uri != null) {
          emit(
            state.copyWith(
              isReposted: true,
              actionStatus: PostActionStatus.success,
              repostUri: result.uri,
            ),
          );
        } else {
          emit(
            state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: result.error,
            ),
          );
        }
      }
    } catch (e) {
      print(e.toString());
      emit(
        state.copyWith(
          actionStatus: PostActionStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> toggleLike(String cid, AtUri postUri) async {
    try {
      emit(
        state.copyWith(
          currentAction: PostActionType.like,
          actionStatus: PostActionStatus.inProgress,
        ),
      );

      if (state.isLiked) {
        if (state.likeUri != null) {
          // Unlike the post
          final result = await _blueskyService.deleteRecord(state.likeUri!);
          if (result.success) {
            emit(
              state.copyWith(
                isLiked: false,
                actionStatus: PostActionStatus.success,
                likeUri: null,
              ),
            );
          } else {
            emit(
              state.copyWith(
                actionStatus: PostActionStatus.failure,
                error: result.error,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: 'Cannot unlike: missing like reference',
            ),
          );
        }
      } else {
        // Like the post
        final result = await _blueskyService.like(cid, postUri);
        if (result.success && result.uri != null) {
          emit(
            state.copyWith(
              isLiked: true,
              actionStatus: PostActionStatus.success,
              likeUri: result.uri,
            ),
          );
        } else {
          emit(
            state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: result.error,
            ),
          );
        }
      }
    } catch (e) {
      print(e.toString());
      emit(
        state.copyWith(
          actionStatus: PostActionStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
