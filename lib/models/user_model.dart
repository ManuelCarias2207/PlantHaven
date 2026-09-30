/// Modelo de datos para el usuario.
/// Mapea el JSON de la API REST de AdopPlant.
class UserModel {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String estado;
  final String fechaRegistro;

  const UserModel({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.estado,
    required this.fechaRegistro,
  });

  /// Nombre completo del usuario.
  String get fullName => '$nombre $apellido';

  /// Crea un UserModel desde un JSON (mapa).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      fechaRegistro: json['fecha_registro'] as String? ?? '',
    );
  }

  /// Convierte el UserModel a JSON (mapa).
  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
      'estado': estado,
      'fecha_registro': fechaRegistro,
    };
  }

  /// Crea una copia con campos actualizados.
  UserModel copyWith({
    int? idUsuario,
    String? nombre,
    String? apellido,
    String? correo,
    String? telefono,
    String? estado,
    String? fechaRegistro,
  }) {
    return UserModel(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $idUsuario, nombre: $nombre, apellido: $apellido, correo: $correo)';
}
