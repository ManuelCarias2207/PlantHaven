import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_strings.dart';
import 'package:flutter_app/core/utils/validators.dart';

/// Indicador visual de fortaleza de contraseña.
/// Muestra checks verdes cuando se cumplen los requisitos.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final hasMinLength = Validators.hasMinLength(password, 8);
    final hasLetter = Validators.hasLetter(password);
    final hasNumber = Validators.hasNumber(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          AppStrings.passwordStrengthLabel,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _CheckItem(
          label: AppStrings.passwordStrengthMin,
          isValid: hasMinLength,
        ),
        const SizedBox(height: 4),
        _CheckItem(
          label: AppStrings.passwordStrengthLetters,
          isValid: hasLetter,
        ),
        const SizedBox(height: 4),
        _CheckItem(
          label: AppStrings.passwordStrengthNumbers,
          isValid: hasNumber,
        ),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool isValid;

  const _CheckItem({
    required this.label,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isValid ? AppColors.accent : AppColors.fieldBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isValid ? Icons.check : Icons.circle,
            size: isValid ? 12 : 6,
            color: isValid ? AppColors.white : AppColors.textDisabled,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isValid ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
