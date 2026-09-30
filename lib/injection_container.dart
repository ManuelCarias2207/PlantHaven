import 'package:get_it/get_it.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/plant_service.dart';
import 'package:flutter_app/utils/session_manager.dart';

/// Contenedor de inyección de dependencias usando get_it.
/// Registra todas las dependencias de la app en un solo lugar.
final sl = GetIt.instance;

/// Inicializa todas las dependencias de la app.
/// Debe llamarse antes de runApp().
Future<void> initDependencies() async {
  // --- Utils ---
  sl.registerLazySingleton<SessionManager>(() => SessionManager());

  // --- Services ---
  sl.registerLazySingleton<ApiService>(() => ApiService(
        sessionManager: sl<SessionManager>(),
      ));
  sl.registerLazySingleton<AuthService>(() => AuthService(
        apiService: sl<ApiService>(),
        sessionManager: sl<SessionManager>(),
  ));
  sl.registerLazySingleton<PlantService>(() => PlantService(
        apiService: sl<ApiService>(),
      ));

  // --- Controllers ---
  sl.registerFactory<AuthController>(() => AuthController(
        authService: sl<AuthService>(),
        sessionManager: sl<SessionManager>(),
  ));
  sl.registerFactory<PlantController>(() => PlantController(
        plantService: sl<PlantService>(),
      ));
}
