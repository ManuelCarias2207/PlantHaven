import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_app/core/config/api_config.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/auth_service.dart';

class PlantService {
  final ApiService _apiService;

  PlantService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<PlantCategory>> GetCategories() async {
    final response = await _apiService.Get('/api/categorias');
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, _asMap(decoded));
    }

    final values = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic>
              ? (decoded['items'] ??
                    decoded['categorias'] ??
                    decoded['data'] ??
                    [])
              : []);
    return (values as List)
        .whereType<Map<String, dynamic>>()
        .map(PlantCategory.fromJson)
        .where(
          (category) => category.idCategoria > 0 && category.nombre.isNotEmpty,
        )
        .toList();
  }

  Future<List<PlantModel>> GetCatalog() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.plantsPath}';

    try {
      debugPrint('[PlantService] GET URL: $url');
      final response = await _apiService.Get(ApiConfig.plantsPath);
      debugPrint('RESPUESTA CATALOGO: ${response.body}');
      debugPrint(
        '[PlantService] GET respuesta: ${response.statusCode} ${response.body}',
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw _createException(response.statusCode, _asMap(decoded));
      }

      final items = _extractList(decoded);
      return items
          .whereType<Map<String, dynamic>>()
          .map(PlantModel.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[PlantService] Error consultando $url: $e');
      rethrow;
    }
  }

  Future<List<PlantModel>> GetMyPlants() async {
    const path = '/api/plantas/mias/';
    debugPrint('[PlantService] GET MIS PLANTAS: ${ApiConfig.baseUrl}$path');
    final response = await _apiService.Get(path);
    debugPrint(
      '[PlantService] GET MIS PLANTAS respuesta: ${response.statusCode}',
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, _asMap(decoded));
    }

    final list = _extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(PlantModel.fromJson)
        .toList();
  }

  Future<PlantModel> CreatePlant(
    PlantRequest request, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    try {
      final payload = request.toJson();
      debugPrint(
        '[PlantService] POST /api/plantas/ payload: ${jsonEncode(payload)}',
      );
      final response = imageBytes == null
          ? await _apiService.Post('/api/plantas/', body: payload)
          : await _apiService.PostMultipart(
              '/api/plantas/',
              fields: payload.map((key, value) => MapEntry(key, '$value')),
              bytes: imageBytes,
              filename: imageName,
            );
      final body = _parseBody(response);
      debugPrint(
        '[PlantService] POST respuesta: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _createException(response.statusCode, body);
      }
      return PlantModel.fromJson(_extractObject(body));
    } catch (e, stackTrace) {
      debugPrint('[PlantService] Error publicando planta: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<PlantModel> UpdatePlant(
    int id,
    PlantRequest request, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final payload = request.toJson();
    debugPrint(
      '[PlantService] PATCH /api/plantas/$id payload: ${jsonEncode(payload)}',
    );
    final response = imageBytes == null
        ? await _apiService.Patch('/api/plantas/$id', body: payload)
        : await _apiService.PatchMultipart(
            '/api/plantas/$id',
            fields: payload.map((key, value) => MapEntry(key, '$value')),
            bytes: imageBytes,
            filename: imageName,
          );
    final body = _parseBody(response);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, body);
    }
    return PlantModel.fromJson(_extractObject(body));
  }

  Future<void> DeletePlant(int id) async {
    final response = await _apiService.Delete('/api/plantas/$id');
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, _parseBody(response));
    }
  }

  Map<String, dynamic> _parseBody(dynamic response) {
    try {
      final decoded = jsonDecode(response.body);
      return _asMap(decoded);
    } catch (_) {
      return {'message': response.body.toString()};
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : {'items': value};
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) return _extractList(data);

      final items = value['items'] ?? value['plantas'];
      if (items is List) return items;
      if (items is Map<String, dynamic>) return _extractList(items);
    }
    return [];
  }

  Map<String, dynamic> _extractObject(Map<String, dynamic> value) {
    for (final key in ['data', 'item', 'planta']) {
      final nested = value[key];
      if (nested is Map<String, dynamic>) return nested;
    }
    return value;
  }

  ApiException _createException(int statusCode, Map<String, dynamic> body) {
    final detail = body['detail'];
    final message = detail is String
        ? detail
        : body['message'] as String? ??
              'No se pudo completar la operacion (HTTP $statusCode).';
    return ApiException(statusCode: statusCode, message: message);
  }
}
