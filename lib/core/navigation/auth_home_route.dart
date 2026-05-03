import '../../features/auth/data/auth_model.dart';
import '../../router/app_router.dart';

/// Saqlangan rol bo'yicha ilova "bosh sahifasi".
String homeRouteForUser(AuthUser user) {
  if (user.role == 'teacher') {
    return AppRoutes.teacherClasses;
  }
  return AppRoutes.studentJoin;
}
