import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final BlueskyService _blueskyService;

  FeedCubit(this._blueskyService) : super(FeedInitial());

  Future<void> loadFeed({AtUri? generatorUri}) async {
    emit(FeedLoading());

    try {
      final Feed feeds = await _fetchFeed(generatorUri: generatorUri);

      final Set<String> uniquePostUris = <String>{};
      final List<FeedView> uniqueFeed = [];

      for (final feedView in feeds.feed) {
        final postUri = feedView.post.uri.toString();
        if (!uniquePostUris.contains(postUri)) {
          uniquePostUris.add(postUri);
          uniqueFeed.add(feedView);
        }
      }

      final Feed uniqueFeeds = Feed(feed: uniqueFeed, cursor: feeds.cursor);

      emit(
        FeedLoaded(
          uniqueFeeds,
          cursor: feeds.cursor,
          hasMore: uniqueFeed.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> loadMoreFeed({AtUri? generatorUri}) async {
    if (state is! FeedLoaded) return;

    final currentState = state as FeedLoaded;

    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final Feed newFeeds = await _fetchFeed(
        generatorUri: generatorUri,
        cursor: currentState.cursor,
      );

      final Set<String> existingPostUris =
          currentState.feeds.feed
              .map((feedView) => feedView.post.uri.toString())
              .toSet();

      final List<FeedView> uniqueNewFeed =
          newFeeds.feed
              .where(
                (feedView) =>
                    !existingPostUris.contains(feedView.post.uri.toString()),
              )
              .toList();

      // Combine with existing feed
      final List<FeedView> combinedFeed = [
        ...currentState.feeds.feed,
        ...uniqueNewFeed,
      ];

      final Feed combinedFeeds = Feed(
        feed: combinedFeed,
        cursor: newFeeds.cursor,
      );

      emit(
        FeedLoaded(
          combinedFeeds,
          isLoadingMore: false,
          cursor: newFeeds.cursor,
          hasMore: uniqueNewFeed.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<Feed> _fetchFeed({AtUri? generatorUri, String? cursor}) async {
    if (generatorUri != null) {
      return await _blueskyService.getFeed(
        generatorUri: generatorUri,
        limit: 50,
        cursor: cursor,
      );
    } else {
      return await _blueskyService.getTimeline(limit: 50, cursor: cursor);
    }
  }
}
