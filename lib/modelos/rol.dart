// // Arhivo - libs/modelos/rol.dart
// Modelo que representa los roles de usuario
// Corresponde a la tabla "roles" en Supabase
// Define la categorización de privilegios y niveles de acceso dentro de la plataforma
class Rol {
  final String rolId;
  final String nombreRol;
  final String? descripcion;

  Rol({
    required this.rolId,
    required this.nombreRol,
    this.descripcion,
  });
  // Convierte la estructura de datos externa en un objeto de dominio interno para su gestión
  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      rolId: map['rol_id'] ?? '',
      nombreRol: map['nombre_rol'] ?? '',
      descripcion: map['descripcion'],
    );
  }
  // Definición del rol para su persistencia o transporte de dato 
  Map<String, dynamic> toMap() {
    return {
      'rol_id': rolId,
      'nombre_rol': nombreRol,
      'descripcion': descripcion,
    };
  }
}
