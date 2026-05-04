import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/curriculum/curriculum_word_assignments.dart';
import 'core/curriculum/curriculum_word_method_presets.dart';
import 'core/curriculum/informatika_json_presets.dart';
import 'core/navigation/auth_home_route.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/network_status_banner_host.dart';
import 'l10n/app_localizations.dart';
import 'features/student/assignments/data/submission_repository.dart';
import 'firebase/firebase_bootstrap.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/teacher/assignments/data/assignment_repository.dart';
import 'features/teacher/groups/data/groups_repository.dart';
import 'features/teacher/classes/data/classes_repository.dart';
import 'features/teacher/methods/data/method_repository.dart';
import 'features/teacher/subjects/data/subjects_repository.dart';
import 'features/teacher/topics/data/topics_repository.dart';
import 'features/profile/data/profile_repository.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env ixtiyoriy
  }

  try {
    await CurriculumWordAssignments.loadFromAssets();
    await CurriculumWordMethodPresets.loadFromAssets();
    await InformatikaJsonPresets.loadFromAssets();
  } catch (_) {}

  await bootstrapFirebase();

  final authRepository = AuthRepository();
  final router = createAppRouter();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider(create: (_) => SubjectsRepository()),
        RepositoryProvider(create: (_) => ClassesRepository()),
        RepositoryProvider(create: (_) => TopicsRepository()),
        RepositoryProvider(create: (_) => MethodRepository()),
        RepositoryProvider(create: (_) => AssignmentRepository()),
        RepositoryProvider(create: (_) => GroupsRepository()),
        RepositoryProvider(create: (_) => SubmissionRepository()),
        RepositoryProvider(create: (_) => ProfileRepository()),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: authRepository)
          ..add(const AuthCheckRequested()),
        child: EduInteractiveApp(router: router),
      ),
    ),
  );
}

class EduInteractiveApp extends StatelessWidget {
  const EduInteractiveApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        if (current is AuthAuthenticated) {
          return previous is AuthLoading ||
              previous is AuthUnauthenticated ||
              previous is AuthInitial ||
              previous is AuthFailure;
        }
        if (current is AuthUnauthenticated) {
          return previous is AuthAuthenticated || previous is AuthLoading;
        }
        return false;
      },
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          router.go(homeRouteForUser(state.user));
        }
        if (state is AuthUnauthenticated) {
          router.go(AppRoutes.login);
        }
      },
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: const Locale('uz'),
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: (locales, supported) {
          for (final locale in locales ?? const <Locale>[]) {
            for (final s in supported) {
              if (s.languageCode == locale.languageCode) return s;
            }
          }
          return const Locale('uz');
        },
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) {
          return NetworkStatusBannerHost(
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: router,
      ),
    );
  }
}
