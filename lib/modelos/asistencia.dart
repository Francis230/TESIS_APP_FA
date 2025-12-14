// Archivo - lib/modelos/asistencia.dart
// Modelo que representa la asistencia de los estudiantes
// Corresponde a la tabla "asistencia" en Supabase

// Representa la estructura de datos para el control de asistencia diaria de los estudiantes
class Asistencia {
  final String asistenciaId;
  final String estudianteId;
  final String conductorId;
  final DateTime fecha;
  final bool asistenciaManana;
  final bool asistenciaTarde;
  final bool ausenteJustificado;
  final String? motivoAusencia;
  final String? notas;
  final String? registradoPor;
  final DateTime creadoEn;
  // Inicializa una instancia inmutable con todos los atributos requeridos
  Asistencia({
    required this.asistenciaId,
    required this.estudianteId,
    required this.conductorId,
    required this.fecha,
    required this.asistenciaManana,
    required this.asistenciaTarde,
    required this.ausenteJustificado,
    this.motivoAusencia,
    this.notas,
    this.registradoPor,
    required this.creadoEn,
  });
  // Transforma un objeto JSON proveniente de la base de datos en una instancia Dart
  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      asistenciaId: map['asistencia_id'] ?? '',
      estudianteId: map['estudiante_id'] ?? '',
      conductorId: map['conductor_id'] ?? '',
      fecha: DateTime.parse(map['fecha']),
      asistenciaManana: map['asistencia_manana'] ?? false,
      asistenciaTarde: map['asistencia_tarde'] ?? false,
      ausenteJustificado: map['ausente_justificado'] ?? false,
      motivoAusencia: map['motivo_ausencia'],
      notas: map['notas'],
      registradoPor: map['registrado_por'],
      creadoEn: DateTime.parse(map['creado_en']),
    );
  }
  // Convierte la instancia actual en un mapa para su persistencia en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'asistencia_id': asistenciaId,
      'estudiante_id': estudianteId,
      'conductor_id': conductorId,
      'fecha': fecha.toIso8601String(),
      'asistencia_manana': asistenciaManana,
      'asistencia_tarde': asistenciaTarde,
      'ausente_justificado': ausenteJustificado,
      'motivo_ausencia': motivoAusencia,
      'notas': notas,
      'registrado_por': registradoPor,
      'creado_en': creadoEn.toIso8601String(),
    };
  }
}
