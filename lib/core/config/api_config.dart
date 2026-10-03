/// Configuracion central de la API REST.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://adopplant-api.onrender.com';
  static const Duration requestTimeout = Duration(seconds: 60);

  static const String loginPath = '/api/auth/login';
  static const String registerPath = '/api/auth/registro';
  static const String forgotPasswordPath = '/api/auth/forgot-password';
  static const String resetPasswordPath = '/api/auth/reset-password';
  static const String profilePath = '/api/usuarios/me';
  static const String plantsPath = '/api/plantas';
  static const String myPlantsPath = '/api/plantas/mias';
  static const String requestsPath = '/api/solicitudes';
  static const String receivedRequestsPath = '/api/solicitudes/recibidas';
  static const String myRequestsPath = '/api/solicitudes/mias';
}
