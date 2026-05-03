import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/student/assignments/screens/solve_assignment_screen.dart';
import '../features/student/assignments/screens/student_assignments_screen.dart';
import '../features/student/assignments/screens/student_submission_detail_screen.dart';
import '../features/student/join/screens/join_screen.dart';
import '../features/teacher/assignments/data/assignment_lookup.dart';
import '../features/teacher/assignments/screens/assignment_results_screen.dart';
import '../features/teacher/methods/screens/method_assignments_screen.dart';
import '../features/teacher/assignments/screens/assignments_screen.dart';
import '../features/teacher/assignments/screens/create_assignment_screen.dart';
import '../features/teacher/assignments/screens/brainstorm_question_bank_screen.dart';
import '../features/teacher/assignments/screens/create_brainstorm_task_screen.dart';
import '../features/teacher/assignments/screens/edit_assignment_screen.dart';
import '../features/teacher/classes/screens/create_class_screen.dart';
import '../features/teacher/classes/screens/teacher_classes_root_screen.dart';
import '../features/teacher/methods/bloc/method_bloc.dart';
import '../features/teacher/methods/data/method_repository.dart';
import '../features/teacher/methods/screens/brainstorm_screen.dart';
import '../features/teacher/methods/screens/case_study_screen.dart';
import '../features/teacher/methods/screens/case_study_teacher_dashboard_screen.dart';
import '../features/teacher/methods/screens/fishbone_method_screen.dart';
import '../features/teacher/methods/screens/group_work_screen.dart';
import '../features/teacher/methods/screens/role_play_screen.dart';
import '../features/teacher/methods/screens/methods_screen.dart';
import '../features/teacher/methods/screens/poll_method_screen.dart';
import '../features/teacher/methods/screens/quiz_method_screen.dart';
import '../features/teacher/subjects/cubit/subjects_cubit.dart';
import '../features/teacher/subjects/data/subjects_repository.dart';
import '../features/teacher/subjects/screens/create_subject_screen.dart';
import '../features/teacher/subjects/screens/subjects_screen.dart';
import '../features/teacher/topics/cubit/topics_cubit.dart';
import '../features/teacher/topics/data/topics_repository.dart';
import '../features/teacher/topics/screens/create_topic_screen.dart';
import '../features/teacher/topics/screens/topics_screen.dart';
import '../features/teacher/groups/screens/create_group_screen.dart';
import '../features/teacher/groups/screens/group_detail_screen.dart';
import '../features/teacher/groups/screens/groups_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'assignment_route_args.dart';
import 'method_route_args.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  /// O'qituvchi bosh sahifasi: sinflar (keyin → fan → mavzu → metod).
  static const teacherClasses = '/teacher/classes';
  static const teacherCreateSubject = '/teacher/subjects/create';

  static String teacherClassSubjects(String classId) =>
      '/teacher/classes/$classId/subjects';

  static String teacherCreateClass(String subjectId) =>
      '/teacher/subjects/$subjectId/classes/create';

  static String teacherClassTopics(String classId, String subjectId) =>
      '/teacher/classes/$classId/subjects/$subjectId/topics';

  static String teacherCreateTopic(String classId, String subjectId) =>
      '/teacher/classes/$classId/subjects/$subjectId/topics/create';

  static String teacherTopicMethods(
    String classId,
    String subjectId,
    String topicId,
  ) =>
      '/teacher/classes/$classId/subjects/$subjectId/topics/$topicId/methods';

  static const teacherQuiz = '/teacher/methods/quiz';
  static const teacherPoll = '/teacher/methods/poll';
  static const teacherBrainstorm = '/teacher/methods/brainstorm';
  static const teacherCase = '/teacher/methods/case';
  static const teacherCaseDashboard = '/teacher/methods/case/dashboard';
  static const teacherGroup = '/teacher/methods/group';
  static const teacherRolePlay = '/teacher/methods/role-play';
  static const teacherFishbone = '/teacher/methods/fishbone';
  static const teacherAssignments = '/teacher/assignments';
  static const teacherCreateAssignment = '/teacher/assignments/create';
  static const teacherCreateBrainstormTask = '/teacher/assignments/create-brainstorm';
  static const teacherBrainstormQuestionBank = '/teacher/assignments/brainstorm-question-bank';
  static const teacherEditAssignment = '/teacher/assignments/edit';
  static const teacherAssignmentResults = '/teacher/assignments/results';
  static const teacherGroups = '/teacher/groups';
  static const teacherCreateGroup = '/teacher/groups/create';

  static String teacherGroupDetail(String groupId) =>
      '/teacher/groups/$groupId';

  static String teacherMethodAssignmentsList(
    String classId,
    String subjectId,
    String topicId,
    String methodId,
  ) =>
      '/teacher/classes/$classId/subjects/$subjectId/topics/$topicId/methods/$methodId/assignments-list';
  static const studentJoin = '/student/join';
  static const studentAssignments = '/student/assignments';
  static const studentSolve = '/student/assignments/solve';
  static const studentSubmission = '/student/assignments/submission';
  static const profile = '/profile';
}

String _teacherId(BuildContext context) {
  final s = context.read<AuthBloc>().state;
  return s is AuthAuthenticated ? s.user.id : '';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (BuildContext context, GoRouterState state) {
      if (state.uri.path == '/teacher/subjects') {
        return AppRoutes.teacherClasses;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherClasses,
        builder: (context, state) => const TeacherClassesRootScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherCreateSubject,
        builder: (context, state) => const CreateSubjectScreen(),
      ),
      GoRoute(
        path: '/teacher/subjects/:subjectId/classes/create',
        builder: (context, state) {
          final sid = state.pathParameters['subjectId']!;
          return CreateClassScreen(subjectId: sid);
        },
      ),
      GoRoute(
        path: '/teacher/classes/:classId/subjects',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final tid = _teacherId(context);
          return BlocProvider(
            create: (_) => SubjectsCubit(
              context.read<SubjectsRepository>(),
              teacherId: tid,
            )..load(),
            child: SubjectsScreen(classId: classId),
          );
        },
      ),
      GoRoute(
        path: '/teacher/classes/:classId/subjects/:subjectId/topics',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final subjectId = state.pathParameters['subjectId']!;
          return BlocProvider(
            create: (_) => TopicsCubit(
              context.read<TopicsRepository>(),
              subjectId: subjectId,
              classId: classId,
            )..load(),
            child: TopicsScreen(subjectId: subjectId, classId: classId),
          );
        },
      ),
      GoRoute(
        path: '/teacher/classes/:classId/subjects/:subjectId/topics/create',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final subjectId = state.pathParameters['subjectId']!;
          return CreateTopicScreen(subjectId: subjectId, classId: classId);
        },
      ),
      GoRoute(
        path:
            '/teacher/classes/:classId/subjects/:subjectId/topics/:topicId/methods',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final subjectId = state.pathParameters['subjectId']!;
          final topicId = state.pathParameters['topicId']!;
          return BlocProvider(
            create: (_) => MethodBloc(
              repository: context.read<MethodRepository>(),
            ),
            child: MethodsScreen(
              subjectId: subjectId,
              classId: classId,
              topicId: topicId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teacherQuiz,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return QuizMethodScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherPoll,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return PollMethodScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherBrainstorm,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return BrainstormScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherCase,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return CaseStudyScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherCaseDashboard,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return CaseStudyTeacherDashboardScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherGroup,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return GroupWorkScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherRolePlay,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return RolePlayScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherFishbone,
        builder: (context, state) {
          final extra = state.extra as MethodRouteArgs?;
          return FishboneMethodScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherCreateAssignment,
        builder: (context, state) {
          final extra = state.extra as AssignmentRouteArgs?;
          return CreateAssignmentScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherCreateBrainstormTask,
        builder: (context, state) {
          final extra = state.extra as CreateBrainstormTaskRouteArgs?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Parametrlar yo‘q')),
            );
          }
          return CreateBrainstormTaskScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherBrainstormQuestionBank,
        name: 'teacherBrainstormQuestionBank',
        builder: (context, state) {
          final extra = state.extra as BrainstormQuestionBankRouteArgs?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Parametrlar yo‘q')),
            );
          }
          return BrainstormQuestionBankScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherEditAssignment,
        builder: (context, state) {
          final extra = state.extra as AssignmentRouteArgs?;
          if (extra?.assignmentId == null || extra!.assignmentId!.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Topshiriq tanlanmagan')),
            );
          }
          return EditAssignmentScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherAssignmentResults,
        builder: (context, state) {
          final extra = state.extra as AssignmentRouteArgs?;
          return AssignmentResultsScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherAssignments,
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherGroups,
        builder: (context, state) => const GroupsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacherCreateGroup,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/teacher/groups/:groupId',
        builder: (context, state) {
          final gid = state.pathParameters['groupId']!;
          return GroupDetailScreen(groupId: gid);
        },
      ),
      GoRoute(
        path:
            '/teacher/classes/:classId/subjects/:subjectId/topics/:topicId/methods/:methodId/assignments-list',
        builder: (context, state) {
          final classId = state.pathParameters['classId']!;
          final subjectId = state.pathParameters['subjectId']!;
          final topicId = state.pathParameters['topicId']!;
          final methodId = state.pathParameters['methodId']!;
          return MethodAssignmentsScreen(
            subjectId: subjectId,
            classId: classId,
            topicId: topicId,
            methodId: methodId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studentJoin,
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentAssignments,
        builder: (context, state) => const StudentAssignmentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentSolve,
        builder: (context, state) {
          final extra = state.extra as AssignmentLookup?;
          return SolveAssignmentScreen(lookup: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.studentSubmission,
        builder: (context, state) {
          final extra = state.extra as AssignmentLookup?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Parametrlar yo\'q')),
            );
          }
          return StudentSubmissionDetailScreen(initialLookup: extra);
        },
      ),
    ],
  );
}
