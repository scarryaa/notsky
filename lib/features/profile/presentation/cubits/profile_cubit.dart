import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:notsky/features/profile/presentation/cubits/post_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._blueskyService) : super(ProfileInitial());

  BlueskyService _blueskyService;

  void updateService(BlueskyService bskyService) {
    _blueskyService = bskyService;
  }

  Future<void> getProfile(String did) async {
    try {
      emit(ProfileLoading());
      final profile = await _blueskyService.getProfile(did);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
