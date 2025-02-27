import 'package:bluesky/bluesky.dart';

abstract class FeedListState {}

class FeedListInitial extends FeedListState {}

class FeedListLoading extends FeedListState {}

class FeedListLoaded extends FeedListState {
  final FeedGenerators feeds;

  FeedListLoaded(this.feeds);
}

class FeedListError extends FeedListState {
  final String message;

  FeedListError(this.message);
}
