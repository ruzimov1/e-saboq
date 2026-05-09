import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/auth_brand_gradients.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_bar_back_or_home.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/firebase_setup_banner.dart';
import '../../../core/widgets/tablet_constrained_body.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_error_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'student';

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
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
          final l10n = AppLocalizations.of(context)!;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AuthBrandGradients.scaffold),
              ),
              Positioned(
                top: -50,
                right: -30,
                child: CircleAvatar(
                  radius: 90,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: AppBarBackOrHomeLeading.leadingWidth(context),
                          child: const AppBarBackOrHomeLeading(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabletConstrainedBody(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Theme(
                            /// Gradient ochiq fon; tizim qorong‘i rejimida bo‘lsa ham form
                            /// matnlari to‘q rangda qolishi kerak.
                            data: AppTheme.light(),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppStrings.register,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.registerSubtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF424242),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  const FirebaseSetupBanner(),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _name,
                                    label: AppStrings.fullName,
                                    validator: (v) =>
                                        validateRequired(v, AppStrings.fullName),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _username,
                                    label: AppStrings.usernameLabel,
                                    keyboardType: TextInputType.text,
                                    validator: validateUsername,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _password,
                                    label: 'Parol',
                                    obscureText: true,
                                    validator: validatePassword,
                                  ),
                                  const SizedBox(height: 16),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'teacher',
                                        label: Text(AppStrings.teacher),
                                      ),
                                      ButtonSegment(
                                        value: 'student',
                                        label: Text(AppStrings.student),
                                      ),
                                    ],
                                    selected: {_role},
                                    onSelectionChanged: (s) {
                                      setState(() => _role = s.first);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  CustomButton(
                                    label: AppStrings.register,
                                    isLoading: loading,
                                    onPressed: loading
                                        ? null
                                        : () {
                                            if (_formKey.currentState
                                                    ?.validate() ??
                                                false) {
                                              context.read<AuthBloc>().add(
                                                    AuthRegisterRequested(
                                                      username: _username.text,
                                                      password: _password.text,
                                                      name: _name.text.trim(),
                                                      role: _role,
                                                    ),
                                                  );
                                            }
                                          },
                                  ),
                                  TextButton(
                                    onPressed: loading
                                        ? null
                                        : () => context.go(AppRoutes.login),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                    child: const Text(AppStrings.login),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
