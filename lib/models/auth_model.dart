/// Modelo de datos para autenticación.
/// Mapea las respuestas de login y registro de la API REST.
class AuthModel {
  final String accessToken;
  final String tokenType;

  const AuthModel({
    required this.accessToken,
    required this.tokenType,
  });

  /// Crea un AuthModel desde un JSON (mapa).
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }

  /// Convierte el AuthModel a JSON (mapa).
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }

  @override
  String toString() => 'AuthModel(tokenType: $tokenType, token: ${accessToken.substring(0, 10)}...)';
}

/// Modelo para la solicitud de login.
class LoginRequest {
  final String identificador;
  final String contrasena;

  const LoginRequest({
    required this.identificador,
    required this.contrasena,
  });

  Map<String, dynamic> toJson() {
    return {
      'identificador': identificador,
      'contrasena': contrasena,
    };
  }
}

/// Modelo para la solicitud de registro.
class RegisterRequest {
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String contrasena;
  final String confirmarContrasena;

  const RegisterRequest({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.contrasena,
    required this.confirmarContrasena,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
      'contrasena': contrasena,
      'confirmar_contrasena': confirmarContrasena,
    };
  }
}

/// Modelo para la solicitud de actualización de perfil.
class UpdateProfileRequest {
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;

  const UpdateProfileRequest({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
    };
  }
}
