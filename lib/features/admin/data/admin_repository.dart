// Archivo - lib/features/conductor/data/admin_repository.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../servicios/supabase_servicio.dart';
import 'dart:math';
import 'dart:core';
// Centraliza la lógica de acceso a datos y operaciones administrativas del sistema de transporte
class AdminRepository {
  late final SupabaseClient _cliente;
  AdminRepository() {
    // 🔹 Obtiene el cliente con sesión activa
    _cliente = Supabase.instance.client;
    if (_cliente.auth.currentSession == null) {
      debugPrint(' No hay sesión activa: las llamadas podrían fallar.');
    } else {
      debugPrint(' Sesión activa detectada para: ${_cliente.auth.currentUser?.email}');
    }
  }
  // Genera credenciales temporales seguras para el registro inicial de usuarios
  String _generarClaveAleatoria(int length) {
    // Caracteres más legibles (evitando 0, O, o, l, 1)
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }
  // Gestion de las actividades de los conductores
  // Verifica cuántos estudiantes activos tiene un conductor.
  Future<int> getEstudiantesCountForConductor(String conductorId) async {
    try {
      final res = await _cliente
          .from('estudiantes')
          .select('estudiante_id')
          .eq('conductor_id', conductorId)
          .eq('activo', true);

      if (res is List) {
        return res.length;
      }
      // Si la respuesta no es una lista, devolvemos 0 como fallback
      return 0;
    } catch (e) {
      debugPrint('Error contando estudiantes: $e');
      return 0; 
    }
  }
  /// Llama a la Edge Function de Supabase que transfiere estudiantes/rutas y desactiva al conductor original.
  Future<void> reemplazarYDesactivarConductor({
    required String conductorOriginalId,
    required String conductorReemplazoId,
  }) async {
    try {
      final response = await _cliente.functions.invoke('reemplazar-conductor',
        body: {
          'conductorOriginalId': conductorOriginalId,
          'conductorReemplazoId': conductorReemplazoId,
        },
      );

      if (response.status != 200) {
        throw Exception('Error en la Edge Function: ${response.data}');
      }

      debugPrint(' Reemplazo completado en el backend.');

    } catch (e) {
      throw Exception('Error al ejecutar reemplazo: $e');
    }
  }

  // Registra un conductor usando la Edge Function para enviar el correo conjuntamente
  Future<String?> registrarConductor({
    required String correo,
    required String nombreCompleto,
    required String telefono,
    String? rutaId,
    required String placa,
    required String marca,
    required String modelo,
    required String color,
    required String licencia,
    required String cedula,
    required String direccion,
    XFile? fotoFile,
  }) async {
    try {
      String? fotoBase64;

      if (fotoFile != null) {
        Uint8List bytes;

        if (kIsWeb) {
          bytes = await fotoFile.readAsBytes();
        } else {
          bytes = await File(fotoFile.path).readAsBytes();
        }

        fotoBase64 = base64Encode(bytes);
      }

      final session = Supabase.instance.client.auth.currentSession;
      final accessToken = session?.accessToken;
      if (accessToken == null) {
        throw Exception('No se pudo obtener el accessToken del usuario actual.');
      }
      // Generación de la clave aleatoria
      final String claveTemporal = _generarClaveAleatoria(10);

      final response = await http.post(
        Uri.parse(
          'https://helpdjfhqnnszqgjcyuu.functions.supabase.co/bright-service',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "email": correo,
          "password": claveTemporal,
          "fullName": nombreCompleto,
          "cedula": cedula,
          "licencia": licencia,
          "plate": placa,
          "rutaId": rutaId,
          "phoneNumber": telefono,
          "marca": marca,
          "modelo": modelo,
          "color": color,
          "direccion": direccion,
          "fotoBase64": fotoBase64,
          "appUrl": "https://tu-app.com/login"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['userId'] as String?;
      } else {
        throw Exception("Error en Edge Function: ${response.body}");
      }
    } catch (e) {
      throw Exception('Error al registrar conductor: $e');
    }
  }

  // Lista de todos los conductores con campos explícitos como nombre desde perfiles, foto desde conductores o perfiles, entre otros
  Future<List<Map<String, dynamic>>> buscarConductores({
    String? rutaId, // ID de Ruta o null o 'Reserva'
    String? searchTerm,
  }) async {
    var query = _cliente.from('conductores').select('''
      conductor_id,
      placa_vehiculo,
      marca_vehiculo,
      modelo_vehiculo,
      color_vehiculo,
      foto_vehiculo_url,
      licencia_conducir,
      permiso_activo,
      creado_en,
      actualizado_en,
      numero_ruta_asignada,
      perfiles (
        id,
        nombre_completo,
        correo,
        telefono,
        direccion,
        rol_id,
        foto_url,
        documento_identidad
      ),
      rutas (
        ruta_id,
        numero_ruta
      )
    ''')
    .eq('permiso_activo', true);

    // Solo aplicar filtro si la rutaId es válida 
    if (rutaId != null && rutaId.isNotEmpty && rutaId != 'RESERVA') {
      query = query.eq('numero_ruta_asignada', rutaId);
    }

    // Filtro por búsqueda nombre o placa
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.or(
          'placa_vehiculo.ilike.%$searchTerm%,perfiles.nombre_completo.ilike.%$searchTerm%');
    }

    final res = await query.order('creado_en', ascending: false);

    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('buscarConductores: respuesta inesperada del SDK: $res');
    }
  }

  // Actualiza al conductor en las tablas de perfil y conductor
  Future<void> actualizarConductor({
    required String conductorId,
    String? nombreCompleto,
    String? telefono,
    String? correo,
    String? direccion,
    String? placaVehiculo,
    String? marcaVehiculo,
    String? modeloVehiculo,
    String? colorVehiculo,
    String? licenciaConducir,
    String? rutaId, 
    XFile? fotoFile,
  }) async {
    try {
      String? fotoPublicUrl;
      // Subida de Foto 
      if (fotoFile != null) {
        final bytes = kIsWeb
            ? await fotoFile.readAsBytes()
            : await File(fotoFile.path).readAsBytes();
        final filePath = 'perfiles/$conductorId-${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _cliente.storage.from('driver_photos').uploadBinary(filePath, bytes);
        fotoPublicUrl = _cliente.storage.from('driver_photos').getPublicUrl(filePath);
      }
      // Actualizar Perfil 
      final updatePerfil = <String, dynamic>{
        'actualizado_en': DateTime.now().toIso8601String(),
        if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
        if (fotoPublicUrl != null) 'foto_url': fotoPublicUrl,
      };
      if (updatePerfil.length > 1) {
        await _cliente.from('perfiles').update(updatePerfil).eq('id', conductorId);
      }

      // Preparación de la actualización del conductor
      final updateConductor = <String, dynamic>{
        'actualizado_en': DateTime.now().toIso8601String(),
        if (placaVehiculo != null) 'placa_vehiculo': placaVehiculo,
        if (marcaVehiculo != null) 'marca_vehiculo': marcaVehiculo,
        if (modeloVehiculo != null) 'modelo_vehiculo': modeloVehiculo,
        if (colorVehiculo != null) 'color_vehiculo': colorVehiculo,
        if (licenciaConducir != null) 'licencia_conducir': licenciaConducir,
      };

      // Lógica de Ruta y de los estudiantes
      String? nuevaRutaId;
      bool huboCambioDeRuta = false;

      if (rutaId == 'SIN_RUTA') {
        updateConductor['numero_ruta_asignada'] = null;
        nuevaRutaId = null;
        huboCambioDeRuta = true;
      } else if (rutaId != null) {
        updateConductor['numero_ruta_asignada'] = rutaId;
        nuevaRutaId = rutaId;
        huboCambioDeRuta = true;
      }
      await _cliente
          .from('conductores')
          .update(updateConductor)
          .eq('conductor_id', conductorId);
      // Cambio de la ruta se actualiza igualmente los estudiantes
      // Esto respeta el alcance, el admin no gestiona estudiantes, el sistema lo hace por debajo
      if (huboCambioDeRuta) {
        await _cliente
            .from('estudiantes')
            .update({'ruta_id': nuevaRutaId}) 
            .eq('conductor_id', conductorId); 
            
        debugPrint(" Estudiantes sincronizados con la nueva ruta del conductor");
      }

    } catch (e) {
      throw Exception('Error actualizando conductor: $e');
    }
  }
  // Funcion para eliminar un conductor 
  Future<void> desactivarConductor({required String conductorId}) async {
    try {
      // En lugar de .delete(), hacemos un .update()
      await _cliente
          .from('conductores')
          .update({'permiso_activo': false})
          .eq('conductor_id', conductorId);
    } catch (e) {
      throw Exception('Error al desactivar conductor: $e');
    }
  }
  // Asignar una ruta a un conductor
  Future<void> asignarRutaAConductor({
    required String conductorId,
    required String rutaId,
  }) async {
    try {
      // Si la ruta esta vacía o sin ruta, se puede asignar null
      if (rutaId.isEmpty || rutaId == 'NULL') {
        await _cliente
            .from('conductores')
            .update({
              'numero_ruta_asignada': null,
              'actualizado_en': DateTime.now().toIso8601String(),
            })
            .eq('conductor_id', conductorId);
        return;
      }

      // Si es un UUID válido se actualiza
      await _cliente
          .from('conductores')
          .update({
            'numero_ruta_asignada': rutaId,
            'actualizado_en': DateTime.now().toIso8601String(),
          })
          .eq('conductor_id', conductorId);
    } catch (e) {
      throw Exception('Error asignando ruta: $e');
    }
  }

  // Listar las rutas 
  Future<List<Map<String, dynamic>>> listarRutas() async {
    final res = await _cliente.from('rutas').select('ruta_id, numero_ruta, sector, descripcion, activo');

    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('listarRutas: respuesta inesperada del SDK: $res');
    }
  }

  // Creación de una nueva ruta
  Future<String> crearRuta({
    required String numeroRuta,
    String? sector,
    String? descripcion,
  }) async {
    final data = {
      'numero_ruta': numeroRuta,
      'sector': sector,
      'descripcion': descripcion,
      'activo': true,
      'creado_en': DateTime.now().toIso8601String(),
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    final resp = await _cliente.from('rutas').insert(data).select().single();
    if (resp == null) throw Exception('Error creando ruta');
    final mapa = Map<String, dynamic>.from(resp as Map);
    return mapa['ruta_id'] as String;
  }

  // Actualización de un ruta existente
  Future<void> actualizarRuta({
    required String rutaId,
    required String numeroRuta,
    String? sector,
    String? descripcion,
    bool? activo,
  }) async {
    final update = {
      'numero_ruta': numeroRuta,
      'sector': sector,
      'descripcion': descripcion,
      'activo': activo ?? true,
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    try {
      await _cliente.from('rutas').update(update).eq('ruta_id', rutaId);
    } catch (e) {
      throw e;
    }
  }

  // Eliminación de un ruta 
  Future<void> eliminarRuta({required String rutaId}) async {
    try {
      await _cliente.from('rutas').delete().eq('ruta_id', rutaId);
    } catch (e) {
      throw e;
    }
  }

  // Función para registrar reemplazo
  Future<void> registrarReemplazo({
    required String conductorOriginalId,
    required String conductorReemplazoId,
  }) async {
    try {
      // Se obtiene la ruta del conductor original
      final original = await _cliente
          .from('conductores')
          .select('numero_ruta_asignada')
          .eq('conductor_id', conductorOriginalId)
          .single();

      final rutaId = original['numero_ruta_asignada'] as String?;
      if (rutaId == null) {
        throw Exception('El conductor original no tiene una ruta asignada.');
      }
      // Funcion RPC para coincidir con amba funciones
      await _cliente.rpc('reemplazar_conductor', params: {
        'ruta_a_transferir': rutaId,
        'conductor_original_id': conductorOriginalId,
        'conductor_reemplazo_id': conductorReemplazoId,
      });
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Error de base de datos: ${e.message}');
      }
      throw Exception('Error al registrar reemplazo: $e');
    }
  }
  // Identifica al personal habilitado que no posee asignación de ruta activa actualmente
  Future<List<Map<String, dynamic>>> getConductoresEnReserva() async {
    try {
      final res = await _cliente
          .from('conductores')
          .select('''
            conductor_id,
            placa_vehiculo,
            marca_vehiculo,
            modelo_vehiculo,
            color_vehiculo,
            foto_vehiculo_url,
            licencia_conducir,
            permiso_activo,
            creado_en,
            actualizado_en,
            numero_ruta_asignada,
            perfiles (
              id,
              nombre_completo,
              correo,
              telefono,
              direccion,
              rol_id,
              foto_url,
              documento_identidad
            ),
            rutas (
              ruta_id,
              numero_ruta
            )
          ''')
          .eq('permiso_activo', true)
          .is_('numero_ruta_asignada', null);

      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (res is PostgrestResponse) {
        if (res.data is List) {
          return (res.data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          throw Exception('Respuesta inesperada del servidor: ${res.data}');
        }
      } else {
        throw Exception('Tipo de respuesta desconocido: ${res.runtimeType}');
      }
    } catch (e) {
      throw Exception('Error al obtener conductores en reserva: $e');
    }
  }
  // Funcion de obtiener el número total de rutas activas.
  Future<int> getNumeroRutas() async {
    try {
      final res = await _cliente
          .from('rutas')
          .select('ruta_id')
          .eq('activo', true);

      if (res is List) {
        return res.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error contando rutas: $e');
      return 0;
    }
  }

  // Obtiene el número total de conductores activos.
  Future<int> getNumeroConductoresActivos() async {
    try {
      final res = await _cliente
          .from('conductores')
          .select('conductor_id')
          .eq('permiso_activo', true);
          
      if (res is List) {
        return res.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error contando conductores activos: $e');
      return 0;
    }
  }

  // Obtiene el número total de conductores en reserva activos pero sin ruta asignada
  Future<int> getNumeroConductoresReserva() async {
    try {
      final res = await _cliente
          .from('conductores')
          .select('conductor_id')
          .eq('permiso_activo', true)
          .is_('numero_ruta_asignada', null); 
      if (res is List) {
        return res.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error contando conductores en reserva: $e');
      return 0;
    }
  }

  // Obtiene el número total de estudiantes activos.
  Future<int> getNumeroTotalEstudiantes() async {
    try {
      final res = await _cliente
          .from('estudiantes')
          .select('estudiante_id')
          .eq('activo', true);
          
      if (res is List) {
        return res.length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error contando estudiantes: $e');
      return 0;
    }
  }
  // Obtiene el número total de representantes activos
  Future<int> getNumeroTotalRepresentantes() async {
      try {
        final res = await _cliente
            .from('representantes')
            .select('representante_id')
            .eq('activo', true);
            
        if (res is List) {
          return res.length;
        }
        return 0;
      } catch (e) {
        debugPrint('Error contando representantes: $e');
        return 0;
      }
    }
    Future<List<Map<String, dynamic>>> listarRutasDisponiblesParaConductor(String conductorIdActual) async {
    try {
      // Se obtiene todas las rutas activas
      final resRutas = await _cliente
          .from('rutas')
          .select('ruta_id, numero_ruta, sector, descripcion')
          .eq('activo', true);
      
      final todasLasRutas = (resRutas as List).map((e) => Map<String, dynamic>.from(e)).toList();

      // Las rutas que ya están ocupadas por otros conductores
      final resOcupadas = await _cliente
          .from('conductores')
          .select('numero_ruta_asignada')
          .neq('conductor_id', conductorIdActual) 
          .not('numero_ruta_asignada', 'is', null); 

      // Lista de IDs prohibidos para las rutas
      final idsOcupados = (resOcupadas as List)
          .map((e) => e['numero_ruta_asignada'] as String)
          .toSet();

      // Filtramos y dejamos solo las que no están en la lista de ocupados
      final rutasDisponibles = todasLasRutas.where((ruta) {
        return !idsOcupados.contains(ruta['ruta_id']);
      }).toList();

      return rutasDisponibles;
    } catch (e) {
      throw Exception('Error filtrando rutas: $e');
    }
  }
  // Verifica si una ruta está siendo usada antes de eliminarla.
  Future<Map<String, int>> verificarUsoDeRuta(String rutaId) async {
    try {
      // Constar conductores asignados a esta ruta
      final resConductores = await _cliente
          .from('conductores')
          .select('conductor_id')
          .eq('numero_ruta_asignada', rutaId);
      
      // Constar estudiantes asignados a esta ruta
      final resEstudiantes = await _cliente
          .from('estudiantes')
          .select('estudiante_id')
          .eq('ruta_id', rutaId);

      int numConductores = (resConductores as List).length;
      int numEstudiantes = (resEstudiantes as List).length;

      return {
        'conductores': numConductores,
        'estudiantes': numEstudiantes,
      };
    } catch (e) {
      throw Exception('Error verificando dependencias de la ruta: $e');
    }
  }
  // Registrar las rutas establecidas 
  Future<List<Map<String, dynamic>>> listarRutasTotalmenteLibres() async {
    try {
      // Trae todas las rutas activas
      final resRutas = await _cliente
          .from('rutas')
          .select('ruta_id, numero_ruta, sector, descripcion')
          .eq('activo', true);
      
      final todasLasRutas = (resRutas as List).map((e) => Map<String, dynamic>.from(e)).toList();

      // Trae todas las rutas que ya están ocupadas
      final resOcupadas = await _cliente
          .from('conductores')
          .select('numero_ruta_asignada')
          .not('numero_ruta_asignada', 'is', null);

      final idsOcupados = (resOcupadas as List)
          .map((e) => e['numero_ruta_asignada'] as String)
          .toSet();

      // Rutas que no estan ocupadas
      final rutasLibres = todasLasRutas.where((ruta) {
        return !idsOcupados.contains(ruta['ruta_id']);
      }).toList();

      return rutasLibres;
    } catch (e) {
      throw Exception('Error buscando rutas libres: $e');
    }
  }
  // Verificación si el usuario actual 'Admin' ya existe en la tabla de conductores
  Future<bool> verificarSiEsConductor(String uid) async {
    try {
      final response = await _cliente
          .from('conductores')
          .select('conductor_id')
          .eq('conductor_id', uid)
          .eq('permiso_activo', true)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
  // Perfil de conductor para insertar en tabla conductores
  Future<void> activarModoConductor({
    required String userId,
    required String licencia,
    required String placa,
    required String marca,
    required String modelo,
    required String color,
  }) async {
    try {
      await _cliente.from('conductores').insert({
        'conductor_id': userId,
        'licencia_conducir': licencia,
        'placa_vehiculo': placa,
        'marca_vehiculo': marca,
        'modelo_vehiculo': modelo,
        'color_vehiculo': color,
        'permiso_activo': true,
        'numero_ruta_asignada': null, // Empieza sin ruta
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al activar modo conductor: $e');
    }
  }
}












