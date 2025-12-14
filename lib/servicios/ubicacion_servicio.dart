// Archivo - lib/servicio/ubicacion_servicio.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:tesis_appmovilfaj/servicios/supabase_servicio.dart';
import 'package:tesis_appmovilfaj/features/conductor/data/conductor_repository.dart';
// Este servicio administra la geolocalizacion del transporte
// Funcion principal es el desarrollo del rastreo continuo de las coordenadas de la trayectoria del conductor
class UbicacionServicio {
  StreamSubscription<Position>? _subscription;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  final LocationAccuracy _accuracy;
  final int _distanceFilterMeters;
  final ConductorRepository _conductorRepo = ConductorRepository();

  // Memoria temporal para evitar el envío de múltiples alertas al mismo estudiante en un solo recorrido
  final Set<String> _estudiantesNotificados = {};

  UbicacionServicio({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
  })  : _accuracy = accuracy,
        _distanceFilterMeters = distanceFilterMeters;
  // Canal de difusión que permite a otras partes de la app "escuchar" la posición actual
  Stream<Position> get positionStream => _positionController.stream;
  // Indica si el servicio de rastreo se encuentra activo actualmente
  bool get estaEscuchando => _subscription != null;
  // Gestion de autorizaciones
  // Interactúa con el sistema operativo para confirmar si la ubicación está activada
  Future<bool> verificarPermisos() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return false;
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return false;
    }
    if (permiso == LocationPermission.deniedForever) return false;
    return true;
  }

  // Obtención de datos
  // Define la precisión deseada y la frecuencia de actualización
  Stream<Position> escucharUbicacion() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _accuracy,
        distanceFilter: _distanceFilterMeters,
      ),
    );
  }

  // Actualizar la ubicación en Supabase 
  Future<void> actualizarUbicacionEnSupabase(
    String conductorId,
    Position pos, {
    double? velocidadKmh,
    String? direccionTexto,
  }) async {
    try {
      final supabase = SupabaseServicio.cliente();
      final velocidad = velocidadKmh ?? (pos.speed * 3.6);
      // Actualización en tiempo real - Mapa
      await supabase.from('conductores').update({
        'latitud_actual': pos.latitude,
        'longitud_actual': pos.longitude,
        'compartiendo_ubicacion': true,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('conductor_id', conductorId);
      // Registro histórico 
      await supabase.from('historial_ubicacion_autobus').insert({
        'conductor_id': conductorId,
        'latitud': pos.latitude,
        'longitud': pos.longitude,
        'velocidad_kmh': velocidad,
        'direccion_texto': direccionTexto,
        'registrado_en': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Ubicacion: error al actualizar en Supabase -> $e');
    }
  }

  // Detección de cercanía 
  Future<void> _verificarCercania(Position pos, List<Map<String, dynamic>> estudiantes) async {
    const double UMBRAL_METROS = 250.0;

    for (final est in estudiantes) {
      final double? latCasa = (est['latitud_casa'] as num?)?.toDouble();
      final double? lonCasa = (est['longitud_casa'] as num?)?.toDouble();
      final nombre = est['nombre_completo'] ?? 'Sin nombre';

      if (latCasa == null || lonCasa == null) {
        print(" $nombre no tiene coordenadas de casa, se omite.");
        continue;
      }
      // Cálculo matemático de la distancia geodésica
      final distancia = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        latCasa,
        lonCasa,
      );

      print(" Distancia a $nombre: ${distancia.toStringAsFixed(2)} m");
      // Lógica de disparo de alerta - Geofencing simple
      if (distancia <= UMBRAL_METROS) {
        final estudianteId = est['estudiante_id'].toString();
        // Verificación para no saturar al usuario con alertas repetidas
        if (_estudiantesNotificados.contains(estudianteId)) {
          print(" Ya se notificó previamente a $nombre. Se omite duplicado.");
          continue;
        }
        final representanteId = est['representante']?['representante_id'];
        if (representanteId == null) {
          print(" No se encontró representante para $nombre.");
          continue;
        }
        print(" Enviando alerta de cercanía para $nombre (distancia ${distancia.toStringAsFixed(1)} m)");
        // Envío de la notificación a través del repositorio
        await _conductorRepo.enviarAlertaDeCercania(
          estudianteId: estudianteId,
          representanteId: representanteId.toString(),
          nombreEstudiante: nombre,
          distanciaMetros: distancia.round(),
        );
         // Marca al estudiante como "notificado" en la sesión actual
        _estudiantesNotificados.add(estudianteId);
      }
    }
  }

  // Monitoreo principal activo
  Future<void> iniciarEscuchaConductor(
    String conductorId,
    List<Map<String, dynamic>> estudiantes,
  ) async {
    if (!await verificarPermisos()) return;
    await detenerEscucha();
    _estudiantesNotificados.clear();

    _subscription = escucharUbicacion().listen((pos) async {
      // Propaga la ubicación a la UI local.
      if (!_positionController.isClosed) _positionController.add(pos);
      // Sincroniza con la nube.
      await actualizarUbicacionEnSupabase(conductorId, pos);
      // Verifica geovallas.
      await _verificarCercania(pos, estudiantes);
    }, onError: (error) {
      print('Ubicacion: error en stream -> $error');
    });

    print('Ubicacion: escucha iniciada para conductor $conductorId con ${estudiantes.length} estudiantes.');
  }
  // Finaliza el rastreo y libera los recursos del dispositivo
  Future<void> detenerEscucha() async {
    await _subscription?.cancel();
    _subscription = null;
  }
  // Cierra definitivamente los canales de comunicación al destruir el servicio
  Future<void> dispose() async {
    await detenerEscucha();
    await _positionController.close();
  }
}


