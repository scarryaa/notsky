import 'dart:async';

import 'package:atproto/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/post/domain/services/post_state_manager.dart';
import 'package:notsky/features/post/presentation/cubits/post_state.dart';

class PostCubit extends Cubit<PostState> {
  final BlueskyService _blueskyService;
  final PostStateManager _stateManager = PostStateManager();
  String? _postUri;
  StreamSubscription? _subscription;

  PostCubit(this._blueskyService) : super(PostState());

  void initializePost(
    String postUri,
    bool isLiked,
    AtUri? likeUri,
    bool isReposted,
    AtUri? repostUri,
    int likeCount,
    int repostCount,
  ) {
    _postUri = postUri;

    final newState = PostState(
      isLiked: isLiked,
      likeUri: likeUri,
      isReposted: isReposted,
      repostUri: repostUri,
      likeCount: likeCount,
      repostCount: repostCount,
    );
    emit(newState);
    _stateManager.updatePostState(postUri, newState);

    // Listen for updates to this post
    _subscription = _stateManager.postUpdates.listen((updatedUri) {
      if (updatedUri == _postUri) {
        final updatedState = _stateManager.getPostState(updatedUri);
        if (updatedState != null) {
          emit(updatedState);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void updateLikeCount(int count) {
    final updatedState = state.copyWith(likeCount: count);
    emit(updatedState);
    if (_postUri != null) {
      _stateManager.updatePostState(_postUri!, updatedState);
    }
  }

  void updateRepostCount(int count) {
    final updatedState = state.copyWith(repostCount: count);
    emit(updatedState);
    if (_postUri != null) {
      _stateManager.updatePostState(_postUri!, updatedState);
    }
  }

  Future<void> toggleRepost(String cid, AtUri postUri) async {
    try {
      final updatedState = state.copyWith(
        currentAction: PostActionType.repost,
        actionStatus: PostActionStatus.inProgress,
      );
      emit(updatedState);
      if (_postUri != null) {
        _stateManager.updatePostState(_postUri!, updatedState);
      }

      if (state.isReposted) {
        if (state.repostUri != null) {
          // Unrepost the post
          final result = await _blueskyService.deleteRecord(state.repostUri!);
          if (result.success) {
            final successState = state.copyWith(
              isReposted: false,
              actionStatus: PostActionStatus.success,
              repostUri: null,
            );
            emit(successState);
            if (_postUri != null) {
              _stateManager.updatePostState(_postUri!, successState);
            }
          } else {
            final failureState = state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: result.error,
            );
            emit(failureState);
            if (_postUri != null) {
              _stateManager.updatePostState(_postUri!, failureState);
            }
          }
        } else {
          final errorState = state.copyWith(
            actionStatus: PostActionStatus.failure,
            error: 'Cannot unrepost: missing repost reference',
          );
          emit(errorState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, errorState);
          }
        }
      } else {
        // Repost the post
        final result = await _blueskyService.repost(cid, postUri);
        if (result.success && result.uri != null) {
          final successState = state.copyWith(
            isReposted: true,
            actionStatus: PostActionStatus.success,
            repostUri: result.uri,
          );
          emit(successState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, successState);
          }
        } else {
          final failureState = state.copyWith(
            actionStatus: PostActionStatus.failure,
            error: result.error,
          );
          emit(failureState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, failureState);
          }
        }
      }
    } catch (e) {
      final errorState = state.copyWith(
        actionStatus: PostActionStatus.failure,
        error: e.toString(),
      );
      emit(errorState);
      if (_postUri != null) {
        _stateManager.updatePostState(_postUri!, errorState);
      }
    }
  }

  Future<void> toggleLike(String cid, AtUri postUri) async {
    try {
      final updatedState = state.copyWith(
        currentAction: PostActionType.like,
        actionStatus: PostActionStatus.inProgress,
      );
      emit(updatedState);
      if (_postUri != null) {
        _stateManager.updatePostState(_postUri!, updatedState);
      }

      if (state.isLiked) {
        if (state.likeUri != null) {
          // Unlike the post
          final result = await _blueskyService.deleteRecord(state.likeUri!);
          if (result.success) {
            final successState = state.copyWith(
              isLiked: false,
              actionStatus: PostActionStatus.success,
              likeUri: null,
            );
            emit(successState);
            if (_postUri != null) {
              _stateManager.updatePostState(_postUri!, successState);
            }
          } else {
            final failureState = state.copyWith(
              actionStatus: PostActionStatus.failure,
              error: result.error,
            );
            emit(failureState);
            if (_postUri != null) {
              _stateManager.updatePostState(_postUri!, failureState);
            }
          }
        } else {
          final errorState = state.copyWith(
            actionStatus: PostActionStatus.failure,
            error: 'Cannot unlike: missing like reference',
          );
          emit(errorState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, errorState);
          }
        }
      } else {
        // Like the post
        final result = await _blueskyService.like(cid, postUri);
        if (result.success && result.uri != null) {
          final successState = state.copyWith(
            isLiked: true,
            actionStatus: PostActionStatus.success,
            likeUri: result.uri,
          );
          emit(successState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, successState);
          }
        } else {
          final failureState = state.copyWith(
            actionStatus: PostActionStatus.failure,
            error: result.error,
          );
          emit(failureState);
          if (_postUri != null) {
            _stateManager.updatePostState(_postUri!, failureState);
          }
        }
      }
    } catch (e) {
      print(e.toString());
      final errorState = state.copyWith(
        actionStatus: PostActionStatus.failure,
        error: e.toString(),
      );
      emit(errorState);
      if (_postUri != null) {
        _stateManager.updatePostState(_postUri!, errorState);
      }
    }
  }
}
