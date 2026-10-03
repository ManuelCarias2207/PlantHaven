import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/services/api_service.dart';

class AdoptionRequestService {
  final ApiService _api;
  AdoptionRequestService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  Future<AdoptionRequest> create({
    required int plantId,
    required String reason,
  }) async {
    debugPrint(
      '[AdoptionRequestService] POST ${ApiConfig.requestsPath} body: {id_planta: $plantId, mensaje: ${reason.length} caracteres}',
    );
    final payload = {'id_planta': plantId, 'mensaje': reason};
    var response = await _api.Post(ApiConfig.requestsPath, body: payload);
    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null && location.isNotEmpty) {
        final uri = Uri.parse(location);
        final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
        debugPrint('[AdoptionRequestService] Reintentando POST en $path');
        response = await _api.Post(path, body: payload);
      }
    }
    debugPrint(
      '[AdoptionRequestService] POST respuesta: ${response.statusCode} ${response.body}',
    );
    if (response.statusCode == 307 || response.statusCode == 308) {
      debugPrint(
        '[AdoptionRequestService] Redirección recibida: ${response.headers['location']}',
      );
    }
    final body = _decode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        body['detail'] ?? body['message'] ?? 'No se pudo enviar la solicitud.',
      );
    }
    return AdoptionRequest.fromJson(_object(body));
  }

  Future<List<AdoptionRequest>> received({
    int offset = 0,
    String? estado,
    int? plantId,
  }) => _list(
    '${ApiConfig.receivedRequestsPath}&offset=$offset${estado == null ? '' : '&estado=$estado'}${plantId == null ? '' : '&id_planta=$plantId'}',
  );

  Future<AdoptionRequest> decide(int id, String status) async {
    final response = await _api.Patch(
      '${ApiConfig.requestsPath}/$id',
      body: {'estado': status},
    );
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['detail'] ?? 'No se pudo guardar la decisión.');
    }
    return AdoptionRequest.fromJson(_object(body));
  }

  Future<AdoptionRequest> detail(int id) async {
    final response = await _api.Get('${ApiConfig.requestsPath}/$id');
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['detail'] ?? 'No se pudo consultar la solicitud.');
    }
    return AdoptionRequest.fromJson(_object(body));
  }

  Future<List<AdoptionRequest>> mine() => _list(ApiConfig.myRequestsPath);

  Future<List<AdoptionRequest>> _list(String path) async {
    debugPrint('[AdoptionRequestService] GET $path');
    final response = await _api.Get(path);
    debugPrint(
      '[AdoptionRequestService] GET respuesta: ${response.statusCode}',
    );
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        body['detail'] ??
            body['message'] ??
            'No se pudieron cargar las solicitudes.',
      );
    }
    final values = body is List
        ? body
        : (body['items'] ?? body['data'] ?? body['solicitudes'] ?? []);
    return (values as List)
        .whereType<Map<String, dynamic>>()
        .map(AdoptionRequest.fromJson)
        .toList();
  }

  dynamic _decode(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return <String, dynamic>{'message': value};
    }
  }

  Map<String, dynamic> _object(dynamic value) => value is Map<String, dynamic>
      ? (value['solicitud'] is Map<String, dynamic>
            ? value['solicitud'] as Map<String, dynamic>
            : value)
      : <String, dynamic>{};
}
