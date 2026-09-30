import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestiona el almacenamiento persistente y seguro del access_token.
/// Usa flutter_secure_storage en móvil y memoria en web.
class SessionManager {
  static const _keyAccessToken = 'access_token';
  static const _keyTokenType = 'token_type';

  final FlutterSecureStorage? _storage;
  String? _webToken;
  String? _webTokenType;

  SessionManager({FlutterSecureStorage? storage})
      : _storage = kIsWeb ? null : (storage ?? const FlutterSecureStorage());

  /// Guarda el access_token de forma segura.
  Future<void> SaveToken(String token, {String tokenType = 'bearer'}) async {
    if (kIsWeb) {
      _webToken = token;
      _webTokenType = tokenType;
    } else {
      await _storage!.write(key: _keyAccessToken, value: token);
      await _storage.write(key: _keyTokenType, value: tokenType);
    }
  }

  /// Retorna el access_token almacenado, o null si no existe.
  Future<String?> GetToken() async {
    if (kIsWeb) {
      return _webToken;
    }
    return await _storage!.read(key: _keyAccessToken);
  }

  /// Retorna el tipo de token almacenado.
  Future<String?> GetTokenType() async {
    if (kIsWeb) {
      return _webTokenType;
    }
    return await _storage!.read(key: _keyTokenType);
  }

  /// Retorna true si hay un token almacenado.
  Future<bool> HasToken() async {
    final token = await GetToken();
    return token != null && token.isNotEmpty;
  }

  /// Elimina el token almacenado (logout).
  Future<void> ClearToken() async {
    if (kIsWeb) {
      _webToken = null;
      _webTokenType = null;
    } else {
      await _storage!.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyTokenType);
    }
  }

  /// Elimina todos los datos almacenados.
  Future<void> ClearAll() async {
    if (kIsWeb) {
      _webToken = null;
      _webTokenType = null;
    } else {
      await _storage!.deleteAll();
    }
  }
}
