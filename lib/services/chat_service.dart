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
  ServerMessage.fromJson(Map<String, dynamic> json)
    : id = json['id_mensaje'],
      userId = json['id_usuario'],
      text = json['contenido'] ?? '',
      date = DateTime.parse(json['fecha_hora']);
}

class ChatService {
  final ApiService _api;
  ChatService({ApiService? api}) : _api = api ?? ApiService();

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
