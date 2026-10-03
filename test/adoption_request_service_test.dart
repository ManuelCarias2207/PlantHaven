import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/adoption_request_service.dart';

class FakeApi extends ApiService {
  final paths = <String>[];
  int status = 200;
  Map<String, dynamic>? lastBody;
  @override
  Future<http.Response> Patch(String path, {Map<String, dynamic>? body}) async {
    paths.add(path); lastBody = body;
    return http.Response(jsonEncode({'id_solicitud':8,'id_planta':3,'estado':body?['estado'],'mensaje':'Tengo espacio'}),200);
  }
  @override
  Future<http.Response> Get(String path) async {
    paths.add(path);
    return http.Response(jsonEncode([{'id_solicitud': 8, 'id_planta': 3,
      'mensaje': 'Tengo espacio', 'estado': 'PENDIENTE'}]), 200);
  }
  @override
  Future<http.Response> Post(String path, {Map<String, dynamic>? body}) async {
    paths.add(path);
    return http.Response(jsonEncode({'detail': 'Ya tienes una solicitud activa'}), status);
  }
}

void main() {
  test('decisión envía solo estado al PATCH compartido', () async {
    final api=FakeApi();
    final service=AdoptionRequestService(apiService:api);
    expect((await service.decide(8,'ACEPTADA')).status,'ACEPTADA');
    expect(api.paths.single,'/api/solicitudes/8');
    expect(api.lastBody,{'estado':'ACEPTADA'});
  });
  test('solicitudes enviadas y recibidas usan los filtros de la API existente', () async {
    final api = FakeApi();
    final service = AdoptionRequestService(apiService: api);
    expect((await service.mine()).single.id, 8);
    expect((await service.received()).single.reason, 'Tengo espacio');
    expect(api.paths, ['/api/solicitudes?tipo=enviadas&limite=100',
      '/api/solicitudes?tipo=recibidas&limite=100&offset=0']);
  });
  test('un conflicto conserva el motivo que explica la API', () async {
    final api = FakeApi()..status = 409;
    final service = AdoptionRequestService(apiService: api);
    await expectLater(service.create(plantId: 3, reason: 'Tengo espacio'),
      throwsA(predicate((e) => e.toString().contains('Ya tienes una solicitud activa'))));
  });
}
