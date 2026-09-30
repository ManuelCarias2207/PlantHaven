import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Tarjeta blanca con bordes muy redondeados para contener formularios.
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
