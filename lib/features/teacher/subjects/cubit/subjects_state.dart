import 'package:equatable/equatable.dart';

import '../data/subject_model.dart';

enum SubjectsStatus { initial, loading, loaded, error }

class SubjectsState extends Equatable {
  const SubjectsState({
    this.status = SubjectsStatus.initial,
    this.subjects = const [],
    this.errorMessage,
  });

  final SubjectsStatus status;
  final List<SubjectModel> subjects;
  final String? errorMessage;

  SubjectsState copyWith({
    SubjectsStatus? status,
    List<SubjectModel>? subjects,
    String? errorMessage,
  }) {
    return SubjectsState(
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, subjects, errorMessage];
}
