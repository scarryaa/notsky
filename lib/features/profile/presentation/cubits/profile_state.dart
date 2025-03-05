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
  final String? feedsCursor;
  final bool hasMorePosts;
  final bool isLoadingPosts;
  final bool isLoadingMorePosts;
  ActorFeeds? actorFeeds;
  bool isLoadingFeeds = false;
  bool hasMoreFeeds = false;
  bool isLoadingMoreFeeds = false;

  ProfileLoaded(
    this.profile, {
    this.authorFeed,
    this.repliesFeed,
    this.mediaFeed,
    this.videosFeed,
    this.likesFeed,
    this.actorFeeds,
    this.postsCursor,
    this.repliesCursor,
    this.mediaCursor,
    this.videosCursor,
    this.likesCursor,
    this.feedsCursor,
    this.hasMorePosts = false,
    this.isLoadingPosts = false,
    this.isLoadingMorePosts = false,
    this.isLoadingFeeds = false,
    this.isLoadingMoreFeeds = false,
  });

  ProfileLoaded copyWith({
    ActorProfile? profile,
    Feed? authorFeed,
    Feed? repliesFeed,
    Feed? mediaFeed,
    Feed? videosFeed,
    Feed? likesFeed,
    ActorFeeds? actorFeeds,
    String? postsCursor,
    String? repliesCursor,
    String? mediaCursor,
    String? videosCursor,
    String? likesCursor,
    String? feedsCursor,
    bool? hasMorePosts,
    bool? hasMoreFeeds,
    bool? isLoadingPosts,
    bool? isLoadingFeeds,
    bool? isLoadingMorePosts,
    bool? isLoadingMoreFeeds,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      authorFeed: authorFeed ?? this.authorFeed,
      repliesFeed: repliesFeed ?? this.repliesFeed,
      mediaFeed: mediaFeed ?? this.mediaFeed,
      videosFeed: videosFeed ?? this.videosFeed,
      likesFeed: likesFeed ?? this.likesFeed,
      actorFeeds: actorFeeds ?? this.actorFeeds,
      postsCursor: postsCursor ?? this.postsCursor,
      repliesCursor: repliesCursor ?? this.repliesCursor,
      mediaCursor: mediaCursor ?? this.mediaCursor,
      videosCursor: videosCursor ?? this.videosCursor,
      feedsCursor: feedsCursor ?? this.feedsCursor,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingFeeds: isLoadingFeeds ?? this.isLoadingFeeds,
      isLoadingMorePosts: isLoadingMorePosts ?? this.isLoadingMorePosts,
      isLoadingMoreFeeds: isLoadingMoreFeeds ?? this.isLoadingMoreFeeds,
    );
  }
}
