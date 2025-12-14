// Archivo - lib/features/representante/presentation/tabs/alertas_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart'; 
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
// Visualización del historial de notificaciones y alertas de seguridad recibidas por el representante
class AlertasTab extends ConsumerWidget {
  const AlertasTab({super.key});
  // Asigna un icono representativo para identificar rápidamente el tipo de evento
  IconData _getIconForTipo(String? tipo) {
    switch (tipo) {
      case 'cercania':
        return FontAwesomeIcons.locationArrow;
      case 'asistencia_on':
        return FontAwesomeIcons.check;
      case 'asistencia_off':
        return FontAwesomeIcons.xmark;
      case 'retraso':
        return FontAwesomeIcons.triangleExclamation;
      case 'inicio_recorrido':
        return FontAwesomeIcons.bus;
      default:
        return FontAwesomeIcons.solidBell;
    }
  }
  // Convierte los errores técnicos en explicaciones sencillas para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cargar") return 'Error al cargar las notificaciones.';
    if (contexto == "eliminar") return 'Error al eliminar la notificación.';
    return 'Ocurrió un error inesperado.';
  }
  // Convierte los errores técnicos en explicaciones sencillas para el usuario
  Future<void> _mostrarDialogoError(BuildContext context, String mensaje) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text("Error", style: GoogleFonts.montserrat(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Aceptar', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte)))
        ],
      ),
    );
  }
  // Muestra una confirmación breve en pantalla tras realizar una acción exitosa
  void _mostrarToastOscuro(BuildContext context, String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: esError ? Colors.red.shade800 : AppTheme.negroPrincipal,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(esError ? 'assets/animations/bool/error.json' : 'assets/animations/bool/correct.json', height: 30, width: 30, repeat: false),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 120, left: 24, right: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  // Solicita confirmación al usuario antes de borrar permanentemente todo el historial
  void _confirmarBorrarTodo(BuildContext context, WidgetRef ref) {
      showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar Alertas', style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro que deseas eliminar todas tus notificaciones? Esta acción no se puede deshacer.', style: GoogleFonts.montserrat(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: AppTheme.acentoBlanco, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(eliminarTodasNotificacionesProvider.future);
                if (context.mounted) _mostrarToastOscuro(context, 'Historial eliminado');
              } catch (e) {
                if (context.mounted) _mostrarDialogoError(context, _traducirError(e, "eliminar"));
              }
            },
            child: Text('Eliminar Todas', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // Construción de la interfaz principal mostrando la lista de notificaciones recibidas
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtiene el flujo de datos de notificaciones desde el proveedor de estado
    final notificacionesAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Alertas', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
        backgroundColor: AppTheme.negroPrincipal,
        actions: [
          // Obtiene el flujo de datos de notificaciones desde el proveedor de estado
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 20),
            tooltip: 'Borrar todas las alertas',
            onPressed: () {
              if(notificacionesAsync.value != null && notificacionesAsync.value!.isNotEmpty) {
                  _confirmarBorrarTodo(context, ref);
              }
            },
          )
        ],
      ),
      backgroundColor: AppTheme.negroPrincipal,
       // Gestiona los estados de carga, error y visualización de la lista de alertas
      body: notificacionesAsync.when(
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.bellSlash, size: 60, color: AppTheme.grisClaro),
                  const SizedBox(height: 16),
                  Text('Sin notificaciones', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
                  Text('Aún no has recibido ninguna alerta.', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificacionesProvider.future),
            color: AppTheme.acentoBlanco,
            backgroundColor: AppTheme.azulFuerte,
            // Lista interactiva que permite eliminar elementos individuales
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notificaciones.length,
              itemBuilder: (context, index) {
                final notificacion = notificaciones[index];
                final notificacionId = notificacion['notificacion_id'] as String;
                // Procesa la fecha del servidor para mostrar la hora local correcta                
                final String fechaStr = notificacion['creada_en'].toString();
                DateTime fechaMostrar;
                try {
                  String fechaLimpia = fechaStr.replaceAll('Z', '').split('+')[0];
                  fechaMostrar = DateTime.parse(fechaLimpia);
                } catch (e) {
                  fechaMostrar = DateTime.now();
                }
                // Permite deslizar la tarjeta para eliminar la notificación
                return Dismissible(
                  key: Key(notificacionId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    try {
                      await ref.read(eliminarNotificacionProvider(notificacionId).future);
                      if (context.mounted) _mostrarToastOscuro(context, 'Alerta eliminada');
                    } catch (e) {
                      if (context.mounted) _mostrarDialogoError(context, _traducirError(e, "eliminar"));
                      ref.refresh(notificacionesProvider);
                    }
                  },
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
                  ),
                  child: Card(
                    // Diferencia visualmente las notificaciones nuevas de las ya leídas
                    color: (notificacion['leida'] ?? false) ? AppTheme.secundario : AppTheme.tonoIntermedio.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 27, 37, 48),
                        child: FaIcon(_getIconForTipo(notificacion['tipo']), color: AppTheme.acentoBlanco, size: 20),
                      ),
                      title: Text(notificacion['titulo'] ?? 'Notificación', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
                      subtitle: Text(notificacion['mensaje'] ?? '', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
                      trailing: Text(
                        DateFormat('hh:mm a').format(fechaMostrar),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
        error: (err, stack) => Center(child: Text(_traducirError(err, "cargar"), style: GoogleFonts.montserrat(color: Colors.red))),
      ),
    );
  }
}