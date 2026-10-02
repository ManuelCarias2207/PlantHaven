class PlantCategory {
  final int idCategoria;
  final String nombre;
  final String estado;

  const PlantCategory({
    required this.idCategoria,
    required this.nombre,
    required this.estado,
  });

  factory PlantCategory.fromJson(Map<String, dynamic> json) {
    return PlantCategory(
      idCategoria:
          (json['id_categoria'] as num?)?.toInt() ??
          (json['categoria_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      nombre:
          (json['nombre'] ?? json['name'] ?? json['descripcion']) as String? ??
          '',
      estado: json['estado'] as String? ?? '',
    );
  }
}

class PlantModel {
  final int idPlanta;
  final String nombre;
  final String tamano;
  final String nivelCuidado;
  final String estadoSalud;
  final String necesidadLuz;
  final String necesidadAgua;
  final String? descripcion;
  final String ubicacion;
  final String estadoPlanta;
  final DateTime? fechaPublicacion;
  final bool visible;
  final bool eliminada;
  final int idUsuario;
  final int idCategoria;
  final String? fotografiaUrl;
  final bool puedeSolicitar;
  final PlantCategory? categoria;

  const PlantModel({
    required this.idPlanta,
    required this.nombre,
    required this.tamano,
    required this.nivelCuidado,
    required this.estadoSalud,
    required this.necesidadLuz,
    required this.necesidadAgua,
    required this.descripcion,
    required this.ubicacion,
    required this.estadoPlanta,
    required this.fechaPublicacion,
    required this.visible,
    required this.eliminada,
    required this.idUsuario,
    required this.idCategoria,
    required this.fotografiaUrl,
    required this.puedeSolicitar,
    required this.categoria,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    final idCategoria = _asInt(json['id_categoria'] ?? json['categoria_id']);
    final categoriaJson = json['categoria'];

    return PlantModel(
      idPlanta: _asInt(json['id_planta'] ?? json['id']),
      nombre: _asString(json['nombre']),
      tamano: _asString(json['tamano']),
      nivelCuidado: _asString(json['nivel_cuidado']),
      estadoSalud: _asString(json['estado_salud']),
      necesidadLuz: _asString(json['necesidad_luz']),
      necesidadAgua: _asString(json['necesidad_agua']),
      descripcion: _asNullableString(json['descripcion']),
      ubicacion: _asString(json['ubicacion']),
      estadoPlanta: _asString(json['estado_planta']),
      fechaPublicacion: DateTime.tryParse(_asString(json['fecha_publicacion'])),
      visible: _asBool(json['visible'], fallback: true),
      eliminada: _asBool(json['eliminada']),
      idUsuario: _asInt(json['id_usuario'] ?? json['usuario_id']),
      idCategoria: idCategoria,
      fotografiaUrl: _imageUrl(json),
      puedeSolicitar: _asBool(json['puede_solicitar']),
      categoria: categoriaJson is Map<String, dynamic>
          ? PlantCategory.fromJson(categoriaJson)
          : PlantCategory(
              idCategoria: idCategoria,
              nombre: 'Sin categoría',
              estado: '',
            ),
    );
  }

  static String _asString(dynamic value) => value is String ? value : '';

  static String? _imageUrl(Map<String, dynamic> json) {
    final value = json['fotografia_url'] ??
        json['foto_url'] ??
        json['imagen_url'] ??
        json['fotografia'] ??
        json['foto'] ??
        json['imagen'] ??
        json['image_url'] ??
        json['image'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Map<String, dynamic>) {
      final nested = value['url'] ?? value['secure_url'] ?? value['src'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }
    return null;
  }

  static String? _asNullableString(dynamic value) =>
      value is String ? value : null;

  static int _asInt(dynamic value) => value is num ? value.toInt() : 0;

  static bool _asBool(dynamic value, {bool fallback = false}) =>
      value is bool ? value : fallback;
}

class PlantRequest {
  final String nombre;
  final String tamano;
  final String nivelCuidado;
  final String estadoSalud;
  final String necesidadLuz;
  final String necesidadAgua;
  final String ubicacion;
  final int idCategoria;
  final String? descripcion;

  const PlantRequest({
    required this.nombre,
    required this.tamano,
    required this.nivelCuidado,
    required this.estadoSalud,
    required this.necesidadLuz,
    required this.necesidadAgua,
    required this.ubicacion,
    required this.idCategoria,
    this.descripcion,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'tamano': tamano,
    'nivel_cuidado': nivelCuidado,
    'estado_salud': estadoSalud,
    'necesidad_luz': necesidadLuz,
    'necesidad_agua': necesidadAgua,
    'ubicacion': ubicacion,
    'id_categoria': idCategoria,
    if (descripcion != null && descripcion!.trim().isNotEmpty)
      'descripcion': descripcion,
  };
}
