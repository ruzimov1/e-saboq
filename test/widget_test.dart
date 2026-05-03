import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edu_interactive/features/auth/bloc/auth_bloc.dart';
import 'package:edu_interactive/features/auth/data/auth_repository.dart';
import 'package:edu_interactive/features/student/assignments/data/submission_repository.dart';
import 'package:edu_interactive/features/teacher/assignments/data/assignment_repository.dart';
import 'package:edu_interactive/features/teacher/classes/data/classes_repository.dart';
import 'package:edu_interactive/features/teacher/methods/data/method_repository.dart';
import 'package:edu_interactive/features/teacher/subjects/data/subjects_repository.dart';
import 'package:edu_interactive/features/teacher/topics/data/topics_repository.dart';
import 'package:edu_interactive/main.dart';
import 'package:edu_interactive/router/app_router.dart';

void main() {
  testWidgets('App smoke — login ekrani', (WidgetTester tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => SubjectsRepository()),
          RepositoryProvider(create: (_) => ClassesRepository()),
          RepositoryProvider(create: (_) => TopicsRepository()),
          RepositoryProvider(create: (_) => MethodRepository()),
          RepositoryProvider(create: (_) => AssignmentRepository()),
          RepositoryProvider(create: (_) => SubmissionRepository()),
        ],
        child: BlocProvider(
          create: (_) => AuthBloc(authRepository: AuthRepository()),
          child: EduInteractiveApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kirish'), findsWidgets);
  });
}
