import 'package:flutter/material.dart';

import '../bloc/auth_state.dart';

void showAuthFailureFeedback(BuildContext context, AuthFailure state) {
  final msg = state.message;
  final looksLikeFirebase = msg.contains('Firebase') ||
      msg.contains('flutterfire') ||
      msg.contains('initializeApp');

  if (looksLikeFirebase) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firebase sozlanmagan'),
        content: SingleChildScrollView(
          child: SelectableText(msg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tushunarli'),
          ),
        ],
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}
