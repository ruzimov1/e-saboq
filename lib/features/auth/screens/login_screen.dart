import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/auth_brand_gradients.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/firebase_setup_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_error_dialog.dart';

/// Kirish ekrani — lavender gradient, zamonaviy inputlar va CTA.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  static const _radius = 18.0;
  static const _hintColor = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final loginCtrl = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.forgotPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.forgotPasswordBody),
            const SizedBox(height: 12),
            TextField(
              controller: loginCtrl,
              decoration: InputDecoration(
                labelText: l10n.forgotPasswordLoginField,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (loginCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.forgotPasswordSubmit),
          ),
        ],
      ),
    );
    final raw = loginCtrl.text.trim();
    loginCtrl.dispose();
    if (sent != true || raw.isEmpty || !mounted) return;
    try {
      await context.read<AuthRepository>().sendPasswordResetEmail(raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.forgotPasswordSent),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.purple.shade50),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: Colors.purple.shade200, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showAuthFailureFeedback(context, state);
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AuthBrandGradients.scaffold,
                ),
              ),
              Positioned(
                top: -60,
                right: -40,
                child: CircleAvatar(
                  radius: 110,
                  backgroundColor: Colors.deepPurple.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -50,
                child: CircleAvatar(
                  radius: 90,
                  backgroundColor: Colors.purple.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                top: 140,
                left: 40,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            elevation: 2,
                            shadowColor: Colors.deepPurple.withValues(alpha: 0.15),
                            child: SizedBox(
                              width: 112,
                              height: 112,
                              child: Image.asset(
                                'assets/images/e_saboq_logo.png',
                                fit: BoxFit.contain,
                                semanticLabel: AppStrings.appName,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.login,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hisobingizga kiring',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.purple.shade400,
                              ),
                        ),
                        const SizedBox(height: 28),
                        const FirebaseSetupBanner(),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_radius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _username,
                            cursorColor: AppColors.primary,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            validator: validateUsername,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textFieldInput,
                            ),
                            decoration: _fieldDecoration(
                              hint: 'Login nomingiz',
                              prefix: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.purple.shade400,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_radius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _password,
                            cursorColor: AppColors.primary,
                            obscureText: _obscurePassword,
                            obscuringCharacter: '•',
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!loading &&
                                  (_formKey.currentState?.validate() ?? false)) {
                                context.read<AuthBloc>().add(
                                      AuthLoginRequested(
                                        username: _username.text,
                                        password: _password.text,
                                      ),
                                    );
                              }
                            },
                            autofillHints: const [AutofillHints.password],
                            validator: validatePassword,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textFieldInput,
                            ),
                            decoration: _fieldDecoration(
                              hint: 'Parolingiz',
                              prefix: Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.purple.shade400,
                                size: 22,
                              ),
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Parolni ko‘rsatish'
                                    : 'Yashirish',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.purple.shade400,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: loading ? null : _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Parolni unutdingizmi?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Material(
                          elevation: 6,
                          shadowColor: Colors.deepPurple.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(_radius),
                          child: InkWell(
                            onTap: loading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      context.read<AuthBloc>().add(
                                            AuthLoginRequested(
                                              username: _username.text,
                                              password: _password.text,
                                            ),
                                          );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(_radius),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color.alphaBlend(
                                      Colors.white.withValues(alpha: 0.22),
                                      AppColors.primary,
                                    ),
                                    AppColors.primary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(_radius),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: loading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        AppStrings.login,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hisobingiz yo‘qmi? ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => context.go(AppRoutes.register),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                AppStrings.register,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
