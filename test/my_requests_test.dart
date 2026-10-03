import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/services/adoption_request_service.dart';
import 'package:flutter_app/views/my_requests_view.dart';
import 'package:provider/provider.dart';

class Auth extends AuthController {
  @override
  Future<bool> ensureAuthenticated() async => true;
}

class Requests extends AdoptionRequestService {
  String status = 'PENDIENTE', message = 'Mensaje original';
  bool removed = false, conflict = false;
  int edits = 0, removals = 0, lastOffset = 0;
  String? filter;
  int? plantFilter;
  int count = 1;
  AdoptionRequest request(int id) => AdoptionRequest.fromJson({
    'id_solicitud': id,
    'id_planta': 2,
    'nombre_planta': 'Monstera',
    'mensaje': message,
    'estado': status,
  });
  @override
  Future<List<AdoptionRequest>> mine({
    int offset = 0,
    int limit = 100,
    String? estado,
    int? plantId,
  }) async {
    lastOffset = offset;
    filter = estado;
    plantFilter = plantId;
    return removed
        ? []
        : List.generate(
            offset == 0 ? count : 1,
            (i) => request(i + 1 + offset),
          );
  }

  @override
  Future<AdoptionRequest> detail(int id) async => request(id);
  @override
  Future<AdoptionRequest> edit(int id, String value) async {
    if (conflict) {
      status = 'ACEPTADA';
      throw Exception('La solicitud ya no está pendiente');
    }
    edits++;
    message = value;
    return request(id);
  }

  @override
  Future<void> withdraw(int id) async {
    removals++;
    removed = true;
  }
}

Future<void> open(WidgetTester tester, Requests service) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthController>(
      create: (_) => Auth(),
      child: MaterialApp(home: MyRequestsView(service: service)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('valida mensaje, edita y permite cancelar o confirmar retiro', (
    tester,
  ) async {
    final service = Requests();
    await open(tester, service);
    await tester.tap(find.text('Editar mensaje'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, ' ');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNull,
    );
    await tester.enterText(input, 'a' * 501);
    await tester.pump();
    expect(
      find.text('El mensaje no puede superar 500 caracteres.'),
      findsOneWidget,
    );
    expect(service.edits, 0);
    await tester.enterText(input, 'Texto actualizado');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(service.message, 'Texto actualizado');
    expect(find.text('Texto actualizado'), findsOneWidget);
    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.removals, 0);
    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();
    expect(service.removals, 1);
    expect(find.text('No hay solicitudes con estos filtros.'), findsOneWidget);
  });
  testWidgets('aceptación mientras se edita muestra error y elimina acciones', (
    tester,
  ) async {
    final service = Requests()..conflict = true;
    await open(tester, service);
    await tester.tap(find.text('Editar mensaje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(service.edits, 0);
    expect(find.text('La solicitud ya no está pendiente'), findsOneWidget);
    expect(find.text('Editar mensaje'), findsNothing);
    expect(find.text('Retirar'), findsNothing);
  });
  testWidgets('paginación y filtro de planta hacen consultas nuevas', (
    tester,
  ) async {
    final service = Requests()..count = 20;
    await open(tester, service);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(service.lastOffset, 20);
    await tester.enterText(find.byType(TextField).first, '2');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(service.lastOffset, 0);
    expect(service.plantFilter, 2);
    expect(tester.takeException(), isNull);
  });
}
