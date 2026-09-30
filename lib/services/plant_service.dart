import 'dart:convert';

import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/auth_service.dart';

class PlantService {
  final ApiService _apiService;

  PlantService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<List<PlantModel>> GetCatalog() async {
    final response = await _apiService.Get('/api/plantas');
    final body = _parseBody(response);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, body);
    }

    final items = body['items'];
    if (items is List) {
      return items
          .whereType<Map<String, dynamic>>()
          .map(PlantModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<PlantModel>> GetMyPlants() async {
    final response = await _apiService.Get('/api/plantas/mias');
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, _asMap(decoded));
    }

    final list = decoded is List ? decoded : (_asMap(decoded)['items'] ?? []);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(PlantModel.fromJson)
        .toList();
  }

  Future<PlantModel> CreatePlant(PlantRequest request) async {
    final response = await _apiService.Post(
      '/api/plantas/',
      body: request.toJson(),
    );
    final body = _parseBody(response);
    if (response.statusCode != 201) {
      throw _createException(response.statusCode, body);
    }
    return PlantModel.fromJson(body);
  }

  Future<PlantModel> UpdatePlant(int id, PlantRequest request) async {
    final response = await _apiService.Patch(
      '/api/plantas/$id',
      body: request.toJson(),
    );
    final body = _parseBody(response);
    if (response.statusCode != 200) {
      throw _createException(response.statusCode, body);
    }
    return PlantModel.fromJson(body);
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

  ApiException _createException(int statusCode, Map<String, dynamic> body) {
    final detail = body['detail'];
    final message = detail is String
        ? detail
        : body['message'] as String? ??
              'No se pudo completar la operacion (HTTP $statusCode).';
    return ApiException(statusCode: statusCode, message: message);
  }
}
