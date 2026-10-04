import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/chat_service.dart';

/// El servidor es la fuente del historial. Un envío no adelanta el cursor
/// de lectura: podría saltarse mensajes que el otro usuario acaba de enviar.
class ChatController extends ChangeNotifier {
  final ChatService service;
  final int plantId;
  ChatController({required this.plantId, required this.service});
  int? chatId;
  int _cursor = 0;
  final Map<int, ServerMessage> _messages = {};
  bool loading = false, sending = false, denied = false, _disposed = false;
  String? error;
  List<ServerMessage> get messages =>
      _messages.values.toList()..sort((a, b) => a.id.compareTo(b.id));

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _fail(Object e) {
    denied = e is ChatFailure && e.denied;
    error = e is ChatFailure
        ? e.message
        : 'No se pudo conectar con el chat. Revisa tu conexión.';
  }

  Future<void> sync() async {
    if (loading || denied || _disposed) return;
    loading = true;
    _notify();
    try {
      chatId ??= await service.open(plantId);
      // Recupera lotes completos, incluso cuando se acumularon mensajes sin conexión.
      List<ServerMessage> batch;
      do {
        final previousCursor = _cursor;
        batch = await service.messages(chatId!, _cursor);
        if (_disposed) return;
        for (final message in batch) {
          _messages[message.id] = message;
          if (message.id > _cursor) _cursor = message.id;
        }
        _notify();
        if (_cursor == previousCursor) break;
      } while (batch.length == 100);
      // Los puntos existentes pueden cambiar sin crear un mensaje nuevo.
      if (_messages.values.any((m) => m.point != null)) {
        final points = {for (final p in await service.points(chatId!)) p.id: p};
        if (_disposed) return;
        for (final entry in _messages.entries.toList()) {
          if (entry.value.point != null) {
            _messages[entry.key] = entry.value.withPoint(
              points[entry.value.point!.id],
            );
          }
        }
      }
      error = null;
    } catch (e) {
      if (!_disposed) _fail(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> send(String text) async {
    text = text.trim();
    if (sending ||
        denied ||
        chatId == null ||
        text.isEmpty ||
        text.length > 2000) {
      return false;
    }
    sending = true;
    _notify();
    try {
      final message = await service.send(chatId!, text);
      if (_disposed) return false;
      _messages[message.id] = message;
      error = null;
      return true;
    } catch (e) {
      if (!_disposed) {
        _fail(e);
        if (!denied) {
          error =
              '${error!} Si se interrumpió el envío, revisa el historial antes de repetirlo.';
        }
      }
      return false;
    } finally {
      sending = false;
      _notify();
    }
  }

  Future<bool> changePoint(Future<void> Function(int chatId) change) async {
    if (sending || denied || chatId == null || _disposed) return false;
    sending = true;
    _notify();
    String? actionError;
    try {
      await change(chatId!);
      error = null;
      return true;
    } catch (e) {
      if (!_disposed) {
        _fail(e);
        actionError = error;
      }
      return false;
    } finally {
      sending = false;
      _notify();
      await sync();
      if (actionError != null && !_disposed) {
        error = actionError;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
