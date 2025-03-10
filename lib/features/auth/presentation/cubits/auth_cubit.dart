import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/atproto.dart';
import 'package:bluesky/bluesky.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notsky/features/auth/presentation/cubits/auth_state.dart';
import 'package:notsky/features/feed/data/services/bluesky_service_impl.dart';
import 'package:notsky/features/feed/domain/services/bluesky_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  BlueskyService getBlueskyService() {
    if (state is AuthSuccess) {
      return BlueskyServiceImpl((state as AuthSuccess).session, this);
    } else {
      throw Exception('Cannot get BlueskyService: User not authenticated');
    }
  }

  Future<void> login(String identifier, String password) async {
    try {
      emit(AuthLoading());

      final session = await createSession(
        service: 'bsky.social',
        identifier: identifier,
        password: password,
      );

      await _saveSession(session.data);

      emit(AuthSuccess(session.data, profile: null));
      final profile = await getBlueskyService().getProfile(session.data.did);
      emit(AuthSuccess(session.data, profile: profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      emit(AuthLoading());
      await _clearSession();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> refreshUserSession(String refreshJwt) async {
    try {
      emit(AuthLoading());
      final session = await refreshSession(refreshJwt: refreshJwt);
      await _saveSession(session.data);
      emit(AuthSuccess(session.data));
      final profile = await getBlueskyService().getProfile(session.data.did);
      emit(AuthSuccess(session.data, profile: profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());
      final savedSession = await _getSavedSession();

      if (savedSession != null) {
        final bluesky = Bluesky.fromSession(savedSession);
        if (bluesky.session!.active) {
          emit(AuthSuccess(savedSession));

          final profile = await getBlueskyService().getProfile(
            savedSession.did,
          );
          emit(AuthSuccess(savedSession, profile: profile));
        } else {
          await _clearSession();
          emit(AuthInitial());
        }
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('session', [
      session.accessJwt,
      session.refreshJwt,
      session.handle,
      session.did,
      session.email ?? '',
    ]);
  }

  Future<Session?> _getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getStringList('session');

    if (sessionData != null && sessionData.length >= 4) {
      return Session(
        accessJwt: sessionData[0],
        refreshJwt: sessionData[1],
        handle: sessionData[2],
        did: sessionData[3],
        email: sessionData[4].isEmpty ? null : sessionData[4],
      );
    }
    return null;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
  }
}
