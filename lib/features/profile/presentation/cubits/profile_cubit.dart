import 'package:bluesky/bluesky.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/profile/presentation/cubits/profile_state.dart';

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

      await loadAuthorPosts(actorDid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> loadAuthorReplies(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    emit(currentState.copyWith(isLoadingPosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];

      final feed = await _blueskyService.getAuthorReplies(actorDid);

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
        currentState.copyWith(
          repliesFeed: dedupedFeeds,
          repliesCursor: feed.cursor,
          hasMorePosts: feed.feed.isNotEmpty,
          isLoadingPosts: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingPosts: false));
    }
  }

  Future<void> loadMoreAuthorReplies(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;

    if (currentState.isLoadingMorePosts || !currentState.hasMorePosts) return;

    emit(currentState.copyWith(isLoadingMorePosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];

      final newFeed = await _blueskyService.getAuthorReplies(
        actorDid,
        cursor: currentState.repliesCursor,
      );

      for (final post in currentState.repliesFeed!.feed) {
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

      final List<FeedView> combinedFeed = [
        ...currentState.repliesFeed!.feed,
        ...dedupedFeed,
      ];

      final Feed combinedFeeds = Feed(
        feed: combinedFeed,
        cursor: newFeed.cursor,
      );

      emit(
        currentState.copyWith(
          repliesFeed: combinedFeeds,
          isLoadingMorePosts: false,
          repliesCursor: newFeed.cursor,
          hasMorePosts: newFeed.feed.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMorePosts: false));
    }
  }

  Future<void> loadAuthorPosts(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;
    emit(currentState.copyWith(isLoadingPosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];

      final feed = await _blueskyService.getAuthorFeed(actorDid);

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
        currentState.copyWith(
          authorFeed: dedupedFeeds,
          postsCursor: feed.cursor,
          hasMorePosts: feed.feed.isNotEmpty,
          isLoadingPosts: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingPosts: false));
    }
  }

  Future<void> loadMoreAuthorPosts(String actorDid) async {
    if (state is! ProfileLoaded) return;

    final currentState = state as ProfileLoaded;

    if (currentState.isLoadingMorePosts || !currentState.hasMorePosts) return;

    emit(currentState.copyWith(isLoadingMorePosts: true));

    try {
      final Set<String> seenRootUris = {};
      final List<FeedView> dedupedFeed = [];

      final newFeed = await _blueskyService.getAuthorFeed(
        actorDid,
        cursor: currentState.postsCursor,
      );

      for (final post in currentState.authorFeed!.feed) {
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

      final List<FeedView> combinedFeed = [
        ...currentState.authorFeed!.feed,
        ...dedupedFeed,
      ];

      final Feed combinedFeeds = Feed(
        feed: combinedFeed,
        cursor: newFeed.cursor,
      );

      emit(
        currentState.copyWith(
          authorFeed: combinedFeeds,
          isLoadingMorePosts: false,
          postsCursor: newFeed.cursor,
          hasMorePosts: newFeed.feed.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMorePosts: false));
    }
  }
}
