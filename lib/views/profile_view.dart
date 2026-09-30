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

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final controller = context.read<AuthController>();
    final user = controller.currentUser;
    if (user != null) {
      _firstNameController.text = user.nombre;
      _lastNameController.text = user.apellido;
      _emailController.text = user.correo;
      _phoneController.text = user.telefono;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = context.read<AuthController>();
    final success = await controller.updateProfile(
      nombre: _firstNameController.text.trim(),
      apellido: _lastNameController.text.trim(),
      correo: _emailController.text.trim(),
      telefono: _phoneController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (success) {
        _isEditing = false;
      }
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.profileUpdateSuccess),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final controller = context.read<AuthController>();
    await controller.logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final user = controller.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.profileTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    AppStrings.placeholderLogo,
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nombre del usuario
              if (user != null) ...[
                Text(
                  user.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.correo,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.profileMemberSince} ${_formatDate(user.fechaRegistro)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Tarjeta del formulario
              AuthCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombres y Apellidos en una fila
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: AppStrings.profileNameLabel,
                              hint: AppStrings.registerNameHint,
                              icon: Icons.person_outline,
                              controller: _firstNameController,
                              validator: Validators.required,
                              enabled: _isEditing && !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              label: AppStrings.profileLastNameLabel,
                              hint: AppStrings.registerLastNameHint,
                              icon: Icons.person_outline,
                              controller: _lastNameController,
                              validator: Validators.required,
                              enabled: _isEditing && !_isLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Correo
                      AuthTextField(
                        label: AppStrings.profileEmailLabel,
                        hint: AppStrings.registerEmailHint,
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        enabled: _isEditing && !_isLoading,
                      ),
                      const SizedBox(height: 18),
                      // Teléfono
                      AuthTextField(
                        label: AppStrings.profilePhoneLabel,
                        hint: AppStrings.registerPhoneHint,
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        enabled: _isEditing && !_isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Error message
                      if (_errorMessage != null) ...[
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
                                  _errorMessage!,
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
                      // Botones de acción
                      if (_isEditing) ...[
                        AuthButton(
                          label: AppStrings.profileSaveButton,
                          onPressed: _isLoading ? null : _handleSave,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = false;
                                      _errorMessage = null;
                                      _loadUserData();
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              AppStrings.profileCancelButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        AuthButton(
                          label: AppStrings.profileEditButton,
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botón de logout
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    AppStrings.profileLogoutButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
