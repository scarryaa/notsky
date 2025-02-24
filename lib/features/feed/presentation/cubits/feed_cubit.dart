import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/data/providers/feed_repository_provider.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepository _feedRepository;

  FeedCubit(AuthState authState)
    : _feedRepository = FeedRepositoryProvider.provideFeedRepository(authState),
      super(FeedInitial());

  Future<void> loadFeed() async {
    try {
      emit(FeedLoading());
      final feeds = await _feedRepository.getFeed();
      emit(FeedLoaded(feeds));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }
}
