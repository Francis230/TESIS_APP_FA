// Archivo - lib/features/conductor/presentation/tabs/alertas_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart'; 
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/conductor_provider.dart';
// Visualización el historial de alertas enviadas por el conductor con opciones de gestión y eliminación
class AlertasTab extends ConsumerWidget {
  const AlertasTab({super.key});
  // Asigna un icono representativo visual según la categoría del mensaje notificado
  IconData _getIconForTipo(String? tipo) {
    switch (tipo) {
      case 'inicio_recorrido':
        return FontAwesomeIcons.bus;
      case 'asistencia_on':
        return FontAwesomeIcons.check;
      case 'asistencia_off':
        return FontAwesomeIcons.xmark;
      case 'observacion':
        return FontAwesomeIcons.commentDots;
      default:
        return FontAwesomeIcons.solidBell;
    }
  }

  // Despliega una alerta visual estilizada para informar sobre errores en el sistema
  Future<void> _mostrarDialogoError(BuildContext context, String mensaje) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text("Error", style: GoogleFonts.montserrat(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.black87)),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Aceptar', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte)))],
      ),
    );
  }
  // Muestra una notificación flotante temporal para confirmar el éxito de una acción
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
  // Solicita confirmación del usuario antes de eliminar todo el registro de alertas enviadas
  void _confirmarBorrarTodo(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secundario,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar historial', style: GoogleFonts.montserrat(color: AppTheme.acentoBlanco, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de eliminar todas las alertas enviadas? Esta acción no se puede deshacer.', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: AppTheme.acentoBlanco, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(eliminarTodasNotificacionesEnviadasProvider.future);
                if (context.mounted) _mostrarToastOscuro(context, 'Historial eliminado');
              } catch (e) {
                if (context.mounted) _mostrarDialogoError(context, 'Error al eliminar el historial: $e');
              }
            },
            child: Text('Eliminar Todo', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // Estructura la interfaz gráfica que presenta el cronograma de notificaciones enviadas
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialEnvioProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Envíos', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
        backgroundColor: AppTheme.negroPrincipal,
        actions: [
          // Permite la limpieza total del historial mediante un botón de acción en la barra superior
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 20),
            tooltip: 'Borrar todo el historial',
            onPressed: () {
              if (historialAsync.value != null && historialAsync.value!.isNotEmpty) {
                _confirmarBorrarTodo(context, ref);
              }
            },
          )
        ],
      ),
      backgroundColor: AppTheme.negroPrincipal,
      // Gestiona la carga asíncrona de datos mostrando estados de espera, error o contenido
      body: historialAsync.when(
        data: (notificaciones) {
          if (notificaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.paperPlane, size: 60, color: AppTheme.grisClaro),
                  const SizedBox(height: 16),
                  Text('Sin envíos aún', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
                  Text('Todavía no has enviado ninguna alerta.', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(historialEnvioProvider.future),
            color: AppTheme.acentoBlanco,
            backgroundColor: AppTheme.azulFuerte,
            // Genera la lista interactiva de mensajes permitiendo su eliminación individual mediante deslizamiento
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notificaciones.length,
              itemBuilder: (context, index) {
                final notificacion = notificaciones[index];
                final notificacionId = notificacion['notificacion_id'] as String;                
                final String fechaStr = notificacion['creada_en'].toString();
                DateTime fechaMostrar;
                try {
                  // Formatea la fecha y hora del evento para su fácil lectura en la lista
                  String fechaLimpia = fechaStr.replaceAll('Z', '').split('+')[0];
                  fechaMostrar = DateTime.parse(fechaLimpia);
                } catch (e) {
                  fechaMostrar = DateTime.now();
                }
                return Dismissible(
                  key: Key(notificacionId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    try {
                      await ref.read(eliminarNotificacionEnviadaProvider(notificacionId).future);
                      if (context.mounted) _mostrarToastOscuro(context, 'Alerta eliminada');
                    } catch (e) {
                      if (context.mounted) _mostrarDialogoError(context, 'Error al eliminar la alerta: $e');
                      ref.refresh(historialEnvioProvider);
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
                    color: AppTheme.secundario.withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.azulFuerte,
                        child: FaIcon(_getIconForTipo(notificacion['tipo']), color: AppTheme.acentoBlanco, size: 20),
                      ),
                      title: Text(notificacion['titulo'] ?? 'Notificación enviada', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
                      subtitle: Text(notificacion['mensaje'] ?? '', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
                      trailing: Text(
                        DateFormat('dd/MM\nhh:mm a').format(fechaMostrar),
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
        error: (err, stack) => Center(child: Text('Error al cargar historial: $err', style: GoogleFonts.montserrat(color: Colors.red))),
      ),
    );
  }
}
