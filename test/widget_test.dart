import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App renders login page', (WidgetTester tester) async {
    await initDependencies();
    await tester.pumpWidget(const PlantHavenApp());
    await tester.pumpAndSettle();

    // Verifica que la pantalla de login se renderiza
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
