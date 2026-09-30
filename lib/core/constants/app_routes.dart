/// Nombres de rutas centralizados para evitar strings mágicos en el código.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  static const String catalog = home;
  static const String messages = '/mensajes';
  static const String publishPlant = '/publicar-planta';
  static const String myPublications = '/mis-publicaciones';
  static const String editPlant = '/editar-planta/:id';
}
