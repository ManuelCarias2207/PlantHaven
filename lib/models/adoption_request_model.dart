class AdoptionRequest {
  final int id;
  final int plantId;
  final String plantName;
  final String adopterName;
  final String adopterEmail;
  final String reason;
  final String status;
  final DateTime? createdAt;

  const AdoptionRequest({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.adopterName,
    required this.adopterEmail,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    final plant = json['planta'] is Map<String, dynamic>
        ? json['planta'] as Map<String, dynamic>
        : <String, dynamic>{};
    final adopter = json['adoptante'] is Map<String, dynamic>
        ? json['adoptante'] as Map<String, dynamic>
        : (json['usuario'] is Map<String, dynamic>
              ? json['usuario'] as Map<String, dynamic>
              : <String, dynamic>{});
    return AdoptionRequest(
      id: _int(json['id_solicitud'] ?? json['solicitud_id'] ?? json['id']),
      plantId: _int(
        json['id_planta'] ??
            json['plant_id'] ??
            plant['id_planta'] ??
            plant['id'],
      ),
      plantName: _string(json['nombre_planta'] ?? plant['nombre']),
      adopterName: _string(
        json['nombre_adoptante'] ?? adopter['nombre'] ?? adopter['name'],
      ),
      adopterEmail: _string(
        json['correo_adoptante'] ?? adopter['correo'] ?? adopter['email'],
      ),
      reason: _string(json['motivo'] ?? json['mensaje']),
      status: _string(json['estado'] ?? json['status']).isEmpty
          ? 'PENDIENTE'
          : _string(json['estado'] ?? json['status']),
      createdAt: DateTime.tryParse(
        _string(
          json['fecha_solicitud'] ??
              json['created_at'] ??
              json['fecha_creacion'],
        ),
      ),
    );
  }
  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static String _string(dynamic v) => v is String ? v : v?.toString() ?? '';
}
