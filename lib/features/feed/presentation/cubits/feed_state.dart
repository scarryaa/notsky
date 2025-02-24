import 'package:bluesky/bluesky.dart';

abstract class FeedState {}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final Feed feeds;

  FeedLoaded(this.feeds);
}

class FeedError extends FeedState {
  final String message;

  FeedError(this.message);
}
