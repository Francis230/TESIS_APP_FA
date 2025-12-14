// // Archivo - lib/modelos/estudiantes.dart
// Modelo que representa a los estudiantes.
// Corresponde a la tabla "estudiantes" en Supabase.
// Define la estructura de información personal, académica y logística del alumnado usuario del servicio
class Estudiante {
  final String estudianteId;
  final String nombreCompleto;
  final DateTime? fechaNacimiento;
  final String? cedula;
  final String? grado;
  final String? paralelo;
  final String? direccion;
  final String? alergias;
  final String? observaciones;
  final String? fotoUrl;
  final String? representanteId;
  final String? conductorId;
  final String? rutaId;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  // Constructor para inicializar la instancia con los datos requeridos y opcionales
  Estudiante({
    required this.estudianteId,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.cedula,
    this.grado,
    this.paralelo,
    this.direccion,
    this.alergias,
    this.observaciones,
    this.fotoUrl,
    this.representanteId,
    this.conductorId,
    this.rutaId,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  // Transforma la respuesta de la base de datos en un objeto estructurado
  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      estudianteId: map['estudiante_id'] ?? '',
      nombreCompleto: map['nombre_completo'] ?? '',
      fechaNacimiento: map['fecha_nacimiento'] != null ? DateTime.parse(map['fecha_nacimiento']) : null,
      cedula: map['cedula'],
      grado: map['grado'],
      paralelo: map['paralelo'],
      direccion: map['direccion'],
      alergias: map['alergias'],
      observaciones: map['observaciones'],
      fotoUrl: map['foto_url'],
      representanteId: map['representante_id'],
      conductorId: map['conductor_id'],
      rutaId: map['ruta_id'],
      activo: map['activo'] ?? true,
      creadoEn: DateTime.parse(map['creado_en']),
      actualizadoEn: DateTime.parse(map['actualizado_en']),
    );
  }
  // El objeto para su almacenamiento o transmisión de datos
  Map<String, dynamic> toMap() {
    return {
      'estudiante_id': estudianteId,
      'nombre_completo': nombreCompleto,
      'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
      'cedula': cedula,
      'grado': grado,
      'paralelo': paralelo,
      'direccion': direccion,
      'alergias': alergias,
      'observaciones': observaciones,
      'foto_url': fotoUrl,
      'representante_id': representanteId,
      'conductor_id': conductorId,
      'ruta_id': rutaId,
      'activo': activo,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

