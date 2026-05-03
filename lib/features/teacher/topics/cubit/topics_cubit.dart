import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/topic_model.dart';
import '../data/topics_repository.dart';
import 'topics_state.dart';

class TopicsCubit extends Cubit<TopicsState> {
  TopicsCubit(
    this._repo, {
    required this.subjectId,
    required this.classId,
  }) : super(const TopicsState());

  final TopicsRepository _repo;
  final String subjectId;
  final String classId;

  StreamSubscription<List<TopicModel>>? _sub;

  void load() {
    _sub?.cancel();
    emit(state.copyWith(status: TopicsStatus.loading, errorMessage: null));
    _sub = _repo
        .watchTopics(subjectId: subjectId, classId: classId)
        .listen(
      (list) => emit(
        state.copyWith(status: TopicsStatus.loaded, topics: list),
      ),
      onError: (Object e, StackTrace _) {
        emit(
          state.copyWith(
            status: TopicsStatus.error,
            errorMessage: e.toString(),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
