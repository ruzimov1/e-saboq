import 'package:equatable/equatable.dart';

import '../data/method_model.dart';

sealed class MethodState extends Equatable {
  const MethodState();

  @override
  List<Object?> get props => [];
}

final class MethodInitial extends MethodState {
  const MethodInitial();
}

final class MethodLoading extends MethodState {
  const MethodLoading();
}

final class MethodLoaded extends MethodState {
  const MethodLoaded(this.methods);

  final List<MethodModel> methods;

  @override
  List<Object?> get props => [methods];
}

final class MethodFailure extends MethodState {
  const MethodFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
