import 'package:bluesky/bluesky.dart';

abstract class FeedState {}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final Feed feeds;
  final bool isLoadingMore;
  final String? cursor;
  final bool hasMore;

  FeedLoaded(
    this.feeds, {
    this.isLoadingMore = false,
    this.cursor,
    this.hasMore = true,
  });

  FeedLoaded copyWith({
    Feed? feeds,
    bool? isLoadingMore,
    String? cursor,
    bool? hasMore,
  }) {
    return FeedLoaded(
      feeds ?? this.feeds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedError extends FeedState {
  final String message;

  FeedError(this.message);
}
