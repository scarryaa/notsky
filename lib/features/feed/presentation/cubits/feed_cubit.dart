import 'package:atproto_core/atproto_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/data/providers/feed_repository_provider.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/feed/presentation/cubits/feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepository _feedRepository;

  FeedCubit(AuthState authState, AuthCubit authCubit)
    : _feedRepository = FeedRepositoryProvider.provideFeedRepository(
        authState,
        authCubit,
      ),
      super(FeedInitial());

  Future<void> loadFeed({AtUri? generatorUri}) async {
    try {
      emit(FeedLoading());
      final feeds =
          generatorUri != null
              ? await _feedRepository.getFeed(generatorUri: generatorUri)
              : await _feedRepository.getTimeline();
      emit(FeedLoaded(feeds));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> loadTimeline() async {
    try {
      emit(FeedLoading());
      final feeds = await _feedRepository.getTimeline();
      emit(FeedLoaded(feeds));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }
}
