// // Arhivo - libs/modelos/representante.dart
// Modelo que representa a los representantes.
// Corresponde a la tabla "representantes" en Supabase.
// Define la estructura de datos para la gestión de los tutores legales responsables de los estudiantes
class Representante {
  final String representanteId;
  final String? parentesco;
  final String? telefonoEmergencia;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  // Inicializa la instancia validando la información crítica de contacto y responsabilidad
  Representante({
    required this.representanteId,
    this.parentesco,
    this.telefonoEmergencia,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  // Transforma la información de la base de datos en un objeto gestionable por la aplicación
  factory Representante.fromMap(Map<String, dynamic> map) {
    return Representante(
      representanteId: map['representante_id'] ?? '',
      parentesco: map['parentesco'],
      telefonoEmergencia: map['telefono_emergencia'],
      activo: map['activo'] ?? true,
      creadoEn: DateTime.parse(map['creado_en']),
      actualizadoEn: DateTime.parse(map['actualizado_en']),
    );
  }
  // Prepara los datos del representante para su almacenamiento o transmisión segura
  Map<String, dynamic> toMap() {
    return {
      'representante_id': representanteId,
      'parentesco': parentesco,
      'telefono_emergencia': telefonoEmergencia,
      'activo': activo,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

