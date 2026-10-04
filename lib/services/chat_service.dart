import 'dart:convert';

import 'package:flutter_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class ChatFailure implements Exception {
  final String message;
  final bool denied;
  ChatFailure(this.message, {this.denied = false});
  @override
  String toString() => message;
}

class ServerChat {
  final int id, plantId;
  final String plantName, otherName;
  ServerChat.fromJson(Map<String, dynamic> json)
    : id = json['id_chat'],
      plantId = json['id_planta'],
      plantName = json['nombre_planta'] ?? 'Planta #${json['id_planta']}',
      otherName =
          json['nombre_otro_participante'] ?? 'Conversación de adopción';
}

class ServerMessage {
  final int id, userId;
  final String text;
  final DateTime date;
  final ServerPoint? point;
  ServerMessage({
    required this.id,
    required this.userId,
    required this.text,
    required this.date,
    this.point,
  });
  ServerMessage.fromJson(Map<String, dynamic> json)
    : id = json['id_mensaje'],
      userId = json['id_usuario'],
      text = json['contenido'] ?? '',
      date = DateTime.parse(json['fecha_hora']),
      point = json['punto'] == null
          ? null
          : ServerPoint.fromJson(json['punto']);

  ServerMessage withPoint(ServerPoint? value) => ServerMessage(
    id: id,
    userId: userId,
    date: date,
    point: value,
    text: value == null ? 'Punto de encuentro retirado por el remitente' : text,
  );
}

class ServerPoint {
  final int id, messageId;
  final double latitude, longitude;
  final String description;
  final bool canEdit;
  ServerPoint.fromJson(Map<String, dynamic> json)
    : id = json['id_punto'],
      messageId = json['id_mensaje'],
      latitude = (json['latitud'] as num).toDouble(),
      longitude = (json['longitud'] as num).toDouble(),
      description = json['descripcion'] ?? '',
      canEdit = json['puede_editar'] == true;
}

class ChatService {
  final ApiService _api;
  ChatService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<ServerPoint>> points(int chatId) async =>
      (_read(await _api.Get('/api/chats/$chatId/puntos')) as List)
          .map((j) => ServerPoint.fromJson(j))
          .toList();

  Future<ServerPoint> point(int id) async =>
      ServerPoint.fromJson(_read(await _api.Get('/api/puntos-encuentro/$id')));

  Future<ServerMessage> sendPoint(
    int chatId,
    double lat,
    double lon,
    String description,
  ) async => ServerMessage.fromJson(
    _read(
      await _api.Post(
        '/api/chats/$chatId/mensajes',
        body: {
          'tipo': 'UBICACION',
          'latitud': lat,
          'longitud': lon,
          'descripcion': description,
        },
      ),
    ),
  );

  Future<void> editPoint(
    int id,
    double lat,
    double lon,
    String description,
  ) async {
    _read(
      await _api.Patch(
        '/api/puntos-encuentro/$id',
        body: {'latitud': lat, 'longitud': lon, 'descripcion': description},
      ),
    );
  }

  Future<void> removePoint(int id) async {
    final response = await _api.Delete('/api/puntos-encuentro/$id');
    if (response.statusCode != 204) _read(response);
  }

  dynamic _read(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      /* HTML de un proxy */
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data != null) {
      return data;
    }
    if (response.statusCode == 401) {
      throw ChatFailure(
        'Tu sesión venció. Vuelve a iniciar sesión.',
        denied: true,
      );
    }
    if (response.statusCode == 403) {
      throw ChatFailure(
        data is Map && data['detail'] is String
            ? data['detail']
            : 'No tienes acceso a esta conversación.',
        denied: true,
      );
    }
    throw ChatFailure(
      data is Map && data['detail'] is String
          ? data['detail']
          : 'No se pudo conectar con el chat. Inténtalo de nuevo.',
    );
  }

  Future<List<ServerChat>> list() async =>
      (_read(await _api.Get('/api/chats')) as List)
          .map((j) => ServerChat.fromJson(j))
          .toList();

  Future<int> open(int plantId) async => _read(
    await _api.Post('/api/chats', body: {'id_planta': plantId}),
  )['id_chat'];

  Future<List<ServerMessage>> messages(int chatId, int after) async =>
      (_read(
                await _api.Get(
                  '/api/chats/$chatId/mensajes?despues_de=$after&tamano_pagina=100',
                ),
              )['mensajes']
              as List)
          .map((j) => ServerMessage.fromJson(j))
          .toList();

  Future<ServerMessage> send(int chatId, String text) async =>
      ServerMessage.fromJson(
        _read(
          await _api.Post(
            '/api/chats/$chatId/mensajes',
            body: {'contenido': text},
          ),
        ),
      );
}
