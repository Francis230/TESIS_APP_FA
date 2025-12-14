// Archivo - lib/servicios/auth_servicio.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_servicio.dart';
// Servicio encargado de centralizar la lógica de autenticación y la gestión de identidades
// Actúa como intermediario entre la interfaz de usuario y el backend (Supabase)
class AuthServicio {
  final _supabase = SupabaseServicio.cliente();

  // Iniciar sesión con correo y contraseña
  Future<AuthResponse> iniciarSesion(String correo, String clave) async {
    return await _supabase.auth.signInWithPassword(
      email: correo,
      password: clave,
    );
  }

  // Registro de un nuevo usuario creando su cuenta de acceso y su perfil 
  Future<AuthResponse> registrarUsuario({
    required String correo,
    required String clave,
    required String nombreCompleto,
    required String rolId,
    String? telefono,
    String? direccion,
  }) async {
    // 1. Crear la cuenta en el módulo de autenticación
    final respuesta =
        await _supabase.auth.signUp(email: correo, password: clave);
    final usuario = respuesta.user;
    if (usuario != null) {
      // Insertar los datos de perfil en la tabla "perfiles"
      await _supabase.from('perfiles').insert({
        'id': usuario.id,
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'direccion': direccion,
        'rol_id': rolId,
        // Obliga al usuario conductor a cambiar clave
        'debe_cambiar_clave': true, 
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    return respuesta;
  }

  // Finaliza la sesión actual y limpia las credenciales almacenadas en el dispositivo
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }
  // Verifica el estado actual de la autenticación para persistir el acceso del usuario
  Session? obtenerSesion() {
    return _supabase.auth.currentSession;
  }
}
