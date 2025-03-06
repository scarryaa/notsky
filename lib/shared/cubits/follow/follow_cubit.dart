import 'package:atproto_core/atproto_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/shared/cubits/follow/follow_state.dart';

class FollowCubit extends Cubit<FollowState> {
  final BlueskyService _blueskyService;

  FollowCubit(this._blueskyService) : super(FollowInitial()) {
    emit(FollowLoaded({}, {}));
  }

  Future<void> toggleFollow(String actorDid, AtUri? followingUri) async {
    final currentState = state as FollowLoaded;

    final newLoadingMap = Map<String, bool>.from(currentState.followingLoading);
    newLoadingMap[actorDid] = true;

    final newFollowingMap = Map<String, bool>.from(
      currentState.followingStatus,
    );
    newFollowingMap[actorDid] = !(newFollowingMap[actorDid] ?? false);

    emit(FollowLoaded(newFollowingMap, newLoadingMap));

    try {
      if (followingUri != null) {
        await _blueskyService.deleteRecord(followingUri);
      } else {
        await _blueskyService.follow(actorDid);
      }

      newLoadingMap[actorDid] = false;
      emit(FollowLoaded(newFollowingMap, newLoadingMap));
    } catch (e) {
      newLoadingMap[actorDid] = false;
      newFollowingMap[actorDid] = !(newFollowingMap[actorDid] ?? false);
      emit(FollowLoaded(newFollowingMap, newLoadingMap));

      rethrow;
    }
  }

  void initializeFollowingStatus(String actorDid, bool isFollowing) {
    final currentState = state as FollowLoaded;

    if (!currentState.followingStatus.containsKey(actorDid)) {
      final newFollowingMap = Map<String, bool>.from(
        currentState.followingStatus,
      );
      newFollowingMap[actorDid] = isFollowing;

      final newLoadingMap = Map<String, bool>.from(
        currentState.followingLoading,
      );
      newLoadingMap[actorDid] = false;

      emit(FollowLoaded(newFollowingMap, newLoadingMap));
    }
  }
}
