import 'package:atproto_core/atproto_core.dart';
import 'package:bluesky/bluesky.dart';

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
  final ActorProfile? profile;

  const AuthSuccess(this.session, {this.profile});
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
