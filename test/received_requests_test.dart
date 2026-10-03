import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/services/adoption_request_service.dart';
import 'package:flutter_app/views/received_requests_view.dart';
import 'package:provider/provider.dart';

class Auth extends AuthController {
  @override
  Future<bool> ensureAuthenticated() async => true;
}
class Requests extends AdoptionRequestService {
  String status = 'PENDIENTE';
  int decisions = 0;
  AdoptionRequest get request => AdoptionRequest.fromJson({'id_solicitud':1,'id_planta':2,
    'nombre_planta':'Monstera', 'nombre_adoptante':'Ana', 'mensaje':'La cuidaré', 'estado':status});
  @override
  Future<List<AdoptionRequest>> received({int offset = 0, String? estado, int? plantId}) async => [request];
  @override
  Future<AdoptionRequest> decide(int id, String value) async { decisions++; status=value; return request; }
}
void main() {
  testWidgets('cancelar no decide; confirmar acepta y retira acciones pendientes', (tester) async {
    tester.view.physicalSize = const Size(320,844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service=Requests();
    await tester.pumpWidget(ChangeNotifierProvider<AuthController>(create: (_) => Auth(),
      child: MaterialApp(home: ReceivedRequestsView(service:service))));
    await tester.pumpAndSettle();
    expect(find.text('Ana'),findsOneWidget);
    await tester.tap(find.text('Aceptar')); await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar')); await tester.pumpAndSettle();
    expect(service.decisions,0);
    await tester.tap(find.text('Aceptar')); await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,'Aceptar').last);
    await tester.pumpAndSettle();
    expect(service.decisions,1);
    expect(find.text('ACEPTADA'),findsOneWidget);
    expect(find.text('Aceptar'),findsNothing);
    expect(tester.takeException(),isNull);
  });
}
