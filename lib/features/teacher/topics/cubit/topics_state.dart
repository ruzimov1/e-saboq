import 'package:equatable/equatable.dart';

import '../data/topic_model.dart';

enum TopicsStatus { initial, loading, loaded, error }

class TopicsState extends Equatable {
  const TopicsState({
    this.status = TopicsStatus.initial,
    this.topics = const [],
    this.errorMessage,
  });

  final TopicsStatus status;
  final List<TopicModel> topics;
  final String? errorMessage;

  TopicsState copyWith({
    TopicsStatus? status,
    List<TopicModel>? topics,
    String? errorMessage,
  }) {
    return TopicsState(
      status: status ?? this.status,
      topics: topics ?? this.topics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, topics, errorMessage];
}
