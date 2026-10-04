import 'dart:convert';

import 'package:flutter_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class AdoptionStatus {
  final int id, plantId;
  final String state, role, plantName, donor, adopter;
  final DateTime? deliveredAt, receivedAt;
  AdoptionStatus.fromJson(Map<String, dynamic> json)
    : id = json['id_adopcion'],
      plantId = json['id_planta'],
      state = json['estado'],
      role = json['rol'],
      plantName = json['planta']['nombre'],
      donor = json['donante'],
      adopter = json['adoptante'],
      deliveredAt = DateTime.tryParse(json['fecha_entrega'] ?? ''),
      receivedAt = DateTime.tryParse(json['fecha_recepcion'] ?? '');
  bool get isDonor => role == 'donante';
  bool get complete => state == 'COMPLETADA';
  bool get confirmed => (isDonor ? deliveredAt : receivedAt) != null;
  bool get canConfirm => state == 'EN_PROCESO' && !confirmed;
  String get actionLabel =>
      isDonor ? 'Confirmar entrega' : 'Confirmar recepción';
}

class AdoptionFailure implements Exception {
  final String message;
  AdoptionFailure(this.message);
  @override
  String toString() => message;
}

class AdoptionService {
  final ApiService _api;
  AdoptionService({ApiService? api}) : _api = api ?? ApiService();

  dynamic _read(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      /* Respuesta no JSON */
    }
    if (response.statusCode == 200 && body != null) return body;
    if (response.statusCode == 401) {
      throw AdoptionFailure('Tu sesión venció. Vuelve a iniciar sesión.');
    }
    throw AdoptionFailure(
      body is Map && body['detail'] is String ? body['detail'] : 'No se pudo consultar la adopción. Revisa tu conexión e inténtalo de nuevo.',
    );
  }

  Future<List<AdoptionStatus>> list() async =>
      (_read(await _api.Get('/api/adopciones')) as List)
          .map((j) => AdoptionStatus.fromJson(j))
          .toList();

  Future<AdoptionStatus> confirm(
    AdoptionStatus adoption,
  ) async => AdoptionStatus.fromJson(
    _read(
      await _api.Post(
        '/api/adopciones/${adoption.id}/${adoption.isDonor ? 'entrega' : 'recepcion'}',
      ),
    ),
  );
}
