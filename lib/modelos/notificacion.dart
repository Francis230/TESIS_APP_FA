// Archivo - lib/modelos/notificacion.dart
// Modelo que representa las notificaciones.
// Corresponde a la tabla "notificaciones" en Supabase.

// Define la estructura de datos para el intercambio de mensajes y alertas informativas entre usuarios del sistema
class Notificacion {
  final String notificacionId;
  final String destinatarioId;
  final String? emisorId;
  final String? tipo;
  final String? titulo;
  final String? mensaje;
  final bool leida;
  final Map<String, dynamic>? payloadJson;
  final DateTime creadaEn;
  // Constructor que inicializa la instancia asegurando la integridad de los datos de comunicación
  Notificacion({
    required this.notificacionId,
    required this.destinatarioId,
    this.emisorId,
    this.tipo,
    this.titulo,
    this.mensaje,
    required this.leida,
    this.payloadJson,
    required this.creadaEn,
  });
  // Convierte el registro de la base de datos en un objeto estructurado para su visualización
  factory Notificacion.fromMap(Map<String, dynamic> map) {
    return Notificacion(
      notificacionId: map['notificacion_id'] ?? '',
      destinatarioId: map['destinatario_id'] ?? '',
      emisorId: map['emisor_id'],
      tipo: map['tipo'],
      titulo: map['titulo'],
      mensaje: map['mensaje'],
      leida: map['leida'] ?? false,
      payloadJson: map['payload_json'],
      creadaEn: DateTime.parse(map['creada_en']),
    );
  }
  // Con un objeto para su almacenamiento persistente o transmisión en red
  Map<String, dynamic> toMap() {
    return {
      'notificacion_id': notificacionId,
      'destinatario_id': destinatarioId,
      'emisor_id': emisorId,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': leida,
      'payload_json': payloadJson,
      'creada_en': creadaEn.toIso8601String(),
    };
  }
}
