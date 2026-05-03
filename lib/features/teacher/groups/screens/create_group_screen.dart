import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/groups_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated || auth.user.role != 'teacher') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O\'qituvchi sifatida kiring')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await context.read<GroupsRepository>().createGroup(
            teacherId: auth.user.id,
            name: _name.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guruh yaratildi. Kod: ${r.joinCode}')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Yangi guruh'),
        actions: const [AppProfileIcon()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Guruh nomi (masalan: 9 «A» informatika). Keyin o\'quvchilar '
                '«Guruh kodi» yoki siz login orqali qo\'shasiz.',
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _name,
                label: 'Guruh nomi',
                validator: (v) => validateRequired(v, 'Guruh nomi'),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Yaratish',
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
