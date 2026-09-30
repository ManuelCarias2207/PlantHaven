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
      idCategoria: (json['id_categoria'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
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
    return PlantModel(
      idPlanta: (json['id_planta'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      tamano: json['tamano'] as String? ?? '',
      nivelCuidado: json['nivel_cuidado'] as String? ?? '',
      estadoSalud: json['estado_salud'] as String? ?? '',
      necesidadLuz: json['necesidad_luz'] as String? ?? '',
      necesidadAgua: json['necesidad_agua'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      ubicacion: json['ubicacion'] as String? ?? '',
      estadoPlanta: json['estado_planta'] as String? ?? '',
      fechaPublicacion: DateTime.tryParse(
        json['fecha_publicacion'] as String? ?? '',
      ),
      visible: json['visible'] as bool? ?? true,
      eliminada: json['eliminada'] as bool? ?? false,
      idUsuario: (json['id_usuario'] as num?)?.toInt() ?? 0,
      idCategoria: (json['id_categoria'] as num?)?.toInt() ?? 0,
      fotografiaUrl: json['fotografia_url'] as String?,
      puedeSolicitar: json['puede_solicitar'] as bool? ?? false,
      categoria: json['categoria'] is Map<String, dynamic>
          ? PlantCategory.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
    );
  }
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
