import 'package:notsky/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/data/repositories/bluesky_feed_repository.dart';
import 'package:notsky/features/feed/data/services/bluesky_service_impl.dart';
import 'package:notsky/features/feed/domain/repositories/feed_repository.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';

class FeedRepositoryProvider {
  static FeedRepository provideFeedRepository(
    AuthState authState,
    AuthCubit authCubit,
  ) {
    if (authState is AuthSuccess) {
      final BlueskyService blueskyService = BlueskyServiceImpl(
        authState.session,
        authCubit,
      );
      return BlueskyFeedRepository(blueskyService);
    } else {
      throw Exception('User must be authenticated to access feed repository');
    }
  }
}
