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
  final Feed? repliesFeed;
  final String? postsCursor;
  final String? repliesCursor;
  final bool hasMorePosts;
  final bool isLoadingPosts;
  final bool isLoadingMorePosts;

  ProfileLoaded(
    this.profile, {
    this.authorFeed,
    this.repliesFeed,
    this.postsCursor,
    this.repliesCursor,
    this.hasMorePosts = false,
    this.isLoadingPosts = false,
    this.isLoadingMorePosts = false,
  });

  ProfileLoaded copyWith({
    ActorProfile? profile,
    Feed? authorFeed,
    Feed? repliesFeed,
    String? postsCursor,
    String? repliesCursor,
    bool? hasMorePosts,
    bool? isLoadingPosts,
    bool? isLoadingMorePosts,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      authorFeed: authorFeed ?? this.authorFeed,
      repliesFeed: repliesFeed ?? this.repliesFeed,
      postsCursor: postsCursor ?? this.postsCursor,
      repliesCursor: repliesCursor ?? this.repliesCursor,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
    );
  }
}
