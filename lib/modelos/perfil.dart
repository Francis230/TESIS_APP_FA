// Arhivo - libs/modelos/perfil.dart
// Modelo que representa los perfiles de usuario.
// Corresponde a la tabla "perfiles" en Supabase.
// Define la estructura de datos personales y credenciales de acceso para los usuarios del sistema
class Perfil {
  final String id;
  final String? nombreCompleto;
  final String? correo;
  final String? telefono;
  final String? direccion;
  final String rolId;
  final String? fotoUrl;
  final String? documentoIdentidad;
  final bool debeCambiarClave;
  final String? tokenPush;
  final DateTime? ultimoAcceso;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  // Constructor que inicializa la instancia asegurando la integridad de los datos de identidad
  Perfil({
    required this.id,
    this.nombreCompleto,
    this.correo,
    this.telefono,
    this.direccion,
    required this.rolId,
    this.fotoUrl,
    this.documentoIdentidad,
    required this.debeCambiarClave,
    this.tokenPush,
    this.ultimoAcceso,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  // Convierte el registro de la base de datos en un objeto estructurado para su gestión en la app
  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] ?? '',
      nombreCompleto: map['nombre_completo'],
      correo: map['correo'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      rolId: map['rol_id'] ?? '',
      fotoUrl: map['foto_url'],
      documentoIdentidad: map['documento_identidad'],
      debeCambiarClave: map['debe_cambiar_clave'] ?? false,
      tokenPush: map['token_push'],
      ultimoAcceso: map['ultimo_acceso'] != null ? DateTime.parse(map['ultimo_acceso']) : null,
      creadoEn: DateTime.parse(map['creado_en']),
      actualizadoEn: DateTime.parse(map['actualizado_en']),
    );
  }
  // El perfil ayuda al formato mapa para operaciones de actualización o transferencia
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'correo': correo,
      'telefono': telefono,
      'direccion': direccion,
      'rol_id': rolId,
      'foto_url': fotoUrl,
      'documento_identidad': documentoIdentidad,
      'debe_cambiar_clave': debeCambiarClave,
      'token_push': tokenPush,
      'ultimo_acceso': ultimoAcceso?.toIso8601String(),
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}
