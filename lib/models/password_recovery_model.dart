/// Modelos de las solicitudes de recuperacion de contrasena.
class ForgotPasswordRequest {
  final String correo;

  const ForgotPasswordRequest({required this.correo});

  Map<String, dynamic> toJson() => {'correo': correo};
}

class ResetPasswordRequest {
  final String token;
  final String nuevaContrasena;
  final String confirmarContrasena;

  const ResetPasswordRequest({
    required this.token,
    required this.nuevaContrasena,
    required this.confirmarContrasena,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'nueva_contrasena': nuevaContrasena,
    'confirmar_contrasena': confirmarContrasena,
  };
}
