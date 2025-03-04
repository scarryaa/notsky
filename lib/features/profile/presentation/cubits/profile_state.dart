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
  final Feed? mediaFeed;
  final String? postsCursor;
  final String? repliesCursor;
  final String? mediaCursor;
  final bool hasMorePosts;
  final bool isLoadingPosts;
  final bool isLoadingMorePosts;

  ProfileLoaded(
    this.profile, {
    this.authorFeed,
    this.repliesFeed,
    this.mediaFeed,
    this.postsCursor,
    this.repliesCursor,
    this.mediaCursor,
    this.hasMorePosts = false,
    this.isLoadingPosts = false,
    this.isLoadingMorePosts = false,
  });

  ProfileLoaded copyWith({
    ActorProfile? profile,
    Feed? authorFeed,
    Feed? repliesFeed,
    Feed? mediaFeed,
    String? postsCursor,
    String? repliesCursor,
    String? mediaCursor,
    bool? hasMorePosts,
    bool? isLoadingPosts,
    bool? isLoadingMorePosts,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      authorFeed: authorFeed ?? this.authorFeed,
      repliesFeed: repliesFeed ?? this.repliesFeed,
      mediaFeed: mediaFeed ?? this.mediaFeed,
      postsCursor: postsCursor ?? this.postsCursor,
      repliesCursor: repliesCursor ?? this.repliesCursor,
      mediaCursor: mediaCursor ?? this.mediaCursor,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
    );
  }
}
