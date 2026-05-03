import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/subject_model.dart';
import '../data/subjects_repository.dart';
import 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit(this._repo, {required this.teacherId})
      : super(const SubjectsState());

  final SubjectsRepository _repo;
  final String teacherId;

  StreamSubscription<List<SubjectModel>>? _sub;

  void load() {
    _sub?.cancel();
    emit(state.copyWith(status: SubjectsStatus.loading, errorMessage: null));
    _sub = _repo.watchSubjects(teacherId).listen(
      (list) => emit(
        state.copyWith(status: SubjectsStatus.loaded, subjects: list),
      ),
      onError: (Object e, StackTrace _) {
        emit(
          state.copyWith(
            status: SubjectsStatus.error,
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
