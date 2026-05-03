import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';

Future<void> showEditProfileDialog(
  BuildContext context, {
  required String uid,
  required UserProfile? initial,
  required String fallbackName,
  required bool isTeacher,
}) async {
  final nameCtrl = TextEditingController(
    text: initial?.name?.trim().isNotEmpty ?? false
        ? initial!.name
        : fallbackName,
  );
  final emailCtrl = TextEditingController(text: initial?.email ?? '');
  final phoneCtrl = TextEditingController(text: initial?.phone ?? '');
  final orgCtrl = TextEditingController(text: initial?.organization ?? '');

  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profilni tahrirlash'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ism',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (ixtiyoriy)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (isTeacher) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (ixtiyoriy)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tashkilot (ixtiyoriy)',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    await context.read<ProfileRepository>().updateProfile(
          uid: uid,
          name: nameCtrl.text,
          email: emailCtrl.text,
          phone: isTeacher ? phoneCtrl.text : null,
          organization: isTeacher ? orgCtrl.text : null,
        );
    if (!context.mounted) return;
    await context.read<AuthRepository>().updateDisplayName(nameCtrl.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil yangilandi')),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  } finally {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    orgCtrl.dispose();
  }
}
