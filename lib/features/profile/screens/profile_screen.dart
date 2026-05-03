import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/minimal_teacher_list.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/auth_model.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';
import '../widgets/edit_profile_dialog.dart';
import '../../../router/app_router.dart';

/// O'qituvchi va o'quvchi uchun umumiy profil (Firestore + Auth).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.login);
          });
          return Scaffold(
            backgroundColor: MinimalTeacherList.bgOf(context),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final authUser = state.user;
        return _ProfileBody(authUser: authUser);
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.authUser});

  final AuthUser authUser;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProfileRepository>();
    return StreamBuilder<UserProfile?>(
      stream: repo.watchProfile(authUser.id),
      builder: (context, snap) {
        final p = snap.data;
        final displayName = p?.name?.trim().isNotEmpty ?? false
            ? p!.name!.trim()
            : (authUser.name?.trim().isNotEmpty ?? false)
                ? authUser.name!.trim()
                : authUser.username;
        final role = p?.role ?? authUser.role;
        final isTeacher = role == 'teacher';
        final initial = displayName.isNotEmpty
            ? String.fromCharCode(displayName.runes.first).toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: MinimalTeacherList.bgOf(context),
          appBar: MinimalTeacherList.appBar(
            context,
            'Profil',
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    _RoleChip(role: role),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => showEditProfileDialog(
                        context,
                        uid: authUser.id,
                        initial: p,
                        fallbackName: displayName,
                        isTeacher: isTeacher,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Ma\'lumotlarni tahrirlash'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionCard(
                title: 'Hisob',
                children: [
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Login',
                    value: authUser.username,
                  ),
                  if (p?.email != null && p!.email!.trim().isNotEmpty)
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: p.email!,
                    ),
                ],
              ),
              if (isTeacher) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final phone = p?.phone?.trim();
                    final org = p?.organization?.trim();
                    final children = <Widget>[
                      if (phone != null && phone.isNotEmpty)
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Telefon',
                          value: phone,
                        )
                      else
                        _EmptyHint(
                          text:
                              'Telefon hali qo\'shilmagan. Administrator yoki keyingi yangilanishda to\'ldirilishi mumkin.',
                        ),
                      if (org != null && org.isNotEmpty)
                        _InfoTile(
                          icon: Icons.apartment_outlined,
                          label: 'Tashkilot',
                          value: org,
                        ),
                    ];
                    return _SectionCard(
                      title: 'Kontakt va tashkilot',
                      children: children,
                    );
                  },
                ),
              ],
              if (!isTeacher) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Tezkor',
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.assignment_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Mening topshiriqlarim'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          context.push(AppRoutes.studentAssignments),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Hisobdan chiqish',
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Chiqish'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final text = role == 'teacher'
        ? 'O\'qituvchi'
        : role == 'student'
            ? 'O\'quvchi'
            : (role ?? 'Rol aniqlanmagan');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(MinimalTeacherList.cardRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: cs.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
