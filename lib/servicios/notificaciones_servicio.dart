// Archivo - lib/servicio/notificaciones_servicio.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa; 
import 'package:tesis_appmovilfaj/providers/representante_provider.dart'; 
import 'supabase_servicio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// Inyección de dependencias
// Provider para instanciar y acceder al servicios de las notificaciones
final notificacionesServicioProvider = Provider<NotificacionesServicio>((ref) {
  return NotificacionesServicio();
});
// Combina la lógica de Firebase Cloud Messaging (FCM) para la identificación del dispositivo
class NotificacionesServicio {
  final FlutterLocalNotificationsPlugin _notificaciones =
      FlutterLocalNotificationsPlugin();
  supa.SupabaseClient get _cliente => SupabaseServicio.cliente();
  supa.RealtimeChannel? _canalNotificaciones;
  // Configuracion y registro del token
  static Future<void> inicializarYGuardarToken() async {
    try {
      // Solicitud de permisos al sistema operativo.
      await FirebaseMessaging.instance.requestPermission();
      // Obtención del token actualizado desde Firebase.
      await FirebaseMessaging.instance.deleteToken();
      String? token = await FirebaseMessaging.instance.getToken();
      print("TOKEN Nuevo del celular:");
      print(token);

      if (token == null) {
        if (kDebugMode) {
          print("Error: No se pudo obtener el token FCM.");
        }
        return;
      }

      if (kDebugMode) {
        print("--- Mi token FM ---");
        print(token);
        print("--------------------");
      }
      // Guarda el token en la base de datos.
      await _guardarTokenEnSupabase(token);

    } catch (e) {
      if (kDebugMode) {
        print("Error al inicializar notificaciones: $e");
      }
    }
  }

  // Función para guardar en la base de datos
  static Future<void> _guardarTokenEnSupabase(String token) async {
    final supabase = SupabaseServicio.cliente();
    final usuario = supabase.auth.currentUser;

    if (usuario == null) {
      if (kDebugMode) {
        print("Error: No hay usuario logueado. No se puede guardar token.");
      }
      return;
    }

    try {
      // Actualiza la tabla 'perfiles' en la columna 'token_push' donde el 'id' coincida con el del usuario logueado.
      await supabase
          .from('perfiles')
          .update({'token_push': token}) 
          .eq('id', usuario.id);

      if (kDebugMode) {
        print("Token FCM guardado en Supabase para el usuario: ${usuario.id}");
      }

    } catch (e) {
      if (kDebugMode) {
        print("Error al guardar token en Supabase: $e");
      }
    }
  }

  // Eliminación el token al cerrar sesión
  static Future<void> borrarTokenAlCerrarSesion() async {
     final supabase = SupabaseServicio.cliente();
     final usuario = supabase.auth.currentUser;

     if (usuario != null) {
        try {
           await supabase
            .from('perfiles')
            .update({'token_push': null}) 
            .eq('id', usuario.id);
          if (kDebugMode) {
             print("Token FCM borrado de Supabase al cerrar sesión.");
          }
        } catch (e) {
          // Manejo de error
        }
     }
  }
  // Inicialización de las notificaciones locales
  Future<void> inicializar() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_notification');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _notificaciones.initialize(initSettings);
    print(" Servicio de Notificaciones Locales Inicializado.");
  }

  // Construye y muestra una notificación en la barra de estado del sistema
  Future<void> mostrarNotificacion(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'canal_principal',
      'Notificaciones Generales',
      channelDescription: 'Canal usado para notificaciones básicas',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails detalles = NotificationDetails(
      android: androidDetails,
    );

    await _notificaciones.show(0, titulo, cuerpo, detalles);
  }

  // Registra notificación en Supabase en la tabla de 'notificaciones' 
  Future<void> registrarNotificacion({
    required String destinatarioId,
    required String titulo,
    required String mensaje,
    String? emisorId,
    String? tipo,
    Map<String, dynamic>? payload,
  }) async {
    await _cliente.from('notificaciones').insert({
      'destinatario_id': destinatarioId,
      'emisor_id': emisorId,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'payload_json': payload,
      'creada_en': DateTime.now().toIso8601String(),
    });
  }

  // Sincronización de las notificaciones en tiempo real
  void iniciarEscuchaNotificaciones(WidgetRef ref) {
    final userId = _cliente.auth.currentUser?.id;
    if (userId == null) return;
    print(" Iniciando escucha de notificaciones para el usuario: $userId");
    if (_canalNotificaciones != null) {
      detenerEscuchaNotificaciones();
    }

    _canalNotificaciones = _cliente
        .channel('public:notificaciones:destinatario_id=eq.$userId')
        .on(
      supa.RealtimeListenTypes.postgresChanges,
      supa.ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notificaciones',
        filter: 'destinatario_id=eq.$userId',
      ),
      (payload, [refPayload]) async {
        print(" ¡Nueva notificación recibida! Payload: ${payload.newRecord}");

        final nuevaNotificacion = payload.newRecord;
        if (nuevaNotificacion != null) {
          final titulo = nuevaNotificacion['titulo'] ?? 'Nueva Alerta';
          final mensaje = nuevaNotificacion['mensaje'] ??
              'Has recibido una nueva notificación.';

          // Mostrar la notificación de manera local
          await mostrarNotificacion(titulo, mensaje);

          // Actualización reactiva del estado de la UI (Providers)
          ref.refresh(notificacionesProvider);
          ref.invalidate(nuevasAlertasProvider);
        }
      },
    );
    // Gestion de estados de conexión
    _canalNotificaciones!.subscribe((status, [error]) {
      if (status == 'Suscrito para recebir ') {
        print(" Suscrito al canal de notificaciones.");
      } else if (status == 'CHANNEL_ERROR') {
        print(" Error en canal de notificaciones: $error");
      } else if (status == 'CLOSED') {
        print(" Canal cerrado.");
      }
    });
  }
  // Cierra el canal de escucha en tiempo real para liberar recursos cuando el servicio no es necesario
  void detenerEscuchaNotificaciones() {
    if (_canalNotificaciones != null) {
      print(" Deteniendo escucha de notificaciones.");
      _cliente.removeChannel(_canalNotificaciones!);
      _canalNotificaciones = null;
    }
  }
}
