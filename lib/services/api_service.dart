import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/utils/session_manager.dart';

/// Configuración base HTTP y manejo de headers (Bearer token).
/// Aísla completamente la configuración del cliente HTTP.
class ApiService {
  final http.Client _client;
  final SessionManager _sessionManager;

  ApiService({http.Client? client, SessionManager? sessionManager})
    : _client = client ?? http.Client(),
      _sessionManager = sessionManager ?? SessionManager();

  /// Retorna los headers base para todas las peticiones.
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Retorna los headers con el token de autorización incluido.
  Future<Map<String, String>> AuthHeaders() async {
    final token = await _sessionManager.GetToken();
    final headers = Map<String, String>.from(_baseHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Realiza una petición GET.
  Future<http.Response> Get(String path) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await AuthHeaders();
    return _client.get(url, headers: headers).timeout(ApiConfig.requestTimeout);
  }

  /// Realiza una petición POST.
  Future<http.Response> Post(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await AuthHeaders();
    return _client
        .post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.requestTimeout);
  }

  /// Realiza una petición PATCH.
  Future<http.Response> Patch(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await AuthHeaders();
    return _client
        .patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(ApiConfig.requestTimeout);
  }

  /// Realiza una peticion DELETE.
  Future<http.Response> Delete(String path) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await AuthHeaders();
    return _client
        .delete(url, headers: headers)
        .timeout(ApiConfig.requestTimeout);
  }

  /// Cierra el cliente HTTP.
  void Dispose() {
    _client.close();
  }
}
