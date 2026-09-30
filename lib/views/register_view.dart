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

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+503 ');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _termsAccepted = false;
  final bool _showPasswordStrength = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.validationTerms),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = context.read<AuthController>();
    final success = await controller.register(
      nombre: _firstNameController.text.trim(),
      apellido: _lastNameController.text.trim(),
      correo: _emailController.text.trim(),
      telefono: _phoneController.text.trim(),
      contrasena: _passwordController.text,
      confirmarContrasena: _confirmPasswordController.text,
    );

    if (success && mounted) {
      context.go(AppRoutes.catalog);
    }
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Logo
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
                // Título
                Text(
                  AppStrings.registerTitle,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtítulo
                Text(
                  AppStrings.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // Tarjeta del formulario
                AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombres y Apellidos en una fila
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: AppStrings.registerNameLabel,
                              hint: AppStrings.registerNameHint,
                              icon: Icons.person_outline,
                              controller: _firstNameController,
                              validator: Validators.required,
                              enabled: !controller.isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              label: AppStrings.registerLastNameLabel,
                              hint: AppStrings.registerLastNameHint,
                              icon: Icons.person_outline,
                              controller: _lastNameController,
                              validator: Validators.required,
                              enabled: !controller.isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Teléfono con prefijo +503
                      AuthTextField(
                        label: AppStrings.registerPhoneLabel,
                        hint: AppStrings.registerPhoneHint,
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 18),
                      // Correo
                      AuthTextField(
                        label: AppStrings.registerEmailLabel,
                        hint: AppStrings.registerEmailHint,
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 18),
                      // Contraseña
                      AuthTextField(
                        label: AppStrings.registerPasswordLabel,
                        hint: AppStrings.registerPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: Validators.password,
                        enabled: !controller.isLoading,
                      ),
                      // Indicador de fortaleza de contraseña
                      if (_showPasswordStrength)
                        PasswordStrengthIndicator(
                          password: _passwordController.text,
                        ),
                      const SizedBox(height: 18),
                      // Confirmar contraseña
                      AuthTextField(
                        label: AppStrings.registerConfirmPasswordLabel,
                        hint: AppStrings.registerConfirmPasswordHint,
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        isPassword: true,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        enabled: !controller.isLoading,
                      ),
                      const SizedBox(height: 16),
                      // Checkbox de términos y condiciones
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _termsAccepted,
                              onChanged: controller.isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _termsAccepted = value ?? false;
                                      });
                                    },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _termsAccepted = !_termsAccepted;
                                      });
                                    },
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: AppStrings.registerTerms,
                                    ),
                                    TextSpan(
                                      text: AppStrings.registerTermsLink,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                      // Botón de registro
                      AuthButton(
                        label: AppStrings.registerButton,
                        onPressed: _handleRegister,
                        isLoading: controller.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Footer - ir a login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.registerFooterHaveAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        AppStrings.registerFooterLogin,
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
