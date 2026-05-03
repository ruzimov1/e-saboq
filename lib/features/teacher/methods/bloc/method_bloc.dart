import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/method_repository.dart';
import 'method_event.dart';
import 'method_state.dart';

class MethodBloc extends Bloc<MethodEvent, MethodState> {
  MethodBloc({required MethodRepository repository})
      : _repo = repository,
        super(const MethodInitial()) {
    on<MethodLoadRequested>(_onLoad);
  }

  final MethodRepository _repo;

  Future<void> _onLoad(
    MethodLoadRequested event,
    Emitter<MethodState> emit,
  ) async {
    emit(const MethodLoading());
    try {
      final list = await _repo.fetchMethods(
        subjectId: event.subjectId,
        classId: event.classId,
        topicId: event.topicId,
      );
      emit(MethodLoaded(list));
    } catch (e) {
      emit(MethodFailure(e.toString()));
    }
  }
}
