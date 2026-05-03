import 'package:equatable/equatable.dart';

sealed class MethodEvent extends Equatable {
  const MethodEvent();

  @override
  List<Object?> get props => [];
}

final class MethodLoadRequested extends MethodEvent {
  const MethodLoadRequested({
    required this.subjectId,
    required this.classId,
    required this.topicId,
  });

  final String subjectId;
  final String classId;
  final String topicId;

  @override
  List<Object?> get props => [subjectId, classId, topicId];
}
