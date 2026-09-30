import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/core/constants/app_strings.dart';
import 'package:flutter_app/core/utils/validators.dart';
import 'package:flutter_app/views/widgets/auth_button.dart';
import 'package:flutter_app/views/widgets/auth_card.dart';
import 'package:flutter_app/views/widgets/auth_text_field.dart';
import 'package:flutter_app/views/widgets/password_strength_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordState);
    _confirmController.addListener(_refreshPasswordState);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordState);
    _confirmController.removeListener(_refreshPasswordState);
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _refreshPasswordState() {
    if (mounted) setState(() {});
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthController>().resetPassword(
      token: _tokenController.text.trim(),
      nuevaContrasena: _passwordController.text,
      confirmarContrasena: _confirmController.text,
    );

    if (!mounted) return;
    final controller = context.read<AuthController>();
    if (!success) {
      _showMessage(
        controller.errorMessage ?? 'No se pudo actualizar la contrasena.',
      );
      return;
    }

    _showMessage(AppStrings.resetPasswordSuccess);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) context.go(AppRoutes.login);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      AppStrings.placeholderLogo,
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.resetPasswordTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.resetPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: AppStrings.resetPasswordCodeLabel,
                        hint: AppStrings.resetPasswordCodeHint,
                        icon: Icons.password_outlined,
                        controller: _tokenController,
                        validator: Validators.required,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        label: AppStrings.resetPasswordNewLabel,
                        hint: AppStrings.registerPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: Validators.password,
                        enabled: !controller.isLoading,
                      ),
                      PasswordStrengthIndicator(
                        password: _passwordController.text,
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        label: AppStrings.resetPasswordConfirmLabel,
                        hint: AppStrings.registerConfirmPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _confirmController,
                        isPassword: true,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthButton(
                        label: AppStrings.resetPasswordButton,
                        onPressed: _handleSubmit,
                        isLoading: controller.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppStrings.resetPasswordBack),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
