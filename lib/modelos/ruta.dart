// // Arhivo - libs/modelos/ruta.dart
// Modelo que representa las rutas.
// Corresponde a la tabla "rutas" en Supabase.
// Define la estructura de los itinerarios de transporte planificados para la recolección de estudiantes
class Ruta {
  final String rutaId;
  final String numeroRuta;
  final String? sector;
  final String? descripcion;
  final bool activo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  // Inicializa la instancia validando los parámetros logísticos esenciales del recorrido
  Ruta({
    required this.rutaId,
    required this.numeroRuta,
    this.sector,
    this.descripcion,
    required this.activo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  // Convierte la estructura de datos externa en un objeto manipulable para la gestión logística
  factory Ruta.fromMap(Map<String, dynamic> map) {
    return Ruta(
      rutaId: map['ruta_id'] ?? '',
      numeroRuta: map['numero_ruta'] ?? '',
      sector: map['sector'],
      descripcion: map['descripcion'],
      activo: map['activo'] ?? true,
      creadoEn: DateTime.parse(map['creado_en']),
      actualizadoEn: DateTime.parse(map['actualizado_en']),
    );
  }
  // Configuración de la ruta para su almacenamiento o distribución a los conductores
  Map<String, dynamic> toMap() {
    return {
      'ruta_id': rutaId,
      'numero_ruta': numeroRuta,
      'sector': sector,
      'descripcion': descripcion,
      'activo': activo,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}

