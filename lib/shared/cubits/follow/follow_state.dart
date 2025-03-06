abstract class FollowState {}

class FollowInitial extends FollowState {}

class FollowLoaded extends FollowState {
  final Map<String, bool> followingStatus;
  final Map<String, bool> followingLoading;

  FollowLoaded(this.followingStatus, this.followingLoading);
}
