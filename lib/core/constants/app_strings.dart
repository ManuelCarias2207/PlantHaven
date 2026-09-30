/// Textos centralizados de la app para facilitar mantenibilidad y futura i18n.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'PlantHaven';

  // Login
  static const String loginTitle = 'Bienvenido de nuevo';
  static const String loginSubtitle = 'Ingresa tus credenciales para acceder';
  static const String loginIdentifierLabel = 'Correo o teléfono';
  static const String loginIdentifierHint = 'correo@ejemplo.com o 0000 0000';
  static const String loginPasswordLabel = 'Contraseña';
  static const String loginPasswordHint = '••••••••';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';
  static const String loginButton = 'Iniciar Sesión';
  static const String loginFooterNoAccount = '¿No tienes cuenta? ';
  static const String loginFooterRegister = 'Regístrate';

  // Recuperacion de contrasena
  static const String forgotPasswordTitle = 'Recuperar contrasena';
  static const String forgotPasswordSubtitle =
      'Te enviaremos un codigo para recuperar tu cuenta';
  static const String forgotPasswordEmailLabel = 'Correo electronico';
  static const String forgotPasswordEmailHint = 'correo@ejemplo.com';
  static const String forgotPasswordButton = 'Enviar codigo';
  static const String forgotPasswordSuccess =
      'Revisa tu correo para obtener el codigo de recuperacion.';
  static const String resetPasswordTitle = 'Restablecer contrasena';
  static const String resetPasswordSubtitle =
      'Ingresa el codigo recibido y crea una nueva contrasena';
  static const String resetPasswordCodeLabel = 'Codigo o token';
  static const String resetPasswordCodeHint = 'Ingresa el codigo recibido';
  static const String resetPasswordNewLabel = 'Nueva contrasena';
  static const String resetPasswordConfirmLabel = 'Confirmar nueva contrasena';
  static const String resetPasswordButton = 'Actualizar contrasena';
  static const String resetPasswordSuccess =
      'Contrasena actualizada. Ya puedes iniciar sesion.';
  static const String resetPasswordBack = 'Volver a iniciar sesion';

  // Register
  static const String registerTitle = 'Crear cuenta';
  static const String registerSubtitle =
      'Únete a PlantHaven y descubre el mundo vegetal';
  static const String registerNameLabel = 'Nombres';
  static const String registerNameHint = 'Tus nombres';
  static const String registerLastNameLabel = 'Apellidos';
  static const String registerLastNameHint = 'Tus apellidos';
  static const String registerPhoneLabel = 'Teléfono móvil';
  static const String registerPhoneHint = '0000 0000';
  static const String registerEmailLabel = 'Correo electrónico';
  static const String registerEmailHint = 'correo@ejemplo.com';
  static const String registerPasswordLabel = 'Contraseña';
  static const String registerPasswordHint = '••••••••';
  static const String registerConfirmPasswordLabel = 'Confirmar contraseña';
  static const String registerConfirmPasswordHint = '••••••••';
  static const String registerTerms = 'Acepto los ';
  static const String registerTermsLink = 'Términos y Condiciones';
  static const String registerButton = 'Registrarse';
  static const String registerFooterHaveAccount = '¿Ya tienes cuenta? ';
  static const String registerFooterLogin = 'Inicia sesión';

  // Profile
  static const String profileTitle = 'Mi Perfil';
  static const String profileSubtitle = 'Gestiona tu información personal';
  static const String profileNameLabel = 'Nombres';
  static const String profileLastNameLabel = 'Apellidos';
  static const String profileEmailLabel = 'Correo electrónico';
  static const String profilePhoneLabel = 'Teléfono móvil';
  static const String profileMemberSince = 'Miembro desde';
  static const String profileEditButton = 'Editar perfil';
  static const String profileSaveButton = 'Guardar cambios';
  static const String profileCancelButton = 'Cancelar';
  static const String profileLogoutButton = 'Cerrar sesión';
  static const String profileLoading = 'Cargando perfil...';
  static const String profileError = 'No se pudo cargar el perfil';
  static const String profileUpdateSuccess = 'Perfil actualizado correctamente';
  static const String profileUpdateError = 'No se pudo actualizar el perfil';

  // Validaciones
  static const String validationRequired = 'Este campo es obligatorio';
  static const String validationEmailFormat = 'Ingresa un correo válido';
  static const String validationPasswordMinLength = 'Mínimo 8 caracteres';
  static const String validationPasswordLettersNumbers =
      'Debe incluir letras y números';
  static const String validationPasswordMatch = 'Las contraseñas no coinciden';
  static const String validationTerms =
      'Debes aceptar los términos y condiciones';
  static const String validationPhoneFormat = 'Ingresa un teléfono válido';

  // Errores de auth
  static const String authInvalidCredentials = 'Credenciales inválidas';
  static const String authEmailAlreadyRegistered =
      'Este correo ya está registrado';
  static const String authPhoneAlreadyRegistered =
      'Este teléfono ya está registrado';
  static const String authGenericError =
      'Ocurrió un error. Inténtalo de nuevo.';

  // Password strength
  static const String passwordStrengthLabel = 'La contraseña debe tener:';
  static const String passwordStrengthMin = 'Mínimo 8 caracteres';
  static const String passwordStrengthLetters = 'Letras';
  static const String passwordStrengthNumbers = 'Números';

  // Placeholder
  static const String placeholderLogo = '🌿';

  // Catalog
  static const String catalogTitle = 'Catálogo';
}
