import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../router/app_router.dart';
import '../navigation/auth_home_route.dart';

/// Bosh sahifa (o'qituvchi: sinflar, o'quvchi: kod bilan kirish).
class AppHomeIcon extends StatelessWidget {
  const AppHomeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => c is AuthAuthenticated || c is AuthUnauthenticated,
      builder: (context, state) {
        final path = state is AuthAuthenticated
            ? homeRouteForUser(state.user)
            : AppRoutes.login;
        return IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Bosh sahifa',
          onPressed: () => context.go(path),
        );
      },
    );
  }
}
