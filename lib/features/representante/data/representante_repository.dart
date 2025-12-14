// Archivo - lib/features/representante/data/representante_repository.dart
import 'dart:async';
import 'dart:typed_data'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../servicios/supabase_servicio.dart';
// Centraliza el acceso a la información y las operaciones exclusivas del perfil de representante
class RepresentanteRepository {
  final SupabaseClient _cliente = SupabaseServicio.cliente();
  // Obtiene el ID del usuario autenticado actualmente.
  String get _userId {
    final user = _cliente.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }
    return user.id;
  }

  // La lista de estudiantes vinculados legalmente al representante logueado.
  Future<List<Map<String, dynamic>>> obtenerEstudiantes() async {
     final res = await _cliente
        .from('estudiantes')
        .select('estudiante_id, nombre_completo, grado, paralelo, foto_url, ruta_id, conductor_id')
        .eq('representante_id', _userId)
        .eq('activo', true);
    return List<Map<String, dynamic>>.from(res);
  }

  // Consulta el historial de alertas y mensajes recibidos por el usuario
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
     final res = await _cliente
        .from('notificaciones')
        .select('notificacion_id, tipo, titulo, mensaje, leida, creada_en')
        .eq('destinatario_id', _userId)
        .order('creada_en', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
  // Identifica al conductor responsable del transporte asignado a los estudiantes del representante
  Future<String?> obtenerIdConductorAsignado() async {
     final resEstudiante = await _cliente
        .from('estudiantes')
        .select('conductor_id')
        .eq('representante_id', _userId)
        .eq('activo', true)
        .limit(1)
        .maybeSingle();

    if (resEstudiante == null) {
      print('Representante no tiene estudiantes asignados.');
      return null;
    }
    return resEstudiante['conductor_id'];
  }
  // Establece una conexión en tiempo real para rastrear la posición del vehículo en el mapa
  Stream<Map<String, dynamic>?> escucharUbicacionBus(String conductorId) {
    return _cliente
        .from('conductores')
        .stream(primaryKey: ['conductor_id'])
        .eq('conductor_id', conductorId)
        .map((lista) {
          return (lista.isNotEmpty ? lista.first : null);
        });
  }
  // Obtiene la información de contacto y detalles del vehículo del conductor asignado
  Future<Map<String, dynamic>?> obtenerDatosConductor(String conductorId) async {
     try {
      final res = await _cliente
          .from('conductores')
          .select('*, perfil:perfiles(*), ruta:rutas(*)')
          .eq('conductor_id', conductorId)
          .single();
      return res;
    } catch (e) {
      print("Error obteniendo datos del conductor: $e");
      return null;
    }
  }
  // Consolida la información personal y de contacto del representante
  Future<Map<String, dynamic>?> getMiPerfil() async {
    try {
      // Usamos maybeSingle para evitar error si no existe el perfil
      final response = await _cliente
          .from('perfiles')
          .select('*, representante:representantes!inner(*)') // Usamos inner join para asegurar que exista en ambas
          .eq('id', _userId)
          .maybeSingle(); // Cambiado de single a maybeSingle

      if (response == null) {
        print('Perfil no encontrado para el usuario $_userId o falta entrada en tabla representantes.');
        return null; // Devuelve null si no se encuentra
      }
      // Combinamos la info de 'perfiles' y 'representantes' en un solo mapa
      final perfilData = response;
      // El inner join ya nos trae los datos de representante dentro de 'representante'
      if (perfilData['representante'] != null && perfilData['representante'] is Map) {
         // Copiamos los campos de representante al nivel superior del mapa
         perfilData.addAll(Map<String, dynamic>.from(perfilData['representante']));
      }
      // Removemos la clave 'representante' anidada que ya no necesitamos
      perfilData.remove('representante');

      // Asegurar de que las claves esperadas existan, aunque sean null
       perfilData.putIfAbsent('nombre_completo', () => null);
       perfilData.putIfAbsent('correo', () => null);
       perfilData.putIfAbsent('telefono', () => null);
       perfilData.putIfAbsent('parentesco', () => null);
       perfilData.putIfAbsent('documento_identidad', () => null);
       perfilData.putIfAbsent('direccion', () => null);
       perfilData.putIfAbsent('foto_url', () => null);

      return perfilData;
    } catch (e) {
      print('Error CRÍTICO cargando perfil de representante: $e');
      return null;
    }
  }
  // Sube la fotografía seleccionada al almacenamiento
  Future<String> uploadProfilePhoto(Uint8List fileBytes, String fileExtension, String mimeType) async {
    final fileName = '${_userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final filePath = 'perfiles/$fileName';

    try {
      await _cliente.storage
          .from('driver_photos')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      // Obtenemos la URL pública después de subir
      final publicUrlResponse = _cliente.storage
          .from('driver_photos')
          .getPublicUrl(filePath);

      print("Foto subida: ${publicUrlResponse}");
      return publicUrlResponse;

    } on StorageException catch (e) {
      print("Error de Supabase Storage al subir foto: ${e.message}");
      throw Exception("Error al subir la foto: ${e.message}");
    } catch (e) {
      print("Error inesperado al subir foto: $e");
      throw Exception("Error inesperado al subir la foto.");
    }
  }

  // Actualiza la referencia de la imagen en el perfil del usuario
  Future<void> updateProfilePhotoUrl(String newUrl) async {
     try {
       await _cliente
            .from('perfiles')
            .update({'foto_url': newUrl})
            .eq('id', _userId);
        print("URL de foto actualizada en perfiles.");
     } catch (e) {
        print("Error actualizando foto_url en perfiles: $e");
        throw Exception("No se pudo actualizar la URL de la foto.");
     }
  }
  // Actualiza el perfil del representante.
  Future<void> actualizarMiPerfil(Map<String, dynamic> datosPerfil,
      Map<String, dynamic> datosRepresentante) async {
    await _cliente.from('perfiles').update(datosPerfil).eq('id', _userId);
    await _cliente
        .from('representantes')
        .update(datosRepresentante)
        .eq('representante_id', _userId);
  }
  Future<void> eliminarMiPerfil() async {
    try {
      final response = await _cliente.functions.invoke('borrar_representante');
      if (response.status! >= 400) {
        throw Exception('Error en Edge Function: ${response.data}');
      }

      print(' Respuesta de Edge Function (Eliminar Perfil): ${response.data}');
    } catch (e) {
      print(' Error al invocar Edge Function: $e');
      rethrow;
    }
  }
  // Borra una alerta específica del historial del usuario
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _cliente
          .from('notificaciones')
          .delete()
          .eq('notificacion_id', notificacionId);
    } catch (e) {
      print("Error al eliminar notificación: $e");
      throw Exception("No se pudo eliminar la alerta.");
    }
  }
  // Limpia completamente el buzón de notificaciones del representante
  Future<void> eliminarTodasMisNotificaciones() async {
    try {
      await _cliente
          .from('notificaciones')
          .delete()
          .eq('destinatario_id', _userId);
    } catch (e) {
      print("Error al eliminar todas las notificaciones: $e");
      throw Exception("No se pudieron eliminar las alertas.");
    }
  }
}
