// Archivo - lib/features/conductor/data/conductor_repository.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
// Centraliza la gestión de datos operativos, logística de rutas y comunicación para el módulo del conductor
class ConductorRepository {
  final _cliente = Supabase.instance.client;

  String get _userId => _cliente.auth.currentUser!.id;
  // Recupera el estado actual de la transmisión de ubicación y la ruta asignada al conductor
  Future<Map<String, dynamic>?> getConductorStatus() async {
    try {
      final res = await _cliente
          .from('conductores')
          .select('compartiendo_ubicacion, rutas(numero_ruta, descripcion)')
          .eq('conductor_id', _userId)
          .maybeSingle();
      return res;
    } catch (e) {
      throw Exception('Error al obtener el estado del conductor: $e');
    }
  }
  // Actualiza la visibilidad del vehículo en el mapa para que los representantes puedan verlo
  Future<void> setSharingLocation(bool isSharing) async {
    await _cliente
        .from('conductores')
        .update({
          'compartiendo_ubicacion': isSharing,
          'actualizado_en': DateTime.now().toIso8601String(),
        })
        .eq('conductor_id', _userId);
  }
  // Guarda un registro histórico de la posición y velocidad del autobús
  Future<void> registrarUbicacion(
    double lat,
    double lng, {
    double? velocidad,
  }) async {
    await _cliente.from('historial_ubicacion_autobus').insert({
      'conductor_id': _userId,
      'latitud': lat,
      'longitud': lng,
      'velocidad_kmh': velocidad,
    });
  }
  // Obtiene la lista detallada de estudiantes asignados a la ruta, incluyendo datos de sus tutores
  Future<List<Map<String, dynamic>>> obtenerEstudiantes() async {
    try {
      final res = await _cliente
          .from('estudiantes')
          .select('''
            *,
            representante:representantes(
              representante_id,
              perfil:perfiles(id, nombre_completo, correo, telefono)
            )
          ''')
          .eq('conductor_id', _userId)
          .eq('activo', true)
          .order('nombre_completo', ascending: true);

      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        throw Exception('Formato inesperado de respuesta: ${res.runtimeType}');
      }
    } catch (e) {
      throw Exception('Error al obtener la lista de estudiantes: $e');
    }
  }
  // Consulta los registros de asistencia correspondientes a la jornada actual
  Future<List<Map<String, dynamic>>> obtenerAsistenciaHoy() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await _cliente
        .from('asistencia')
        .select('estudiante_id, asistencia_manana, asistencia_tarde')
        .eq('conductor_id', _userId)
        .eq('fecha', today);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Obtiene los registros de asistencia para una fecha específica.
  Future<List<Map<String, dynamic>>> obtenerAsistenciaPorFecha(DateTime fecha) async {
    // Formatea la fecha a 'YYYY-MM-DD' para la consulta SQL
    final fechaFormateada = fecha.toIso8601String().substring(0, 10);
    final res = await _cliente
        .from('asistencia')
        .select('estudiante_id, asistencia_manana, asistencia_tarde')
        .eq('conductor_id', _userId)
        .eq('fecha', fechaFormateada);
    return List<Map<String, dynamic>>.from(res);
  }
  // Registra o actualiza el estado de presencia del estudiante
  Future<void> registrarAsistencia({
    required String estudianteId,
    required DateTime fecha, 
    required bool esManana,
    required bool? asistio,
  }) async {
    final fechaFormateada = fecha.toIso8601String().substring(0, 10);
    final Map<String, dynamic> updateData = {};
    if (esManana) {
      updateData['asistencia_manana'] = asistio;
    } else {
      updateData['asistencia_tarde'] = asistio;
    }

    await _cliente.from('asistencia').upsert({
      'estudiante_id': estudianteId,
      'conductor_id': _userId,
      'fecha': fechaFormateada,
      ...updateData,
    }, onConflict: 'estudiante_id, fecha'); 
  }
  // Inscribe un nuevo estudiante en la ruta gestionada por el conductor actual
  Future<void> registrarEstudiante(Map<String, dynamic> datosEstudiante) async {
    datosEstudiante['conductor_id'] = _userId;
    if (datosEstudiante['representante_id'] == null) {
      print("Registrando estudiante sin representante (huérfano)");
    }
    await _cliente.from('estudiantes').insert(datosEstudiante);
  }
  // Modifica la información personal o logística de un estudiante existente
  Future<void> actualizarEstudiante(
    String estudianteId,
    Map<String, dynamic> datosEstudiante,
  ) async {
    await _cliente
        .from('estudiantes')
        .update(datosEstudiante)
        .eq('estudiante_id', estudianteId);
  }
  // Desactiva el registro del estudiante sin eliminarlo físicamente para preservar el historial
  Future<void> eliminarEstudiante(String estudianteId) async {
    await _cliente
        .from('estudiantes')
        .update({'activo': false}) 
        .eq('estudiante_id', estudianteId);
  }

  // Localiza representantes registrados mediante búsqueda por nombre o correo electrónico
  Future<List<Map<String, dynamic>>> buscarRepresentantes(String query) async {
    try {
      print(' Buscando representantes con query: "$query"');

      // Obténción del rol_id de representante 
      final rolResp = await _cliente
          .from('roles')
          .select('rol_id')
          .eq('nombre_rol', 'representante')
          .maybeSingle();

      if (rolResp == null || rolResp['rol_id'] == null) {
        print(' No se encontró el rol "representante"');
        return [];
      }

      final String rolId = rolResp['rol_id'].toString().trim();
      print(' Rol representante ID: $rolId');

      final filtro = query.trim();

      // Si no hay filtro, devuelve los primeros representantes
      if (filtro.isEmpty) {
        final res = await _cliente
            .from('perfiles')
            .select('id, nombre_completo, correo, telefono, foto_url, rol_id')
            .eq('rol_id', rolId)
            .order('nombre_completo', ascending: true)
            .limit(50);
        final lista = List<Map<String, dynamic>>.from(res);
        print(' Resultados (sin filtro): ${lista.length}');
        return lista;
      }

      // Si hay filtro, primero buscar por nombre 
      final resPorNombre = await _cliente
          .from('perfiles')
          .select('id, nombre_completo, correo, telefono, foto_url, rol_id')
          .eq('rol_id', rolId)
          .filter('nombre_completo', 'ilike', '%$filtro%')
          .order('nombre_completo', ascending: true)
          .limit(50);

      var listaNombre = List<Map<String, dynamic>>.from(resPorNombre);

      // Si se encontró por nombre, también intentamos buscar por correo y unimos 
      final resPorCorreo = await _cliente
          .from('perfiles')
          .select('id, nombre_completo, correo, telefono, foto_url, rol_id')
          .eq('rol_id', rolId)
          .filter('correo', 'ilike', '%$filtro%')
          .order('nombre_completo', ascending: true)
          .limit(50);

      var listaCorreo = List<Map<String, dynamic>>.from(resPorCorreo);

      // Unir listas sin duplicados 
      final Map<String, Map<String, dynamic>> mapa = {};
      for (final item in listaNombre) {
        mapa[item['id'].toString()] = Map<String, dynamic>.from(item);
      }
      for (final item in listaCorreo) {
        mapa[item['id'].toString()] = Map<String, dynamic>.from(item);
      }

      final resultados = mapa.values.toList();
      print(' Resultados finales encontrados: ${resultados.length}');
      for (final r in resultados) {
        print(' ${r['nombre_completo']} (${r['correo']}) rol:${r['rol_id']}');
      }

      return resultados;
    } catch (e, st) {
      print(' Error en buscarRepresentantes: $e');
      print(st);
      return [];
    }
  }
  // Localiza representantes registrados mediante búsqueda por nombre o correo electrónico
  Future<Map<String, dynamic>?> cargarConductoresPerfil() async {
    final userId = _cliente.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      // Hacemos una consulta que une la tabla 'perfiles' con 'conductores'
      final response = await _cliente
          .from('perfiles')
          .select(
            '*, conductores(*)',
          ) // Selecciona todo de perfiles y lo anidado de conductores
          .eq('id', userId)
          .single(); 

      // La respuesta viene con 'conductores' como un mapa anidado.
      // Lo aplanamos para que sea más fácil de usar en la UI.
      final perfilData = response;
      final conductorData = perfilData['conductores'];

      if (conductorData != null && conductorData is Map) {
        // Añadimos los datos del conductor al mapa principal
        perfilData.addAll(Map<String, dynamic>.from(conductorData));
      }
      // Removemos el mapa anidado para evitar redundancia
      perfilData.remove('conductores');

      return perfilData;
    } catch (e) {
      print('Error obteniendo perfil completo, devolviendo perfil básico: $e');
      final basicProfile = await _cliente
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();
      return basicProfile;
    }
  }

  // Almacena la fotografía del estudiante para facilitar su identificación
  Future<String> subirFotoEstudiante({
    required XFile foto,
    required String estudianteId,
  }) async {
    try {
      final storage = _cliente.storage.from('driver_photos');
      final extension = foto.name.split('.').last.toLowerCase();
      // Ruta consistente para sobrescribir
      final rutaArchivo = 'estudiantes/$estudianteId/foto_perfil.$extension';

      // Leemos los bytes, funciona en todas las plataformas
      final Uint8List bytes = await foto.readAsBytes();
      
      // Usamos uploadBinary, funciona en todas las plataformas
      await storage.uploadBinary(
        rutaArchivo,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true, // Sobrescribir si ya existe
          contentType: 'image/$extension'
        ),
      );

      return storage.getPublicUrl(rutaArchivo);
    } catch (e) {
      throw Exception('Error al subir la foto del estudiante: $e');
    }
  }

  // Establece una conexión en tiempo real para detectar cambios en la lista de pasajeros
  RealtimeChannel suscribirseACambiosDeEstudiantes(VoidCallback cuandoHayaCambios) {
    final canal = _cliente
        .channel('public:estudiantes:conductor_id=eq.$_userId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'estudiantes'),
          (payload, [ref]) {
            print('¡Cambio detectado en estudiantes!');
            cuandoHayaCambios();
          },
        );
        
    canal.subscribe();
    return canal;
  }
  // Actualiza la imagen de perfil del conductor en el almacenamiento seguro de la nube
  Future<String> subirFotoPerfilConductor({
    required Uint8List fotoBytes,
    required String mimeType,
    required String fileExtension,
    required String idUsuario,
  }) async {
    try {
      final storage = _cliente.storage.from('driver_photos');

      // Normalizar la extensión
      String ext = fileExtension.toLowerCase();
      if (ext == 'jpeg') ext = 'jpg';
      if (!['jpg', 'png', 'gif', 'webp'].contains(ext)) ext = 'png';

      // Ruta consistente dentro del bucket
      final rutaArchivo = 'perfiles/$idUsuario/foto_perfil.$ext';

      // Subida segura upsert = true permite reemplazar si ya existe
      await storage.uploadBinary(
        rutaArchivo,
        fotoBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
          contentType: mimeType,
        ),
      );

      // Devolvemos la URL pública para mostrarla en la app
      return storage.getPublicUrl(rutaArchivo);
    } catch (e) {
      throw Exception('Error al subir la foto de perfil: $e');
    }
  }
  // Recopila los identificadores únicos de los representantes asociados a la ruta actual
  Future<List<String>> _obtenerIdsRepresentantesDeMiRuta() async {
    try {
      final response = await _cliente
          .from('estudiantes')
          .select('representante_id')
          .eq('conductor_id', _userId)
          .eq('activo', true); // Solo estudiantes activos

      if (response.isEmpty) {
        return [];
      }
      // Usamos un Set para eliminar duplicados
      final Set<String> idsRepresentantes = {};
      for (var item in response) {
        if (item['representante_id'] != null) {
          idsRepresentantes.add(item['representante_id']);
        }
      }
      return idsRepresentantes.toList();
      
    } catch (e) {
      print('Error obteniendo IDs de representantes: $e');
      return []; // Devuelve lista vacía en caso de error
    }
  }

  // Emite una alerta masiva a los padres informando el inicio del recorrido escolar
  Future<void> enviarNotificacionInicioRecorrido(String conductorNombre) async {
    
    // Paso 1: Obtener los IDs de los representantes
    final idsRepresentantes = await _obtenerIdsRepresentantesDeMiRuta();
    
    if (idsRepresentantes.isEmpty) {
      print("No hay representantes activos en esta ruta para notificar.");
      return;
    }

    // Paso 2: Preparar los datos de la notificación
    final String titulo = "Recorrido Iniciado";
    final String mensaje = "El conductor $conductorNombre ha iniciado el recorrido. ¡Atento a las alertas!";
    final String tipo = "inicio_recorrido";

    // Paso 3: Crear una lista de notificaciones (una para cada representante)
    final List<Map<String, dynamic>> nuevasNotificaciones = idsRepresentantes.map((id) {
      return {
        'destinatario_id': id,
        'emisor_id': _userId,
        'tipo': tipo,
        'titulo': titulo,
        'mensaje': mensaje,
        'creada_en': DateTime.now().toIso8601String(),
      };
    }).toList();

    // Paso 4: Insertar todas las notificaciones en la base de datos
    try {
      await _cliente.from('notificaciones').insert(nuevasNotificaciones);
      print(" Notificaciones de 'Inicio de Recorrido' enviadas a ${nuevasNotificaciones.length} representantes.");
    } catch (e) {
      print("Error al insertar notificaciones de inicio: $e");
      // No lanzamos excepción para no detener la app del conductor
    }
  }
  // Marca la asistencia y notifica inmediatamente al representante sobre el evento
  Future<void> registrarAsistenciaYNotificar({
    required String estudianteId,
    required String representanteId,
    required String nombreEstudiante,
    required DateTime fecha,
    required bool esManana,
    required bool? asistio,
  }) async {
    if (representanteId.isEmpty) {
       print(" No se puede notificar: Estudiante sin representante.");
       // Solo registra la asistencia y termina.
       await _upsertAsistencia(
         estudianteId: estudianteId,
         fecha: fecha,
         updateData: {
           esManana ? 'asistencia_manana' : 'asistencia_tarde': asistio,
         },
       );
       return;
    }
    await _upsertAsistencia(
      estudianteId: estudianteId,
      fecha: fecha,
      updateData: {
        esManana ? 'asistencia_manana' : 'asistencia_tarde': asistio,
      },
    );

    final tipo = asistio == true
        ? 'asistencia_on'
        : asistio == false
            ? 'asistencia_off'
            : 'asistencia_reset';

    final mensaje = asistio == true
        ? 'Confirmado: $nombreEstudiante subió al bus.'
        : asistio == false
            ? 'Confirmado: $nombreEstudiante NO subió al bus hoy.'
            : 'La asistencia de $nombreEstudiante se marcó como pendiente.';

    await _cliente.from('notificaciones').insert({
      'destinatario_id': representanteId,
      'emisor_id': _userId,
      'tipo': tipo,
      'titulo': 'Asistencia: $nombreEstudiante',
      'mensaje': mensaje,
      'creada_en': DateTime.now().toIso8601String(),
    });
  }

  // Registra una novedad específica sobre el estudiante y la comunica al representante
  Future<void> registrarObservacionYNotificar({
    required String estudianteId,
    required String representanteId,
    required String nombreEstudiante,
    required DateTime fecha,
    required String observacion,
    required bool esManana,
  }) async {
    
    //Guardar la observación en la tabla de asistencia
      final updateData = {
      'notas': observacion,
    };
    await _upsertAsistencia(estudianteId: estudianteId, fecha: fecha, updateData: updateData);
    if (representanteId.isEmpty) {
       print(" No se puede notificar observación: Estudiante sin representante.");
       return;
    }
    // Enviar notificación al representante
    try {
      await _cliente.from('notificaciones').insert({
        'destinatario_id': representanteId,
        'emisor_id': _userId,
        'tipo': 'observacion',
        'titulo': "Observación para $nombreEstudiante",
        'mensaje': observacion, 
        'creada_en': DateTime.now().toIso8601String(),
      });
      print(" Notificación de observación enviada para $nombreEstudiante");
    } catch (e) {
      print("Error al enviar notificación de observación: $e");
    }
  }
  // Ejecuta la operación de Supabase para guardar la asistencia sin duplicados
  Future<void> _upsertAsistencia({
    required String estudianteId,
    required DateTime fecha,
    required Map<String, dynamic> updateData,
  }) async {
    final f = fecha.toIso8601String().substring(0, 10);
    await _cliente.from('asistencia').upsert({
      'estudiante_id': estudianteId,
      'conductor_id': _userId,
      'fecha': f,
      ...updateData,
    }, onConflict: 'estudiante_id, fecha');
  }
  // Consulta el historial de alertas y mensajes enviados previamente por el conductor
  Future<List<Map<String, dynamic>>> obtenerNotificacionesEnviadas() async {
    try {
      final res = await _cliente
          .from('notificaciones')
          .select('notificacion_id, tipo, titulo, mensaje, creada_en, destinatario_id')
          .eq('emisor_id', _userId)
          .order('creada_en', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error al obtener notificaciones enviadas: $e');
      return [];
    }
  }
  // Elimina un registro específico del historial de notificaciones enviadas
  Future<void> eliminarNotificacionEnviada(String notificacionId) async {
    try {
      await _cliente
          .from('notificaciones')
          .delete()
          .eq('notificacion_id', notificacionId)
          .eq('emisor_id', _userId);
      print(" Notificación eliminada: $notificacionId");
    } catch (e) {
      print("Error al eliminar notificación enviada: $e");
      throw Exception("No se pudo eliminar la notificación.");
    }
  }

  // Limpia completamente el registro de alertas generadas por el usuario
  Future<void> eliminarTodasNotificacionesEnviadas() async {
    try {
      await _cliente
          .from('notificaciones')
          .delete()
          .eq('emisor_id', _userId);
      print(" Todas las notificaciones enviadas fueron eliminadas.");
    } catch (e) {
      print(" Error al eliminar todas las notificaciones enviadas: $e");
      throw Exception("No se pudieron eliminar todas las notificaciones.");
    }
  }
  // Envía un aviso automático de proximidad cuando el transporte se acerca al domicilio
  Future<void> enviarAlertaDeCercania({
    required String estudianteId,
    required String representanteId,
    required String nombreEstudiante,
    required int distanciaMetros,
  }) async {
    if (representanteId.isEmpty) {
       print(" No se puede notificar cercanía: Estudiante sin representante.");
       return;
    }

    final String titulo = "¡Bus Cercano!";
    final String mensaje =
        "El bus está a menos de $distanciaMetros metros. Prepara a $nombreEstudiante.";
    final String tipo = "cercania";

    try {
      await _cliente.from('notificaciones').insert({
        'destinatario_id': representanteId,
        'emisor_id': _userId,
        'tipo': tipo,
        'titulo': titulo,
        'mensaje': mensaje,
        'creada_en': DateTime.now().toIso8601String(),
      });
      print("Notificación de CERCANÍA enviada para $nombreEstudiante");
    } catch (e) {
      print("Error al enviar notificación de cercanía: $e");
    }
  }
}