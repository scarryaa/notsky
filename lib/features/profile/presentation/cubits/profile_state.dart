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
  final Feed? videosFeed;
  final Feed? likesFeed;
  final String? postsCursor;
  final String? repliesCursor;
  final String? mediaCursor;
  final String? videosCursor;
  final String? likesCursor;
  final bool hasMorePosts;
  final bool isLoadingPosts;
  final bool isLoadingMorePosts;

  ProfileLoaded(
    this.profile, {
    this.authorFeed,
    this.repliesFeed,
    this.mediaFeed,
    this.videosFeed,
    this.likesFeed,
    this.postsCursor,
    this.repliesCursor,
    this.mediaCursor,
    this.videosCursor,
    this.likesCursor,
    this.hasMorePosts = false,
    this.isLoadingPosts = false,
    this.isLoadingMorePosts = false,
  });

  ProfileLoaded copyWith({
    ActorProfile? profile,
    Feed? authorFeed,
    Feed? repliesFeed,
    Feed? mediaFeed,
    Feed? videosFeed,
    Feed? likesFeed,
    String? postsCursor,
    String? repliesCursor,
    String? mediaCursor,
    String? videosCursor,
    String? likesCursor,
    bool? hasMorePosts,
    bool? isLoadingPosts,
    bool? isLoadingMorePosts,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      authorFeed: authorFeed ?? this.authorFeed,
      repliesFeed: repliesFeed ?? this.repliesFeed,
      mediaFeed: mediaFeed ?? this.mediaFeed,
      videosFeed: videosFeed ?? this.videosFeed,
      likesFeed: likesFeed ?? this.likesFeed,
      postsCursor: postsCursor ?? this.postsCursor,
      repliesCursor: repliesCursor ?? this.repliesCursor,
      mediaCursor: mediaCursor ?? this.mediaCursor,
      videosCursor: videosCursor ?? this.videosCursor,
      likesCursor: likesCursor ?? this.likesCursor,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
    );
  }
}
