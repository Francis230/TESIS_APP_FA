// Archivo - lib/features/auth/data/auth_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../servicios/supabase_servicio.dart';
import 'dart:convert';
// Notifica a toda la aplicación cuando ocurren cambios importantes en la información del usuario
final perfilActualizadoNotifier = ValueNotifier<bool>(false);
// Centraliza todas las operaciones de seguridad, control de acceso y gestión de cuentas de usuario
class AuthRepository {
  final SupabaseClient _cliente = SupabaseServicio.cliente();

  // Inicia sesión con correo y contraseña.
  // Lanza excepción con mensaje en español si ocurre un error.
  Future<User> iniciarSesion(String correo, String clave) async {
    final res = await _cliente.auth.signInWithPassword(
      email: correo,
      password: clave,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Credenciales inválidas.');
    }
    
    return user;
  }
  
  // Obtiene el registro de perfil desde la tabla 'perfiles' por id.
  // Devuelve null si no existe.
  Future<Map<String, dynamic>?> obtenerPerfilPorId(String userId) async {
    final respuesta = await _cliente
        .from('perfiles')
        .select('*, roles(nombre_rol)')
        .eq('id', userId)
        .maybeSingle();
    if (respuesta == null) return null;
    if (respuesta is Map<String, dynamic>) return respuesta;
    return (respuesta as dynamic);
  }

  // Obtiene el nombre del rol dado su id (columna 'rol_id' / 'nombre_rol').
  Future<String?> obtenerNombreRolPorId(String rolId) async {
    if (rolId == null || rolId.isEmpty) return null;
    final resp = await _cliente
        .from('roles')
        .select('nombre_rol')
        .eq('rol_id', rolId)
        .maybeSingle();
    if (resp == null) return null;
    if (resp is Map<String, dynamic> && resp.containsKey('nombre_rol'))
      return resp['nombre_rol'] as String?;
    return null;
  }
  // Registrar a un representante
  Future<void> registrarRepresentante({
    required String correo,
    required String clave,
    required String nombreCompleto,
    required String telefono,
    required String parentesco,
    required String cedula,
    required String direccion,
  }) async {
    try {
      // Crear usuario en Auth
      final res = await _cliente.auth.signUp(email: correo, password: clave);
      final user = res.user;

      if (user == null) {
        throw Exception('No se pudo crear el usuario en Auth.');
      }

      // Iniciar sesión inmediatamente 
      await _cliente.auth.signInWithPassword(email: correo, password: clave);

      // Obtener rol_id para 'representante'
      final rolResp = await _cliente
          .from('roles')
          .select('rol_id')
          .eq('nombre_rol', 'representante')
          .maybeSingle();

      final rolId = (rolResp is Map<String, dynamic>) ? rolResp['rol_id'] : null;

      // Crear o actualizar el perfil 
      final perfil = {
        'id': user.id,
        'nombre_completo': nombreCompleto,
        'correo': correo,
        'telefono': telefono,
        'rol_id': rolId,
        'debe_cambiar_clave': false,
        'documento_identidad': cedula,
        'direccion': direccion,
      };

      final resultadoPerfil =
          await _cliente.from('perfiles').upsert(perfil).select();

      print('Perfil creado o actualizado correctamente: $resultadoPerfil');

      // Insertar en representantes 
      final existeRepresentante = await _cliente
          .from('representantes')
          .select('representante_id')
          .eq('representante_id', user.id)
          .maybeSingle();

      if (existeRepresentante == null) {
        final representante = {
          'representante_id': user.id,
          'parentesco': parentesco,
          'activo': true,
        };

        final resultadoRep = await _cliente
            .from('representantes')
            .insert(representante)
            .select();

        print(' Representante insertado correctamente: $resultadoRep');
      } else {
        print(' El representante ya existía. No se volvió a insertar.');
      }

      //Cerrar sesión 
      await _cliente.auth.signOut();

    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado durante el registro: $e');
    }
  }


  // Cambia la contraseña del usuario autenticado.
  Future<void> cambiarClaveUsuario(String nuevaClave) async {
    await _cliente.auth.updateUser(UserAttributes(password: nuevaClave));
  }

  // Modifica el estado que indica si el usuario debe renovar su contraseña obligatoriamente
  Future<void> actualizarFlagCambioClave(String userId, bool valor) async {
    await _cliente
        .from('perfiles')
        .update({'debe_cambiar_clave': valor})
        .eq('id', userId);
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _cliente.auth.signOut();
  }
  /// Envía un correo de recuperación de contraseña.
  Future<void> enviarRecuperacionContrasena(
    String correo, {
    String? redirectHost,
  }) async {
    try {
      // Determinar la URL de redirección basada en el entorno
      final String redirectUrl;
      if (kIsWeb && redirectHost != null) {
        redirectUrl =
            '$redirectHost/#/aplicar-nueva-clave'; 
      } else {
        redirectUrl = 'emausapp://recovery';
      }

      await _cliente.auth.resetPasswordForEmail(
        correo,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      throw Exception('No se pudo enviar recuperación de contraseña: $e');
    }
  }
  // Solicita el envío de un código numérico para validar la identidad del usuario
  Future<void> solicitarCodigoDeRecuperacion(String email) async {
    try {
      await _cliente.functions.invoke(
        'olvidascontra',
        body: {'email': email},
      );
    } catch (e) {
      throw Exception('Error al solicitar el código de recuperación: $e');
    }
  }

  // Confirma el código de seguridad recibido y establece la nueva contraseña definitiva
  Future<void> verificarCodigoYActualizarClave({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _cliente.functions.invoke('verificar-y-actualizar-clave', body: {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw 'Ocurrió un error al actualizar la contraseña: $e';
    }
  }

  // Obtiene el perfil completo del usuario actualmente logueado.
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      if (_cliente.auth.currentUser == null) return null;
      final userId = _cliente.auth.currentUser!.id;
      final data = await _cliente
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      print('Error en getMyProfile: $e');
      return null;
    }
  }
  // Verificar si el usuario tiene un perfil de conductor activo
  Future<bool> esConductorActivo(String userId) async {
    try {
      final response = await _cliente
          .from('conductores')
          .select('conductor_id')
          .eq('conductor_id', userId)
          .eq('permiso_activo', true) 
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Error verificando conductor: $e');
      return false; 
    }
  }
}
