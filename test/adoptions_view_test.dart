import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/adoption_service.dart';
import 'package:flutter_app/views/adoptions_view.dart';

class FakeAdoptions extends AdoptionService {
  final String role;
  int calls = 0;
  bool saved = false;
  FakeAdoptions(this.role);
  AdoptionStatus get item => AdoptionStatus.fromJson({
    'id_adopcion': 1,
    'id_planta': 2,
    'estado': saved ? 'COMPLETADA' : 'EN_PROCESO',
    'rol': role,
    'donante': 'Donante',
    'adoptante': 'Adoptante',
    'planta': {'nombre': 'Monstera'},
    'fecha_entrega': role == 'adoptante' || saved
        ? '2026-10-03T10:00:00Z'
        : null,
    'fecha_recepcion': role == 'donante' || saved
        ? '2026-10-03T10:01:00Z'
        : null,
  });
  @override
  Future<List<AdoptionStatus>> list() async => [item];
  @override
  Future<AdoptionStatus> confirm(AdoptionStatus adoption) async {
    calls++;
    saved = true;
    return item;
  }
}

void main() {
  for (final role in ['donante', 'adoptante']) {
    testWidgets('$role ve su acción, puede cancelar y completar una sola vez', (
      tester,
    ) async {
      final service = FakeAdoptions(role);
      final label = role == 'donante'
          ? 'Confirmar entrega'
          : 'Confirmar recepción';
      await tester.pumpWidget(
        MaterialApp(home: AdoptionsView(service: service)),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, confirmar'));
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(find.text(label), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
