// Archivo - lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tesis_appmovilfaj/firebase_options.dart';
import 'package:tesis_appmovilfaj/servicios/notificaciones_servicio.dart';
import 'servicios/supabase_servicio.dart';
import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Gestion de procesos en segundo plano
// Procesa las notificaciones entrantes cuando la aplicación está cerrada o minimizada
// Se ejecuta en un aislamiento de memoria separado, por lo que requiere su propia inicialización
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Verifica si ya existe una instancia de Firebase para evitar conflictos de "aplicación duplicada"
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    Firebase.app();
  }
  // Configuración del plugin de notificaciones locales para mostrar alertas visuales desde el background
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  // Si el mensaje contiene datos visuales, construye y muestra la notificación en la barra de estado
  final notification = message.notification;
  if (notification != null) {
    await flutterLocalNotificationsPlugin.show(
      // Genera un ID único basado en el tiempo
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_principal',
          'Notificaciones Generales',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }
}

// Punto de entrada principal 
// Función del arranque de la aplicación y la inyección de dependencias
Future<void> main() async {
  // Asegurar que el motor gráfico de Flutter esté listo antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Bloque de inicializacion de los servicios
    // 1. Establecer la conexión con la base de datos Supabase
    print("Main: Inicializando Supabase...");
    await SupabaseServicio.inicializar();
    print("Main: Supabase OK.");
    // 2. Inicializar los servicios de Google (Firebase) validando duplicidad de instancias
    print("MAIN: Inicializando Firebase...");
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
    print("Main: Firebase OK.");
    // Configurar un "oyente" que actualiza automáticamente el token de notificaciones en la base de datos si este cambia
    FirebaseMessaging.instance.onTokenRefresh.listen((nuevoToken) async {
      try {
        final supabase = SupabaseServicio.cliente();
        final usuario = supabase.auth.currentUser;
        // Solo se actualiza si hay una sesión activa para mantener la consistencia de datos
        if (usuario == null) {
          print(" Token refrescado pero no hay usuario logueado");
          return;
        }
        print(" TOKEN FCM REFRESCADO AUTOMÁTICAMENTE:");
        print(nuevoToken);
        // Sincronizar el nuevo identificador del dispositivo con el perfil del usuario
        await supabase
            .from('perfiles')
            .update({'token_push': nuevoToken})
            .eq('id', usuario.id);

        print(" Token FCM actualizado en Supabase correctamente");
      } catch (e) {
        print(" Error al actualizar token refrescado: $e");
      }
    });
    // Solicitar los permisos explícitos al usuario para enviar notificaciones (Requerido en Android 13+)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('Permiso de notificaciones: ${settings.authorizationStatus}');
    // 3. Registrar la función que manejará los mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print("Main: Background handler OK.");
    // 4. Configurar el sistema de notificaciones locales para mostrar alertas dentro de la app
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    print("Main: Notificaciones locales OK.");

    // Crea el canal de comunicación específico para Android (necesario para definir prioridad y sonidos)
    const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
      'canal_principal', 'Notificaciones Generales',
      description: 'Canal para alertas del transporte escolar',
      importance: Importance.max,
    );
    final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    print("Main: Canal Android OK.");

    // 5. Éxito, lanza la aplicación principal envuelta en el gestor de estado Riverpod
    print("Main: Inicialización completa. Lanzando app principal...");
    runApp(const ProviderScope(child: MyApp()));

  } catch (e) {
    // Gestion de errores
    print(" Error grave en el main ");
    print(e.toString());
    print("---------------------------");

    // Renderiza una interfaz de emergencia que muestra el error al usuario en lugar de cerrar la app
    runApp(ErrorApp(error: e.toString()));
  }
}

// Permite diagnosticar problemas de configuración sin necesidad de depuración por consola
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFb71c1c), 
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "ERROR FATAL AL INICIAR LA APP:\n\n$error",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// Widget raíz de la aplicación funcional
// Configuración del enrutamiento, la internacionalización (idioma español) y el tema visual global
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // Sistema de navegación definido externamente
      routerConfig: appRouter, 
      // Estilos visuales globales
      theme: AppTheme.temaPrincipal,
      // Configuración de localización para soportar formatos de fecha y texto en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
    );
  }
}

