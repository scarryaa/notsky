import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/home/presentation/cubits/feed_list_state.dart';

class FeedListCubit extends Cubit<FeedListState> {
  final FeedRepository feedRepository;

  FeedListCubit({required this.feedRepository}) : super(FeedListInitial());

  void loadFeeds() async {
    if (isClosed) return;

    try {
      emit(FeedListLoading());
      final feeds = await feedRepository.getFeeds();
      if (!isClosed) {
        emit(FeedListLoaded(feeds));
      }
    } catch (e) {
      if (!isClosed) {
        emit(FeedListError(e.toString()));
      }
    }
  }
}
