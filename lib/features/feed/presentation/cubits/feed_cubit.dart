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
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];
      final Feed feeds = await _fetchFeed(generatorUri: generatorUri);

      for (final post in feeds.feed) {
        if (post.post.record.reply != null &&
            !seenRootUris.contains(
              post.post.record.reply?.root.uri.toString(),
            )) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
          dedupedFeed.add(post);
        }
      }

      final Feed dedupedFeeds = Feed(feed: dedupedFeed, cursor: feeds.cursor);

      emit(
        FeedLoaded(
          dedupedFeeds,
          cursor: feeds.cursor,
          hasMore: feeds.feed.isNotEmpty,
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
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];
      final Feed newFeeds = await _fetchFeed(
        generatorUri: generatorUri,
        cursor: currentState.cursor,
      );

      for (final post in currentState.feeds.feed) {
        if (post.post.record.reply != null) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
        }
      }

      for (final post in newFeeds.feed) {
        if (post.post.record.reply != null &&
            !seenRootUris.contains(
              post.post.record.reply?.root.uri.toString(),
            )) {
          seenRootUris.add(post.post.record.reply!.root.uri.toString());
          dedupedFeed.add(post);
        }
      }

      final List<FeedView> combinedFeed = [
        ...currentState.feeds.feed,
        ...dedupedFeed,
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
          hasMore: dedupedFeed.isNotEmpty,
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
