import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.username, required this.password});

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.username,
    required this.password,
    required this.name,
    required this.role,
  });

  final String username;
  final String password;
  final String name;
  final String role;

  @override
  List<Object?> get props => [username, password, name, role];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
