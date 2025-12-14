// Archivo - lib/features/representante/presentation/representante_home_page.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
import 'package:tesis_appmovilfaj/servicios/notificaciones_servicio.dart';
import 'tabs/inicio_tab.dart';
import 'tabs/conductor_tab.dart';
import 'tabs/alertas_tab.dart';
import 'tabs/perfil_tab.dart';
// Configuración de la estructura de navegación principal e inicializa los servicios de comunicación para el representante
class RepresentanteHomePage extends ConsumerStatefulWidget {
  const RepresentanteHomePage({super.key});

  @override
  ConsumerState<RepresentanteHomePage> createState() => _RepresentanteHomePageState();
}

class _RepresentanteHomePageState extends ConsumerState<RepresentanteHomePage> {
  @override
  void initState() {
    super.initState();
      // Activa la escucha de eventos en tiempo real y configura el sistema de notificaciones al iniciar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificacionesServicioProvider).iniciarEscuchaNotificaciones(ref);
        _configurarFCM();
      });
  }
  // Gestiona los permisos del dispositivo y sincroniza el token de mensajería con el perfil del usuario
  Future<void> _configurarFCM() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Obteneción del token
    final token = await messaging.getToken();
    print("📱 Token FCM: $token");

    // Guardar token en Supabase si quieres enviarle notificaciones push
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null && token != null) {
      await Supabase.instance.client
          .from('perfiles')
          .update({'token_push': token})
          .eq('id', userId);
    }
    // Configura la recepción de alertas visuales cuando la aplicación se encuentra en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        FlutterLocalNotificationsPlugin().show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_principal',
              'Notificaciones Generales',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
  // Construye la interfaz gráfica integrando el sistema de navegación por pestañas
  @override
  Widget build(BuildContext context) {
    final int indiceSeleccionado = ref.watch(representanteTabProvider);

    return Scaffold(
      body: IndexedStack(
        // Mantiene el estado de las diferentes secciones para una navegación fluida sin recargas
        index: indiceSeleccionado,
        children: const [
          InicioTabRepresentante(),
          ConductorTab(),
          AlertasTab(),
          PerfilTabRepresentante(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, ref, indiceSeleccionado),
    );
  }
  // Diseña la barra de menú inferior con estilo flotante para el acceso a los módulos
  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref, int indiceSeleccionado) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, ref, FontAwesomeIcons.house, 'Inicio', 0, indiceSeleccionado),
            _buildNavItem(context, ref, FontAwesomeIcons.userTie, 'Conductor', 1, indiceSeleccionado),
            _buildNavItem(context, ref, FontAwesomeIcons.solidBell, 'Alertas', 2, indiceSeleccionado),
            _buildNavItem(context, ref, FontAwesomeIcons.solidUser, 'Mi Perfil', 3, indiceSeleccionado),
          ],
        ),
      ),
    );
  }

  // Renderiza cada opción de navegación y gestiona la actualización del estado de lectura de notificaciones
  Widget _buildNavItem(BuildContext context, WidgetRef ref, IconData icon, String label,
      int index, int currentIndex) {
    final bool isSelected = (index == currentIndex);
    final Color color = isSelected ? AppTheme.acentoBlanco : AppTheme.grisClaro;
    final int nuevasAlertas = (index == 2) ? ref.watch(nuevasAlertasProvider) : 0;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(representanteTabProvider.notifier).state = index;
          if (index == 2) {
            final cliente = Supabase.instance.client;
            final userId = cliente.auth.currentUser?.id;
            if (userId != null) {
              cliente.from('notificaciones')
                  .update({'leida': true})
                  .eq('destinatario_id', userId)
                  .eq('leida', false);

              // Refresca la lista completa
              ref.refresh(notificacionesProvider);
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, color: color, size: 22),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  width: isSelected ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.acentoBlanco : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            // Muestra un indicador visual si existen alertas pendientes de revisión
            if (index == 2 && nuevasAlertas > 0)
              Positioned(
                top: 6,
                right: 26,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            
          ],
        ),
      ),
    );
  }
}
