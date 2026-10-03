import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/services/plant_service.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:provider/provider.dart';

class Auth extends AuthController {
  @override
  Future<bool> ensureAuthenticated() async => true;
}

class Catalog extends PlantService {
  final calls = <int>[];
  Map<String, String> last = {};
  @override
  Future<Map<String, dynamic>> GetCatalogPage({
    int page = 1,
    Map<String, String> filters = const {},
  }) async {
    calls.add(page);
    last = filters;
    final filtered = filters.containsKey('tamano');
    return {
      'total': filtered ? 1 : 13,
      'hay_mas': !filtered && page == 1,
      'filtros': {
        'tamano': ['Grande', 'Pequeno'],
        'nivel_cuidado': ['Bajo', 'Alto'],
        'categoria': ['Interior'],
        'ubicacion': ['Sonsonate'],
      },
      'plantas': List.generate(
        filtered ? 1 : (page == 1 ? 12 : 1),
        (i) => {
          'id_planta': filtered ? 99 : (page == 1 ? i + 1 : 13),
          'nombre': filtered ? 'Filtrada' : 'Planta ${page == 1 ? i + 1 : 13}',
          'estado_planta': 'DISPONIBLE',
          'tamano': 'Grande',
          'nivel_cuidado': 'Bajo',
        },
      ),
    };
  }
}

void main() {
  testWidgets('carga pagina siguiente y reinicia al filtrar', (tester) async {
    final service = Catalog();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>(
        create: (_) => Auth(),
        child: MaterialApp(home: CatalogView(service: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.calls, [1]);
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
    }
    expect(service.calls, [1, 2]);
    await tester.drag(find.byType(ListView).first, const Offset(0, 4000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos los tamaños'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grande').last);
    await tester.pumpAndSettle();
    expect(service.calls.last, 1);
    expect(service.last['tamano'], 'Grande');
    expect(find.text('Filtrada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
