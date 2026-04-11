import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithApple extends AuthEvent {}

class AuthSignInWithGithub extends AuthEvent {}

class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignInWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthSignUpWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOut extends AuthEvent {}
