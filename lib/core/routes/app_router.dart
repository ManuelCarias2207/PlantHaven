import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/views/login_view.dart';
import 'package:flutter_app/views/register_view.dart';
import 'package:flutter_app/views/profile_view.dart';
import 'package:flutter_app/views/forgot_password_view.dart';
import 'package:flutter_app/views/reset_password_view.dart';
import 'package:flutter_app/views/catalog_view.dart';
import 'package:flutter_app/views/plant_form_view.dart';
import 'package:flutter_app/views/my_plants_view.dart';
import 'package:flutter_app/services/pending_plant_draft.dart';

import 'package:flutter_app/views/plant_detail_view.dart';
import 'package:flutter_app/models/plant_model.dart';
import 'package:go_router/go_router.dart';

/// Router principal de la aplicación con guard de autenticación.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: PendingPlantDraft.initialRoute,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Guard básico: si no está autenticado y trata de acceder a ruta protegida,
      // redirigir al login.
      //
      // Por ahora, permitimos acceso a todas las rutas (el token se valida
      // en el Controller). En producción, aquí verificaríamos el token:
      //
      // final isAuthRoute = state.matchedLocation == AppRoutes.login ||
      //     state.matchedLocation == AppRoutes.register;
      // if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      // if (isAuthenticated && isAuthRoute) return AppRoutes.profile;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordView(
          correoInicial: state.extra is String ? state.extra as String : '',
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const CatalogView(),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Mensajes')),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'El chat entre usuarios todavía está pendiente de conexión con la API. Se habilitará después de aceptar una solicitud.',
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.publishPlant,
        builder: (context, state) => const PlantFormView(),
      ),
      GoRoute(
        path: AppRoutes.myPublications,
        builder: (context, state) => const MyPlantsView(),
      ),
      GoRoute(
        path: AppRoutes.plantDetail,
        builder: (context, state) {
          final plant = state.extra;
          if (plant is PlantModel) return PlantDetailView(plant: plant);
          return const Scaffold(
            body: Center(
              child: Text('No se pudo cargar el detalle de la planta.'),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editPlant,
        builder: (context, state) => PlantFormView(
          plantId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
}
