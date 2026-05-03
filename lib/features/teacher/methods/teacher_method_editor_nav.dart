import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../../../router/method_route_args.dart';
import 'data/method_model.dart';

/// O'qituvchi: metod turiga mos tahrir ekranini ochadi.
Future<void> pushTeacherMethodEditorScreen(
  BuildContext context,
  MethodModel m, {
  required String subjectId,
  required String classId,
  required String topicId,
}) async {
  final args = MethodRouteArgs(
    subjectId: subjectId,
    classId: classId,
    topicId: topicId,
    methodId: m.id,
  );
  final t = m.type;
  if (t == 'quiz') {
    await context.push(AppRoutes.teacherQuiz, extra: args);
  } else if (t == 'poll') {
    await context.push(AppRoutes.teacherPoll, extra: args);
  } else if (t == 'brainstorm') {
    await context.push(AppRoutes.teacherBrainstorm, extra: args);
  } else if (t == 'case') {
    await context.push(AppRoutes.teacherCase, extra: args);
  } else if (t == 'group') {
    await context.push(AppRoutes.teacherGroup, extra: args);
  } else if (t == 'role_play') {
    await context.push(AppRoutes.teacherRolePlay, extra: args);
  } else if (t == 'fishbone') {
    await context.push(AppRoutes.teacherFishbone, extra: args);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Noma\'lum metod: ${m.type}')),
      );
    }
  }
}
