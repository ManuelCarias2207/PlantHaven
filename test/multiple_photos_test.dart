import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/views/plant_form_view.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/plant_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class Auth extends AuthController {
  @override
  Future<bool> ensureAuthenticated() async => true;
}

class Plants extends PlantController {
  @override
  Future<bool> loadCategories() async => true;
  @override
  List<PlantCategory> get categories => [
    const PlantCategory(idCategoria: 1, nombre: 'Interior', estado: 'ACTIVA'),
  ];
  @override
  Future<PlantModel?> loadMyPlant(int id) async => PlantModel.fromJson({
    'id_planta': id,
    'nombre': 'Monstera',
    'id_categoria': 1,
    'tamano': 'Mediano',
    'estado_salud': 'Bueno',
    'nivel_cuidado': 'Bajo',
    'necesidad_luz': 'Indirecta',
    'necesidad_agua': 'Semanal',
    'ubicacion': 'Sonsonate',
    'estado_planta': 'DISPONIBLE',
    'fotografias': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
  });
}

class Api extends ApiService {
  Map<String, String>? sentFields;
  int count = 0;
  String? verb;
  @override
  Future<http.Response> UploadPhotosMultipart(
    String method,
    String path, {
    required Map<String, String> fields,
    required List<({List<int> bytes, String name})> photos,
  }) async {
    sentFields = fields;
    count = photos.length;
    verb = method;
    return http.Response('{}', method == 'POST' ? 201 : 200);
  }
}

void main() {
  test(
    'envia nuevas fotos y seleccion de conservadas en la misma solicitud',
    () async {
      final api = Api();
      final service = PlantService(apiService: api);
      const data = PlantRequest(
        nombre: 'Monstera',
        tamano: 'Mediano',
        nivelCuidado: 'Bajo',
        estadoSalud: 'Bueno',
        necesidadLuz: 'Indirecta',
        necesidadAgua: 'Semanal',
        ubicacion: 'Sonsonate',
        idCategoria: 1,
      );
      final photos = [
        (bytes: <int>[1, 2], name: 'a.jpg'),
        (bytes: <int>[3, 4], name: 'b.jpg'),
      ];
      await service.CreatePlant(data, photos: photos);
      expect(api.verb, 'POST');
      expect(api.count, 2);
      await service.UpdatePlant(
        1,
        data,
        photos: photos,
        keepPhotos: ['https://example.com/original.jpg'],
      );
      expect(api.verb, 'PATCH');
      expect(api.count, 2);
      expect(jsonDecode(api.sentFields!['conservar_fotografias']!), [
        'https://example.com/original.jpg',
      ]);
      await service.UpdatePlant(
        1,
        data,
        photos: [],
        keepPhotos: ['https://example.com/original.jpg'],
      );
      expect(api.count, 0);
      expect(api.verb, 'PATCH');
    },
  );
  testWidgets('editar muestra fotos actuales y quitar todas impide guardar', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(create: (_) => Auth()),
          ChangeNotifierProvider<PlantController>(create: (_) => Plants()),
        ],
        child: const MaterialApp(home: PlantFormView(plantId: 1)),
      ),
    );
    await tester.pumpAndSettle();
    final second = find.byTooltip('Quitar foto 2');
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(find.text('Fotografías (1/5)'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar foto 1'));
    await tester.pumpAndSettle();
    expect(find.text('Fotografías (0/5)'), findsOneWidget);
    final save = find.text('Guardar cambios');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('La publicación debe conservar al menos una fotografía.'),
      findsOneWidget,
    );
  });
}
