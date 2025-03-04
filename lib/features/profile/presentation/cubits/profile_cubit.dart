import 'package:bluesky/bluesky.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_state.dart';

enum FeedType { posts, media, replies }

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

      emit(
        _updateStateWithFeed(
          currentState,
          feedType,
          combinedFeeds,
          newFeed.cursor,
          newFeed.feed.isNotEmpty,
          false,
          isLoadingMorePosts: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMorePosts: false));
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
    }
  }
}
