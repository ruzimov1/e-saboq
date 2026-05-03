import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../teacher/assignments/data/assignment_repository.dart';
import '../../../teacher/groups/data/groups_repository.dart';

/// Tartib: 1) tizimga kirish talab qilinadi; 2) topshiriq kodi yoki guruh kodi.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _assignmentCode = TextEditingController();
  final _assignmentFocus = FocusNode();
  final _groupCode = TextEditingController();
  final _groupFocus = FocusNode();
  bool _loadingA = false;
  bool _loadingG = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _assignmentCode.dispose();
    _assignmentFocus.dispose();
    _groupCode.dispose();
    _groupFocus.dispose();
    super.dispose();
  }

  String _firebaseMessage(AppLocalizations l10n, Object e) {
    if (e is FirebaseException) {
      if (e.code == 'failed-precondition') {
        return l10n.firebaseErrorIndexBuilding;
      }
      if (e.code == 'permission-denied') {
        return l10n.firebaseErrorPermissionStudent;
      }
      return e.message ?? e.code;
    }
    return e.toString();
  }

  Future<void> _joinAssignment() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackLoginForAssignment)),
      );
      return;
    }
    final raw = _assignmentCode.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackEnterCode)),
      );
      return;
    }
    setState(() => _loadingA = true);
    try {
      final repo = context.read<AssignmentRepository>();
      final found = await repo.findAssignmentByCode(raw);
      if (!mounted) return;
      if (found == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.joinSnackCodeInvalid)),
        );
        return;
      }
      context.push(AppRoutes.studentSolve, extra: found);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_firebaseMessage(AppLocalizations.of(context)!, e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_firebaseMessage(AppLocalizations.of(context)!, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingA = false);
    }
  }

  Future<void> _joinGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackLoginForGroup)),
      );
      return;
    }
    if (auth.user.role != 'student') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackGroupStudentOnly)),
      );
      return;
    }
    final raw = _groupCode.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackEnterGroupCode)),
      );
      return;
    }
    setState(() => _loadingG = true);
    try {
      await context.read<GroupsRepository>().joinGroupWithCode(
            studentId: auth.user.id,
            rawCode: raw,
          );
      if (!mounted) return;
      _groupCode.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.joinSnackGroupJoined)),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_firebaseMessage(AppLocalizations.of(context)!, e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingG = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthBloc>().state;
    final asStudent =
        auth is AuthAuthenticated && auth.user.role == 'student';
    final loggedIn = auth is AuthAuthenticated;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text(l10n.joinByCode),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.joinTabAssignmentCode),
            Tab(text: l10n.joinTabGroupCode),
          ],
        ),
        actions: const [AppProfileIcon()],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          TabletConstrainedBody(
            child: _assignmentTab(context, l10n, loggedIn, asStudent),
          ),
          TabletConstrainedBody(
            child: _groupTab(context, l10n, asStudent),
          ),
        ],
      ),
    );
  }

  Widget _assignmentTab(
    BuildContext context,
    AppLocalizations l10n,
    bool loggedIn,
    bool asStudent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!loggedIn)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                title: Text(l10n.joinLoginCardTitle),
                subtitle: Text(l10n.joinLoginCardSubtitleAssignment),
              ),
            )
          else ...[
            Text(l10n.joinAssignmentIntro),
            if (!asStudent) ...[
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  dense: true,
                  title: Text(l10n.joinTeacherPreviewTitle),
                  subtitle: Text(l10n.joinTeacherPreviewSubtitle),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          CustomTextField(
            controller: _assignmentCode,
            focusNode: _assignmentFocus,
            autofocus: true,
            label: l10n.joinFieldAssignmentCode,
            hint: l10n.joinFieldAssignmentHint,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (_) {
              if (!_loadingA) _joinAssignment();
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: l10n.joinOpenAssignment,
            isLoading: _loadingA,
            onPressed: (_loadingA || !loggedIn) ? null : _joinAssignment,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadingA
                ? null
                : () => context.push(AppRoutes.studentAssignments),
            child: Text(l10n.myAssignments),
          ),
        ],
      ),
    );
  }

  Widget _groupTab(
    BuildContext context,
    AppLocalizations l10n,
    bool asStudent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.joinGroupIntro),
          const SizedBox(height: 16),
          if (!asStudent)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                title: Text(l10n.joinStudentOnlyCardTitle),
              ),
            ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _groupCode,
            focusNode: _groupFocus,
            label: l10n.joinFieldGroupCode,
            hint: l10n.joinFieldGroupHint,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (_) {
              if (!_loadingG) _joinGroup();
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: l10n.joinGroupSubmit,
            isLoading: _loadingG,
            onPressed: (_loadingG || !asStudent) ? null : _joinGroup,
          ),
        ],
      ),
    );
  }
}
