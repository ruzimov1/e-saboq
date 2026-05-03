import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/class_model.dart';
import '../data/classes_repository.dart';
import 'classes_state.dart';

class ClassesCubit extends Cubit<ClassesState> {
  ClassesCubit(this._repo, {required this.subjectId})
      : super(const ClassesState());

  final ClassesRepository _repo;
  final String subjectId;

  StreamSubscription<List<ClassModel>>? _sub;

  void load() {
    _sub?.cancel();
    emit(state.copyWith(status: ClassesStatus.loading, errorMessage: null));
    _sub = _repo.watchClasses(subjectId).listen(
      (list) => emit(
        state.copyWith(status: ClassesStatus.loaded, classes: list),
      ),
      onError: (Object e, StackTrace _) {
        emit(
          state.copyWith(
            status: ClassesStatus.error,
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
