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

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AuthController>();
    final success = await controller.login(
      identificador: _identifierController.text.trim(),
      contrasena: _passwordController.text,
    );

    if (success && mounted) {
      context.go(controller.defaultAuthenticatedRoute);
    }
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Logo
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
                // Título
                Text(
                  AppStrings.loginTitle,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtítulo
                Text(
                  AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Tarjeta del formulario
                AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de identificador (correo o teléfono)
                      AuthTextField(
                        label: AppStrings.loginIdentifierLabel,
                        hint: AppStrings.loginIdentifierHint,
                        icon: Icons.person_outline,
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.required,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 20),
                      // Campo de contraseña
                      AuthTextField(
                        label: AppStrings.loginPasswordLabel,
                        hint: AppStrings.loginPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: Validators.required,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 12),
                      // Enlace de recuperar contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push(AppRoutes.forgotPassword);
                          },
                          child: Text(
                            AppStrings.loginForgotPassword,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Error message
                      if (controller.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Botón de login
                      AuthButton(
                        label: AppStrings.loginButton,
                        onPressed: _handleLogin,
                        isLoading: controller.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Footer - ir a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.loginFooterNoAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        AppStrings.loginFooterRegister,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
