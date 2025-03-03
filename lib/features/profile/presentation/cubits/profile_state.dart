import 'package:bluesky/bluesky.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileLoaded extends ProfileState {
  final ActorProfile profile;
  final Feed? authorFeed;
  final String? postsCursor;
  final bool hasMorePosts;
  final bool isLoadingPosts;
  final bool isLoadingMorePosts;

  ProfileLoaded(
    this.profile, {
    this.authorFeed,
    this.postsCursor,
    this.hasMorePosts = false,
    this.isLoadingPosts = false,
    this.isLoadingMorePosts = false,
  });

  ProfileLoaded copyWith({
    ActorProfile? profile,
    Feed? authorFeed,
    String? postsCursor,
    bool? hasMorePosts,
    bool? isLoadingPosts,
    bool? isLoadingMorePosts,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      authorFeed: authorFeed ?? this.authorFeed,
      postsCursor: postsCursor ?? this.postsCursor,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
    );
  }
}
