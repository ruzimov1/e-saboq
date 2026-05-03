import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../router/app_router.dart';

/// AppBar o'ng qismida — profil sahifasiga o'tish (avatar yoki bosh harf).
class AppProfileIcon extends StatelessWidget {
  const AppProfileIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => c is AuthAuthenticated || c is AuthUnauthenticated,
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        final u = state.user;
        final label = (u.name?.trim().isNotEmpty ?? false)
            ? u.name!.trim()
            : u.username;
        final initial = label.isNotEmpty
            ? String.fromCharCode(label.runes.first).toUpperCase()
            : '?';
        final cs = Theme.of(context).colorScheme;
        return IconButton(
          tooltip: 'Profil',
          onPressed: () => context.push(AppRoutes.profile),
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
