import '../constants/app_strings.dart';

/// Validadores puros y testeables reutilizables en toda la app.
class Validators {
  Validators._();

  static bool isValidEmail(String value) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  static bool isValidPhone(String value) {
    // Acepta números con espacios, guiones o sin formato, mínimo 8 dígitos
    final phoneRegex = RegExp(r'^[\d\s\-+]{8,15}$');
    return phoneRegex.hasMatch(value.trim());
  }

  /// Retorna true si la contraseña tiene al menos 8 caracteres,
  /// al menos una letra y al menos un número.
  static bool isStrongPassword(String value) {
    if (value.length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    return hasLetter && hasNumber;
  }

  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  static bool hasLetter(String value) {
    return RegExp(r'[A-Za-z]').hasMatch(value);
  }

  static bool hasNumber(String value) {
    return RegExp(r'[0-9]').hasMatch(value);
  }

  // Mensajes de validación para formularios

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    if (!isValidEmail(value)) {
      return AppStrings.validationEmailFormat;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationRequired;
    }
    if (value.length < 8) {
      return AppStrings.validationPasswordMinLength;
    }
    if (!isStrongPassword(value)) {
      return AppStrings.validationPasswordLettersNumbers;
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return AppStrings.validationRequired;
    }
    if (value != originalPassword) {
      return AppStrings.validationPasswordMatch;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    if (!isValidPhone(value)) {
      return AppStrings.validationPhoneFormat;
    }
    return null;
  }

  static String? terms(bool accepted) {
    if (!accepted) {
      return AppStrings.validationTerms;
    }
    return null;
  }
}
