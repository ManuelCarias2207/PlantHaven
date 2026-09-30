import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/core/constants/app_strings.dart';
import 'package:flutter_app/core/utils/validators.dart';
import 'package:flutter_app/views/widgets/auth_button.dart';
import 'package:flutter_app/views/widgets/auth_card.dart';
import 'package:flutter_app/views/widgets/auth_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthController>().requestPasswordReset(
      correo: _emailController.text.trim(),
    );

    if (!mounted) return;
    final controller = context.read<AuthController>();
    if (!success) {
      _showMessage(
        controller.errorMessage ?? 'No se pudo enviar la solicitud.',
      );
      return;
    }

    _showMessage(AppStrings.forgotPasswordSuccess);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) context.go(AppRoutes.resetPassword);
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      AppStrings.placeholderLogo,
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: AppStrings.forgotPasswordEmailLabel,
                        hint: AppStrings.forgotPasswordEmailHint,
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AuthButton(
                        label: AppStrings.forgotPasswordButton,
                        onPressed: _handleSubmit,
                        isLoading: controller.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
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
