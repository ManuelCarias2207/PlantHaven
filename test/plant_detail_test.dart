import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/plant_service.dart';
import 'package:flutter_app/views/plant_detail_view.dart';

class FakeApi extends ApiService {
  int status = 200;
  String? path;
  @override
  Future<http.Response> Get(String value) async {
    path = value;
    return http.Response(
      jsonEncode({
        'id_planta': 7,
        'nombre': 'Actualizada',
        'estado_planta': 'SOLICITADA',
        'fotografias': [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
        ],
      }),
      status,
    );
  }
}

void main() {
  test(
    'detalle consulta por ID y conserva todas las fotos y estado actual',
    () async {
      final api = FakeApi();
      final service = PlantService(apiService: api);
      final plant = await service.GetPlant(7);
      expect(api.path, '/api/plantas/7');
      expect(plant.estadoPlanta, 'SOLICITADA');
      expect(plant.fotografias.length, 2);
      api.status = 404;
      await expectLater(service.GetPlant(7), throwsException);
    },
  );
  testWidgets('galeria permite pasar a la segunda foto', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 285,
            child: PlantPhotoGallery(
              urls: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
            ),
          ),
        ),
      ),
    );
    expect(find.text('1 / 2 · Desliza'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2 · Desliza'), findsOneWidget);
  });
}
