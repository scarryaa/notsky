import 'package:bluesky/bluesky.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_state.dart';

enum FeedType { posts, media, replies, videos, likes }

class ProfileCubit extends Cubit<ProfileState> {
  final BlueskyService _blueskyService;
  List<ContentLabelPreference> _contentLabelPreferences = [];

  ProfileCubit(this._blueskyService) : super(ProfileInitial());

  List<ContentLabelPreference> get contentLabelPreferences =>
      _contentLabelPreferences;

  Future<void> loadContentLabelPreferences() async {
    try {
      _contentLabelPreferences = await _blueskyService.getContentPreferences();
    } catch (e) {}
  }

  Future<void> getProfile(String actorDid) async {
    emit(ProfileLoading());

    try {
      final profile = await _blueskyService.getProfile(actorDid);
      emit(ProfileLoaded(profile));

      await loadContentLabelPreferences();

      await loadFeed(actorDid, FeedType.posts);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> loadFeed(String actorDid, FeedType feedType) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    emit(currentState.copyWith(isLoadingPosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];

      final Feed feed = await _getFeedByType(actorDid, feedType);

      for (final post in feed.feed) {
        if (post.post.record.reply != null &&
            !seenRootUris.contains(
              post.post.record.reply?.root.uri.toString(),
            )) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
          dedupedFeed.add(post);
        } else if (post.post.record.reply == null &&
            !seenRootUris.contains(post.post.uri.toString())) {
          seenRootUris.add(post.post.uri.toString());
          dedupedFeed.add(post);
        }
      }

      final Feed dedupedFeeds = Feed(feed: dedupedFeed, cursor: feed.cursor);

      emit(
        _updateStateWithFeed(
          currentState,
          feedType,
          dedupedFeeds,
          feed.cursor,
          feed.feed.isNotEmpty,
          false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingPosts: false));
    }
  }

  Future<void> loadMoreFeed(String actorDid, FeedType feedType) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;

    final String? currentCursor = _getCursorByType(currentState, feedType);
    final Feed? currentFeed = _getFeedFromState(currentState, feedType);

    if (currentState.isLoadingMorePosts ||
        !currentState.hasMorePosts ||
        currentFeed == null) {
      return;
    }

    emit(currentState.copyWith(isLoadingMorePosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];
      // Get more feed items with cursor
      final newFeed = await _getFeedByType(
        actorDid,
        feedType,
        cursor: currentCursor,
      );

      for (final post in currentFeed.feed) {
        if (post.post.record.reply != null) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
        }
      }

      for (final post in newFeed.feed) {
        if (post.post.record.reply != null &&
            !seenRootUris.contains(
              post.post.record.reply?.root.uri.toString(),
            )) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
          dedupedFeed.add(post);
        } else if (post.post.record.reply == null &&
            !seenRootUris.contains(post.post.uri.toString())) {
          seenRootUris.add(post.post.uri.toString());
          dedupedFeed.add(post);
        }
      }

      final List<FeedView> combinedFeed = [...currentFeed.feed, ...dedupedFeed];

      final Feed combinedFeeds = Feed(
        feed: combinedFeed,
        cursor: newFeed.cursor,
      );

      final bool reachedEndOfFeed =
          newFeed.feed.isEmpty || newFeed.cursor == null;

      emit(
        _updateStateWithFeed(
          currentState,
          feedType,
          newFeed.cursor == null ? Feed(feed: currentFeed.feed) : combinedFeeds,
          newFeed.cursor,
          !reachedEndOfFeed,
          false,
          isLoadingMorePosts: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMorePosts: false));
    }
  }

  Future<void> loadActorFeeds(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    emit(currentState.copyWith(isLoadingFeeds: true));

    try {
      final feeds = await _blueskyService.getActorFeeds(actorDid);
      emit(
        currentState.copyWith(
          actorFeeds: feeds,
          feedsCursor: feeds.cursor,
          hasMoreFeeds: feeds.cursor != null,
          isLoadingFeeds: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingFeeds: false));
    }
  }

  Future<void> loadMoreActorFeeds(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    if (currentState.isLoadingMoreFeeds || !currentState.hasMoreFeeds) return;

    emit(currentState.copyWith(isLoadingMoreFeeds: true));

    try {
      final feeds = await _blueskyService.getActorFeeds(
        actorDid,
        cursor: currentState.feedsCursor,
      );

      final updatedFeeds = ActorFeeds(
        feeds: [...currentState.actorFeeds!.feeds, ...feeds.feeds],
        cursor: feeds.cursor,
      );

      emit(
        currentState.copyWith(
          actorFeeds: updatedFeeds,
          feedsCursor: feeds.cursor,
          hasMoreFeeds: feeds.cursor != null,
          isLoadingMoreFeeds: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMoreFeeds: false));
    }
  }

  Future<Feed> _getFeedByType(
    String actorDid,
    FeedType feedType, {
    String? cursor,
  }) async {
    switch (feedType) {
      case FeedType.posts:
        return await _blueskyService.getAuthorFeed(actorDid, cursor: cursor);
      case FeedType.media:
        return await _blueskyService.getAuthorMedia(actorDid, cursor: cursor);
      case FeedType.replies:
        return await _blueskyService.getAuthorReplies(actorDid, cursor: cursor);
      case FeedType.videos:
        return await _blueskyService.getAuthorVideos(actorDid, cursor: cursor);
      case FeedType.likes:
        return await _blueskyService.getActorLikes(actorDid, cursor: cursor);
    }
  }

  String? _getCursorByType(ProfileLoaded state, FeedType feedType) {
    switch (feedType) {
      case FeedType.posts:
        return state.postsCursor;
      case FeedType.media:
        return state.mediaCursor;
      case FeedType.replies:
        return state.repliesCursor;
      case FeedType.videos:
        return state.videosCursor;
      case FeedType.likes:
        return state.likesCursor;
    }
  }

  Feed? _getFeedFromState(ProfileLoaded state, FeedType feedType) {
    switch (feedType) {
      case FeedType.posts:
        return state.authorFeed;
      case FeedType.media:
        return state.mediaFeed;
      case FeedType.replies:
        return state.repliesFeed;
      case FeedType.videos:
        return state.videosFeed;
      case FeedType.likes:
        return state.likesFeed;
    }
  }

  ProfileLoaded _updateStateWithFeed(
    ProfileLoaded state,
    FeedType feedType,
    Feed feed,
    String? cursor,
    bool hasMore,
    bool isLoading, {
    bool isLoadingMorePosts = false,
  }) {
    switch (feedType) {
      case FeedType.posts:
        return state.copyWith(
          authorFeed: feed,
          postsCursor: cursor,
          hasMorePosts: hasMore,
          isLoadingPosts: isLoading,
          isLoadingMorePosts: isLoadingMorePosts,
        );
      case FeedType.media:
        return state.copyWith(
          mediaFeed: feed,
          mediaCursor: cursor,
          hasMorePosts: hasMore,
          isLoadingPosts: isLoading,
          isLoadingMorePosts: isLoadingMorePosts,
        );
      case FeedType.replies:
        return state.copyWith(
          repliesFeed: feed,
          repliesCursor: cursor,
          hasMorePosts: hasMore,
          isLoadingPosts: isLoading,
          isLoadingMorePosts: isLoadingMorePosts,
        );
      case FeedType.videos:
        return state.copyWith(
          videosFeed: feed,
          videosCursor: cursor,
          hasMorePosts: hasMore,
          isLoadingPosts: isLoading,
          isLoadingMorePosts: isLoadingMorePosts,
        );
      case FeedType.likes:
        return state.copyWith(
          likesFeed: feed,
          likesCursor: cursor,
          hasMorePosts: hasMore,
          isLoadingPosts: isLoading,
          isLoadingMorePosts: isLoadingMorePosts,
        );
    }
  }
}
