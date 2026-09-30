import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/models/auth_model.dart';
import 'package:flutter_app/models/password_recovery_model.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/utils/session_manager.dart';

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Servicio de autenticación.
/// Aísla completamente las peticiones HTTP a la API REST.
class AuthService {
  final ApiService _apiService;
  final SessionManager _sessionManager;

  AuthService({ApiService? apiService, SessionManager? sessionManager})
    : _apiService = apiService ?? ApiService(),
      _sessionManager = sessionManager ?? SessionManager();

  /// POST /api/auth/login
  /// Retorna un [AuthModel] con el access_token en caso de éxito.
  /// Lanza [ApiException] con el código de estado y mensaje de error.
  Future<AuthModel> Login({
    required String identificador,
    required String contrasena,
  }) async {
    final request = LoginRequest(
      identificador: identificador,
      contrasena: contrasena,
    );

    final response = await _apiService.Post(
      ApiConfig.loginPath,
      body: request.toJson(),
    );

    return HandleAuthResponse(response);
  }

  /// POST /api/auth/registro
  /// Retorna un [UserModel] con los datos del usuario creado.
  /// Lanza [ApiException] con el código de estado y mensaje de error.
  Future<UserModel> Register({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    final request = RegisterRequest(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      contrasena: contrasena,
      confirmarContrasena: confirmarContrasena,
    );

    final response = await _apiService.Post(
      ApiConfig.registerPath,
      body: request.toJson(),
    );

    return HandleRegisterResponse(response);
  }

  /// Solicita el envio del codigo de recuperacion por correo.
  Future<void> RequestPasswordReset({required String correo}) async {
    final request = ForgotPasswordRequest(correo: correo);
    final response = await _apiService.Post(
      ApiConfig.forgotPasswordPath,
      body: request.toJson(),
    );

    EnsureSuccess(response, acceptedStatusCodes: {200, 202});
  }

  /// Cambia la contrasena usando el token/codigo recibido.
  Future<void> ResetPassword({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    final request = ResetPasswordRequest(
      token: token,
      nuevaContrasena: nuevaContrasena,
      confirmarContrasena: confirmarContrasena,
    );
    final response = await _apiService.Post(
      ApiConfig.resetPasswordPath,
      body: request.toJson(),
    );

    EnsureSuccess(response, acceptedStatusCodes: {200, 204});
  }

  /// GET /api/usuarios/me
  /// Retorna el [UserModel] del usuario autenticado.
  /// Lanza [ApiException] si el token es inválido o ha expirado.
  Future<UserModel> GetProfile() async {
    final response = await _apiService.Get(ApiConfig.profilePath);
    return HandleProfileResponse(response);
  }

  /// PATCH /api/usuarios/me
  /// Actualiza los datos del perfil y retorna el [UserModel] actualizado.
  Future<UserModel> UpdateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
  }) async {
    final request = UpdateProfileRequest(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
    );

    final response = await _apiService.Patch(
      ApiConfig.profilePath,
      body: request.toJson(),
    );

    return HandleProfileResponse(response);
  }

  /// Guarda el token de acceso en el almacenamiento seguro.
  Future<void> SaveSession(AuthModel auth) async {
    await _sessionManager.SaveToken(
      auth.accessToken,
      tokenType: auth.tokenType,
    );
  }

  /// Cierra la sesión eliminando el token almacenado.
  Future<void> Logout() async {
    await _sessionManager.ClearToken();
  }

  /// Retorna true si hay una sesión activa.
  Future<bool> IsAuthenticated() async {
    return await _sessionManager.HasToken();
  }

  // --- Manejo de respuestas ---

  AuthModel HandleAuthResponse(http.Response response) {
    final body = ParseBody(response);

    if (response.statusCode == 200) {
      return AuthModel.fromJson(body);
    }

    throw CreateException(response.statusCode, body);
  }

  UserModel HandleRegisterResponse(http.Response response) {
    final body = ParseBody(response);

    if (response.statusCode == 201) {
      return UserModel.fromJson(body);
    }

    throw CreateException(response.statusCode, body);
  }

  UserModel HandleProfileResponse(http.Response response) {
    final body = ParseBody(response);

    if (response.statusCode == 200) {
      return UserModel.fromJson(body);
    }

    throw CreateException(response.statusCode, body);
  }

  void EnsureSuccess(
    http.Response response, {
    required Set<int> acceptedStatusCodes,
  }) {
    if (acceptedStatusCodes.contains(response.statusCode)) return;
    throw CreateException(response.statusCode, ParseBody(response));
  }

  Map<String, dynamic> ParseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'message': decoded.toString()};
    } catch (_) {
      return {'message': response.body};
    }
  }

  ApiException CreateException(int statusCode, Map<String, dynamic> body) {
    final message = ExtractMessage(body, statusCode);

    // Extraer errores de validación (422) si existen
    Map<String, dynamic>? errors;
    if (statusCode == 422) {
      errors = ExtractValidationErrors(body);
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      errors: errors,
    );
  }

  String ExtractMessage(Map<String, dynamic> body, int statusCode) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;

    final detail = body['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List) {
      final messages = detail
          .whereType<Map>()
          .map((item) => item['msg'])
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) return messages.join('. ');
    }

    return DefaultMessage(statusCode);
  }

  Map<String, dynamic>? ExtractValidationErrors(Map<String, dynamic> body) {
    // Formato común de FastAPI: {"detail": [{"loc": [...], "msg": "...", "type": "..."}]}
    final detail = body['detail'];
    if (detail is List) {
      final errors = <String, dynamic>{};
      for (final item in detail) {
        if (item is Map<String, dynamic>) {
          final loc = item['loc'] as List?;
          final msg = item['msg'] as String? ?? 'Error de validación';
          if (loc != null && loc.length > 1) {
            final field = loc[1].toString();
            errors[field] = msg;
          }
        }
      }
      return errors.isNotEmpty ? errors : null;
    }

    // Formato alternativo: {"errors": {"field": "message"}}
    final errorsField = body['errors'];
    if (errorsField is Map<String, dynamic>) {
      return errorsField;
    }

    return null;
  }

  String DefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud incorrecta. Verifica los datos enviados.';
      case 401:
        return 'No autorizado. Verifica tus credenciales.';
      case 403:
        return 'Acceso denegado.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'Conflicto: el recurso ya existe.';
      case 422:
        return 'Error de validación. Verifica los campos del formulario.';
      case 500:
        return 'Error del servidor. Inténtalo más tarde.';
      default:
        return 'Ocurrió un error inesperado (código $statusCode).';
    }
  }
}
