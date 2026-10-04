import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/chat_controller.dart';
import 'package:flutter_app/services/chat_service.dart';

ServerMessage message(int id) => ServerMessage.fromJson({
  'id_mensaje': id,
  'id_usuario': id.isEven ? 2 : 1,
  'contenido': 'Mensaje $id',
  'fecha_hora': '2026-10-03T10:00:00Z',
});

class FakeChat extends ChatService {
  final server = <ServerMessage>[];
  List<ServerPoint> locations = [];
  @override
  Future<List<ServerPoint>> points(int chatId) async => locations;
  bool offline = false, blocked = false;
  @override
  Future<int> open(int plantId) async => 1;
  @override
  Future<List<ServerMessage>> messages(int chatId, int after) async {
    if (blocked) throw ChatFailure('Sin permiso', denied: true);
    if (offline) throw Exception('offline');
    return server.where((m) => m.id > after).take(100).toList();
  }

  @override
  Future<ServerMessage> send(int chatId, String text) async {
    if (offline) throw Exception('offline');
    final sent = message(server.length + 1);
    server.add(sent);
    return sent;
  }
}

void main() {
  test(
    'corrige y retira coordenadas ya recibidas sin cambiar el mensaje',
    () async {
      ServerPoint point(double latitude) => ServerPoint.fromJson({
        'id_punto': 1,
        'id_mensaje': 1,
        'latitud': latitude,
        'longitud': -89.7,
        'descripcion': 'Parque',
        'puede_editar': true,
      });
      final api = FakeChat();
      api.locations = [point(13.7)];
      api.server.add(
        ServerMessage(
          id: 1,
          userId: 1,
          text: 'Punto de encuentro',
          date: DateTime.utc(2026),
          point: point(13.7),
        ),
      );
      final chat = ChatController(plantId: 1, service: api);
      await chat.sync();
      expect(chat.messages.single.point!.latitude, 13.7);
      api.locations = [point(14)];
      await chat.sync();
      expect(chat.messages.single.point!.latitude, 14);
      api.locations = [];
      await chat.sync();
      expect(chat.messages.single.point, isNull);
      expect(
        chat.messages.single.text,
        'Punto de encuentro retirado por el remitente',
      );
      expect(chat.messages.single.id, 1);
      chat.dispose();
    },
  );
  test(
    'dos clientes comparten historial y envío no salta mensajes pendientes',
    () async {
      final api = FakeChat();
      final first = ChatController(plantId: 1, service: api);
      final second = ChatController(plantId: 1, service: api);
      await first.sync();
      await second.sync();
      expect(await first.send('Hola'), isTrue);
      expect(await second.send('Respuesta antes de actualizar'), isTrue);
      await second.sync();
      await first.sync();
      expect(first.messages.map((m) => m.id), [1, 2]);
      expect(second.messages.map((m) => m.id), [1, 2]);
      await first.sync();
      expect(first.messages.length, 2);
      first.dispose();
      second.dispose();
    },
  );

  test(
    'reconexión recupera varias páginas y conserva historial ante error',
    () async {
      final api = FakeChat()
        ..server.addAll(List.generate(205, (i) => message(i + 1)));
      final chat = ChatController(plantId: 1, service: api);
      await chat.sync();
      expect(chat.messages.length, 205);
      api.offline = true;
      expect(await chat.send('No se confirmó'), isFalse);
      await chat.sync();
      expect(chat.messages.length, 205);
      api.offline = false;
      api.server.add(message(206));
      await chat.sync();
      expect(chat.messages.length, 206);
      api.blocked = true;
      await chat.sync();
      expect(chat.denied, isTrue);
      expect(await chat.send('No permitido'), isFalse);
      chat.dispose();
    },
  );
}
