// Archivo - lib/features/notificaciones/presentation/lista_notificaciones.dart
// Pantalla que lista todas las notificaciones del usuario autenticado.
// El estudiante implementa la consulta a Supabase y el renderizado en una lista.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../servicios/supabase_servicio.dart';
// Esta clase define la pantalla donde el usuario visualiza sus notificaciones
class ListaNotificaciones extends StatefulWidget {
  const ListaNotificaciones({super.key});

  @override
  State<ListaNotificaciones> createState() => _ListaNotificacionesState();
}
// Gestiona la carga, visualización y actualización del estado de las notificaciones
class _ListaNotificacionesState extends State<ListaNotificaciones> {
  final _cliente = SupabaseServicio.cliente();
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Inicia automáticamente la carga de notificaciones al acceder al módulo
    _cargarNotificaciones();
  }
  // Inicia automáticamente la carga de notificaciones al acceder al módulo
  Future<void> _cargarNotificaciones() async {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) return;

    final res = await _cliente
        .from('notificaciones')
        .select('notificacion_id, titulo, mensaje, leida, creada_en')
        .eq('destinatario_id', usuario.id)
        .order('creada_en', ascending: false);

    setState(() {
      _notificaciones = List<Map<String, dynamic>>.from(res);
      _cargando = false;
    });
  }
  // Permite marcar una notificacion como leida.
  Future<void> _marcarComoLeida(String id) async {
    await _cliente.from('notificaciones').update({'leida': true}).eq('notificacion_id', id);
    _cargarNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Presenta la interfaz dedicada a la gestion de notificaciones
      appBar: AppBar(title: const Text('Notificaciones')),
      // Gestión del estado de carga ausencia y visualizacion
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(child: Text('No tienes notificaciones'))
              : ListView.builder(
                  itemCount: _notificaciones.length,
                  itemBuilder: (context, i) {
                    final notif = _notificaciones[i];
                    // Muestra cada notificacion junto con su estado de lectura
                    return Card(
                      color: notif['leida'] ? Colors.grey[850] : Colors.blueGrey[900],
                      child: ListTile(
                        // Presenta el título de la notificación
                        title: Text(
                          notif['titulo'] ?? 'Sin título',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // Presenta el contenido y la fecha de la notificación
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif['mensaje'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              notif['creada_en'] != null
                                  ? DateTime.parse(notif['creada_en']).toLocal().toString()
                                  : '',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                        // Indica visualmene si la notificacion ha sido leida
                        trailing: notif['leida'] == true
                            ? const Icon(Icons.check, color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.mark_email_read, color: Colors.white),
                                onPressed: () => _marcarComoLeida(notif['notificacion_id']),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
