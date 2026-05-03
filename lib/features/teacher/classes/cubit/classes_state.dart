import 'package:equatable/equatable.dart';

import '../data/class_model.dart';

enum ClassesStatus { initial, loading, loaded, error }

class ClassesState extends Equatable {
  const ClassesState({
    this.status = ClassesStatus.initial,
    this.classes = const [],
    this.errorMessage,
  });

  final ClassesStatus status;
  final List<ClassModel> classes;
  final String? errorMessage;

  ClassesState copyWith({
    ClassesStatus? status,
    List<ClassModel>? classes,
    String? errorMessage,
  }) {
    return ClassesState(
      status: status ?? this.status,
      classes: classes ?? this.classes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, classes, errorMessage];
}
