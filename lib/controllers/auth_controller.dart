import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/models/auth_model.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/utils/session_manager.dart';

/// Estados posibles del controlador de autenticación.
enum AuthState { initial, loading, authenticated, error }

/// Controlador de autenticación con MVC.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final SessionManager _sessionManager;

  AuthController({AuthService? authService, SessionManager? sessionManager})
    : _authService = authService ?? AuthService(),
      _sessionManager = sessionManager ?? SessionManager();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _state == AuthState.loading;
  String get defaultAuthenticatedRoute => AppRoutes.home;

  /// Inicia sesión con identificador (correo o teléfono) y contraseña.
  Future<bool> login({
    required String identificador,
    required String contrasena,
  }) async {
    _setLoading();

    try {
      final AuthModel auth = await _authService.Login(
        identificador: identificador,
        contrasena: contrasena,
      );

      await _authService.SaveSession(auth);

      try {
        _currentUser = await _authService.GetProfile();
      } catch (e) {
        debugPrint('⚠️ Error no crítico cargando perfil: $e');
      }

      _isAuthenticated = true;
      _state = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('🔴 ApiException en Login: [${e.statusCode}] ${e.message}');
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      debugPrint('ClientException en Login: $e');
      _setError(_networkErrorMessage());
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException en Login: $e');
      _setError(
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
      );
      return false;
    } catch (e, stackTrace) {
      debugPrint('🔴 Error no controlado en Login: $e\n$stackTrace');
      _setError('Ocurrió un error inesperado. Inténtalo de nuevo.');
      return false;
    }
  }

  /// Registra un nuevo usuario.
  Future<bool> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String contrasena,
    required String confirmarContrasena,
  }) async {
    _setLoading();

    try {
      // 1. Llamar al endpoint de registro
      final UserModel user = await _authService.Register(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
        contrasena: contrasena,
        confirmarContrasena: confirmarContrasena,
      );

      // 2. Autenticar automáticamente
      final AuthModel auth = await _authService.Login(
        identificador: correo,
        contrasena: contrasena,
      );

      // 3. Guardar sesión y usuario
      await _authService.SaveSession(auth);
      _currentUser = user;

      _isAuthenticated = true;
      _state = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint(
        '🔴 ApiException en Register: Status Code ${e.statusCode} | Msg: ${e.message}',
      );
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      // En Flutter Web, los errores de red o CORS llegan como ClientException.
      debugPrint('🔴 ClientException en Register: $e');
      _setError(
        'No se pudo conectar con el servidor. Verifica la API y tu conexión.',
      );
      return false;
    } on TimeoutException catch (e) {
      debugPrint('🔴 TimeoutException en Register: $e');
      _setError('El servidor tardó demasiado en responder.');
      return false;
    } catch (e, stackTrace) {
      // IMPRESIÓN DETALLADA DEL ERROR EN CONSOLA
      debugPrint('🔴 ERROR CAPTURADO EN CATCH GENÉRICO:');
      debugPrint('Detalle: $e');
      debugPrint('Stacktrace: $stackTrace');
      _setError(
        'Ocurrió un error inesperado: ${e.toString().split('\n').first}',
      );
      return false;
    }
  }

  Future<bool> requestPasswordReset({required String correo}) async {
    _setLoading();

    try {
      await _authService.RequestPasswordReset(correo: correo);
      _setIdle();
      return true;
    } on ApiException catch (e) {
      debugPrint('ApiException en RequestPasswordReset: $e');
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      debugPrint('ClientException en RequestPasswordReset: $e');
      _setError(_networkErrorMessage());
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException en RequestPasswordReset: $e');
      _setError(
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
      );
      return false;
    } catch (e) {
      debugPrint('Error en RequestPasswordReset: $e');
      _setError('No se pudo solicitar la recuperacion. Intentalo de nuevo.');
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    _setLoading();

    try {
      await _authService.ResetPassword(
        token: token,
        nuevaContrasena: nuevaContrasena,
        confirmarContrasena: confirmarContrasena,
      );
      _setIdle();
      return true;
    } on ApiException catch (e) {
      debugPrint('ApiException en ResetPassword: $e');
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      debugPrint('ClientException en ResetPassword: $e');
      _setError(_networkErrorMessage());
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException en ResetPassword: $e');
      _setError(
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
      );
      return false;
    } catch (e) {
      debugPrint('Error en ResetPassword: $e');
      _setError('No se pudo actualizar la contrasena. Intentalo de nuevo.');
      return false;
    }
  }

  /// Carga el perfil del usuario autenticado.
  Future<bool> loadProfile() async {
    _setLoading();

    try {
      _currentUser = await _authService.GetProfile();
      _state = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('🔴 ApiException en GetProfile: $e');
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      debugPrint('ClientException en protected request: $e');
      _setError(_networkErrorMessage());
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException en protected request: $e');
      _setError(
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
      );
      return false;
    } catch (e) {
      debugPrint('🔴 Error en GetProfile: $e');
      _setError('No se pudo cargar el perfil. Inténtalo de nuevo.');
      return false;
    }
  }

  /// Actualiza los datos del perfil.
  Future<bool> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
  }) async {
    _setLoading();

    try {
      _currentUser = await _authService.UpdateProfile(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
      );
      _state = AuthState.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('🔴 ApiException en UpdateProfile: $e');
      _setError(_friendlyErrorMessage(e));
      return false;
    } on http.ClientException catch (e) {
      debugPrint('ClientException en protected request: $e');
      _setError(_networkErrorMessage());
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException en protected request: $e');
      _setError(
        'El servidor tardo demasiado en responder. Intentalo de nuevo.',
      );
      return false;
    } catch (e) {
      debugPrint('🔴 Error en UpdateProfile: $e');
      _setError('No se pudo actualizar el perfil. Inténtalo de nuevo.');
      return false;
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout() async {
    await _authService.Logout();
    _currentUser = null;
    _isAuthenticated = false;
    _state = AuthState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  /// Verifica si hay una sesión activa al iniciar la app.
  Future<void> checkSession() async {
    final hasToken = await _sessionManager.HasToken();
    if (hasToken) {
      await loadProfile();
    }
  }

  Future<bool> ensureAuthenticated() async {
    if (!await _sessionManager.HasToken()) return false;
    if (_isAuthenticated) return true;
    return loadProfile();
  }

  /// Limpia el estado de error.
  void clearError() {
    if (_state == AuthState.error) {
      _state = _currentUser != null
          ? AuthState.authenticated
          : AuthState.initial;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Traduce los errores de la API a mensajes amigables.
  String _friendlyErrorMessage(ApiException exception) {
    if (exception.statusCode >= 500) {
      return 'El servidor no esta disponible. Intentalo en unos segundos.';
    }

    if (exception.statusCode == 422) {
      final validationMessage = _validationErrorMessage(exception.errors);
      if (validationMessage != null) return validationMessage;

      return exception.message.isNotEmpty
          ? exception.message
          : 'Error de validación. Revisa los datos ingresados.';
    }

    switch (exception.statusCode) {
      case 400:
        return 'Solicitud incorrecta. Verifica los datos enviados.';
      case 401:
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      case 403:
        return 'Acceso denegado.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'El correo o teléfono ya está registrado.';
      case 500:
        return 'Error del servidor. Inténtalo más tarde.';
      default:
        return exception.message;
    }
  }

  String? _validationErrorMessage(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) return null;

    final messages = errors.entries.map((entry) {
      final field = _fieldLabel(entry.key);
      final value = entry.value;
      if (value is List) return '$field: ${value.join(', ')}';
      return '$field: $value';
    }).toList();

    return messages.isEmpty ? null : messages.join('. ');
  }

  String _fieldLabel(String field) {
    const labels = {
      'nombre': 'Nombre',
      'apellido': 'Apellido',
      'correo': 'Correo',
      'telefono': 'Telefono',
      'contrasena': 'Contrasena',
      'confirmar_contrasena': 'Confirmar contrasena',
      'identificador': 'Correo o telefono',
    };
    return labels[field] ?? field;
  }

  String _networkErrorMessage() {
    return 'No se pudo conectar con la API. Verifica el servidor y la configuracion CORS para esta aplicacion web.';
  }

  void _setLoading() {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setIdle() {
    _state = AuthState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = AuthState.error;
    _errorMessage = message;
    _isAuthenticated = false;
    notifyListeners();
  }
}
