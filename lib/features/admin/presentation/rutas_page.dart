// Archivo - lib/features/admin/presentation/rutas_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:lottie/lottie.dart'; 
import '../data/admin_repository.dart';
import '../../../app/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validadores.dart'; 
// Administra el catálogo de rutas de transporte y sus configuraciones operativas
class RutasPage extends StatefulWidget {
  const RutasPage({super.key});

  @override
  State<RutasPage> createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  final AdminRepository _repo = AdminRepository();
  List<Map<String, dynamic>> _rutas = [];
  bool _cargando = true;
  // Inicia la recuperación del listado de rutas al abrir la pantalla
  @override
  void initState() {
    super.initState();
    _cargarRutas();
  }
  // Lógica de los datos y persistencia 
  // Obtiene y organiza la lista de rutas registradas para su visualización en pantalla
  Future<void> _cargarRutas() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    
    try {
      final data = await _repo.listarRutas(); 
      // Ordena numéricamente los registros para facilitar la búsqueda lógica en la lista
      data.sort((a, b) { 
        int extractNumber(String? route) {
          if (route == null) return 0;
          final numericPart = route.replaceAll(RegExp(r'[^0-9]'), '');
          return int.tryParse(numericPart.isEmpty ? '0' : numericPart) ?? 0;
        }
        final numA = extractNumber(a['numero_ruta'] as String?);
        final numB = extractNumber(b['numero_ruta'] as String?);
        return numA.compareTo(numB); 
      });

      if (mounted) {
        setState(() => _rutas = data);
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e, "cargar"));
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
  // Gestión de mensajes y alertas
  // Convierte los errores técnicos del sistema en explicaciones claras para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (errorStr.contains('duplicate key value violates unique constraint')) {
      return 'Ya existe una ruta con ese nombre/número. Por favor, verifique.';
    }
    if (errorStr.contains('violates foreign key constraint')) {
      return 'No se puede eliminar esta ruta porque tiene conductores asignados. Reasígnelos primero.';
    }
    if (contexto == "cargar") return 'Error al cargar las rutas.';
    if (contexto == "guardar") return 'Error al guardar la ruta.';
    if (contexto == "eliminar") return 'Error al eliminar la ruta.';
    return 'Ocurrió un error inesperado.';
  }
  // Despliega una alerta visual estilizada para informar sobre fallos en el proceso
  Future<void> _mostrarDialogoError(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text("Error",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(mensaje,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Aceptar', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte)),
          )
        ],
      ),
    );
  }
  // Despliega una notificación visual de confirmación tras una operación exitosa
  Future<void> _mostrarDialogoExito(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Lottie.asset('assets/animations/bool/correct.json', height: 100, repeat: false),
          title: Text('¡Éxito!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text(mensaje, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }
  // Formulario de la gestión
  // Despliega el formulario interactivo para registrar una nueva ruta o modificar una existente
  Future<bool?> _mostrarDialogoCrearEditar({Map<String, dynamic>? ruta}) async { 
    final numeroCtrl = TextEditingController(text: ruta?['numero_ruta'] ?? '');
    final sectorCtrl = TextEditingController(text: ruta?['sector'] ?? '');
    final descCtrl = TextEditingController(text: ruta?['descripcion'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool procesando = false;
    
    return await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setState2) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(
              ruta == null ? 'Crear Ruta' : 'Editar Ruta',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: numeroCtrl,
                    label: 'Número de ruta',
                    hint: 'Ej: Ruta 1',
                    validator: Validadores.validarFormatoRuta,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: sectorCtrl,
                    label: 'Sector',
                    hint: 'Ej: Norte - Carcelén',
                    validator: (v) => Validadores.validarTexto(v, "Sector"),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: descCtrl,
                    label: 'Descripción',
                    hint: 'Ej: Recorrido principal...',
                    validator: (v) => Validadores.validarTexto(v, "Descripción"),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), 
                child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.azulFuerte,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: procesando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState2(() => procesando = true);
                      
                      try {
                        if (ruta == null) {
                          await _repo.crearRuta( 
                            numeroRuta: numeroCtrl.text.trim(),
                            sector: sectorCtrl.text.trim(),
                            descripcion: descCtrl.text.trim(),
                          );
                        } else {
                          await _repo.actualizarRuta( 
                            rutaId: ruta['ruta_id'],
                            numeroRuta: numeroCtrl.text.trim(),
                            sector: sectorCtrl.text.trim(),
                            descripcion: descCtrl.text.trim(),
                          );
                        }
                        
                        if (mounted) { 
                          Navigator.pop(ctx, true); 
                        }
                      } catch (e) {
                        if(mounted) {
                          Navigator.pop(ctx, false); 
                          await _mostrarDialogoError(_traducirError(e, "guardar"));
                        }
                      } finally {
                        if(mounted) {
                           setState2(() => procesando = false);
                        }
                      }
                    },
                child: Text(
                  ruta == null ? 'Crear' : 'Guardar',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)
                ),
              ),
            ],
          );
        });
      },
    );
  }

  // Configura el estilo visual de los campos de texto dentro del diálogo emergente
  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.negroPrincipal), 
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.negroPrincipal.withOpacity(0.7)),
        fillColor: Colors.grey.shade200, 
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.azulFuerte, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  // Proceso de eliminacion 
  // Verifica si la ruta está siendo utilizada por conductores o estudiantes antes de eliminarla
  Future<void> _confirmarEliminar(Map<String, dynamic> ruta) async {
    final String rutaId = ruta['ruta_id'];
    final String nombreRuta = ruta['numero_ruta'];

    // Verificar si la ruta está ocupada
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final uso = await _repo.verificarUsoDeRuta(rutaId);
      Navigator.pop(context); 

      final int conductores = uso['conductores'] ?? 0;
      final int estudiantes = uso['estudiantes'] ?? 0;
      final bool estaOcupada = conductores > 0 || estudiantes > 0;

      // Alerta adecuada a la acción
      if (estaOcupada) {
        // Ruta ocupada
        _mostrarAlertaPeligro(nombreRuta, rutaId, conductores, estudiantes);
      } else {
        // Ruta vacía 
        _mostrarConfirmacionSimple(nombreRuta, rutaId);
      }

    } catch (e) {
      Navigator.pop(context); 
      _mostrarDialogoError('No se pudo verificar el estado de la ruta. Inténtalo de nuevo.');
    }
  }
  // Advierte sobre las consecuencias de eliminar una ruta que tiene personal o alumnos asignados
  Future<void> _mostrarAlertaPeligro(String nombre, String id, int conds, int studs) async {
    if (!mounted) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // Usamos una animación de advertencia si tienes, si no el icono standard
        icon: const FaIcon(FontAwesomeIcons.triangleExclamation, size: 50, color: Colors.orange),
        title: Text(
          '¡Acción Requerida!',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.red.shade900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La ruta "$nombre" no está vacía.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(FontAwesomeIcons.idCard, 'Conductor(es) afectados'),
                  const SizedBox(height: 8),
                  _infoRow(FontAwesomeIcons.graduationCap, 'Estudiante(s) afectados'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Si eliminas esta ruta, todos ellos quedarán "Sin Asignar" y deberás reubicarlos manualmente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Entiendo, Eliminar', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _ejecutarEliminacion(id);
    }
  }

  // Muestra una confirmación estándar para eliminar rutas que no tienen dependencias activas
  Future<void> _mostrarConfirmacionSimple(String nombre, String id) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Eliminar Ruta', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Seguro que deseas eliminar la ruta "$nombre"?',
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _ejecutarEliminacion(id);
    }
  }

  // Procesa la eliminación definitiva del registro en la base de datos tras la confirmación
  Future<void> _ejecutarEliminacion(String id) async {
    try {
      await _repo.eliminarRuta(rutaId: id);
      if (mounted) {
        await _mostrarDialogoExito('Ruta eliminada correctamente.');
        _cargarRutas(); 
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e, "eliminar"));
      }
    }
  }
  // Crea una fila visual para mostrar detalles de afectación en las alertas
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: Colors.orange.shade800),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.montserrat(color: Colors.orange.shade900, fontWeight: FontWeight.w500)),
      ],
    );
  }
  // Diseña la tarjeta visual que resume la información clave de cada itinerario
  Widget _buildRouteItem(Map<String, dynamic> r) {
    final String numeroRuta = r['numero_ruta'] ?? 'Ruta Sin Nº';
    final String sector = r['sector'] ?? 'Sector no especificado';
    final String descripcion = r['descripcion'] ?? 'Recorrido no detallado';
    final String subtitulo = '$sector | Recorrido: ${descripcion.split('hasta').first.trim()}...';

    return Card(
      color: AppTheme.secundario,
      margin: EdgeInsets.zero,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async {
          final result = await _mostrarDialogoCrearEditar(ruta: r);
          if (result == true && mounted) {
            await _mostrarDialogoExito('Ruta actualizada correctamente');
            await _cargarRutas(); 
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(
                FontAwesomeIcons.bus,
                color: const Color.fromARGB(255, 255, 255, 255),
                size: 40, 
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      numeroRuta,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w900,
                        fontSize: 18, 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Colors.white70, 
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    final result = await _mostrarDialogoCrearEditar(ruta: r);
                    if (result == true && mounted) {
                      await _mostrarDialogoExito('Ruta actualizada correctamente');
                      await _cargarRutas(); 
                    }
                  }
                  if (v == 'delete') _confirmarEliminar(r);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
                ],
                color: AppTheme.secundario,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                icon: const Icon(Icons.more_vert, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Construye la interfaz principal con la lista de rutas y las opciones de gestión
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: const Text('Gestión de Rutas'),
        backgroundColor: AppTheme.negroPrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Crear ruta',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await _mostrarDialogoCrearEditar();
              if (result == true && mounted) {
                await _mostrarDialogoExito('Ruta creada correctamente');
                await _cargarRutas();
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _cargarRutas,
              color: AppTheme.azulFuerte,
              backgroundColor: Colors.white,
              child: _rutas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.route, color: Colors.white24, size: 50),
                          SizedBox(height: 16),
                          Text('No hay rutas registradas.', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 16)),
                        ],
                      )
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rutas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = _rutas[index];
                        return _buildRouteItem(r);
                      },
                    ),
            ),
    );
  }
}
