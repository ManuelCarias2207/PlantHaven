import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:flutter_app/views/my_plants_view.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class _Auth extends AuthController {
  @override
  Future<bool> ensureAuthenticated() async => true;
}

class _Plants extends PlantController {
  @override
  Future<bool> loadMyPlants() async => true;

  @override
  List<PlantModel> get myPlants => [PlantModel.fromJson({
    'id_planta': 1,
    'nombre': 'Monstera deliciosa de prueba con un nombre largo',
    'estado_planta': 'DISPONIBLE',
    'visible': true,
    'eliminada': false,
    'ubicacion': 'Tepecoyo, zona central con descripción larga',
  })];
}

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('La foto y el menú caben a $width píxeles', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(create: (_) => _Auth()),
          ChangeNotifierProvider<PlantController>(create: (_) => _Plants()),
        ],
        child: const MaterialApp(home: MyPlantsView()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PlantImage)), const Size(56, 56));
      final menu = find.byTooltip('Editar o retirar publicación');
      expect(tester.getRect(menu).right, lessThanOrEqualTo(width));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Retirar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
