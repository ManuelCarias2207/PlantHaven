import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/routes/app_router.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/plant_controller.dart';
import 'package:flutter_app/controllers/adoption_request_controller.dart';
import 'package:flutter_app/injection_container.dart';
import 'package:flutter_app/services/local_chat_store.dart';
import 'package:flutter_app/services/pending_plant_draft.dart';
import 'package:flutter_app/utils/session_manager.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalChatStore.initialize();
  await PendingPlantDraft.initialize();
  try {
    if (await SessionManager().HasToken()) {
      PendingPlantDraft.initialRoute = PendingPlantDraft.value == null
          ? AppRoutes.home
          : PendingPlantDraft.pendingRoute;
    }
  } catch (_) {
    // La pantalla de acceso sigue disponible si no puede leerse la sesión.
  }

  // Capturar errores no manejados para mostrarlos en pantalla
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    await initDependencies();
  } catch (e) {
    debugPrint('Error initializing dependencies: $e');
  }

  runApp(const PlantHavenApp());
}

class PlantHavenApp extends StatelessWidget {
  const PlantHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthController>()),
        ChangeNotifierProvider(create: (_) => sl<PlantController>()),
        ChangeNotifierProvider(create: (_) => sl<AdoptionRequestController>()),
      ],
      child: MaterialApp.router(
        title: 'PlantHaven',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.background,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
