/// Modelos de las solicitudes de recuperacion de contrasena.
class ForgotPasswordRequest {
  final String correo;

  const ForgotPasswordRequest({required this.correo});

  Map<String, dynamic> toJson() => {'correo': correo};
}

class ResetPasswordRequest {
  final String correo;
  final String codigo;
  final String nuevaContrasena;
  final String confirmarContrasena;

  const ResetPasswordRequest({
    required this.correo,
    required this.codigo,
    required this.nuevaContrasena,
    required this.confirmarContrasena,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'codigo': codigo,
    'nueva_contrasena': nuevaContrasena,
    'confirmar_contrasena': confirmarContrasena,
  };
}
