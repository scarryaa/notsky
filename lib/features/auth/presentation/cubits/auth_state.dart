import 'package:atproto_core/atproto_core.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final Session session;
  const AuthSuccess(this.session);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
