// Archivo - lib/features/conductor/presentation/tabs/estudiantes_tab.dart
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/features/conductor/data/conductor_repository.dart';
import 'package:tesis_appmovilfaj/features/conductor/presentation/registrar_editar_estudiante.dart';
import 'package:lottie/lottie.dart';
// Presentación del listado de estudiantes asignados a la ruta y permite su administración (crear, editar, eliminar)
class EstudiantesTab extends StatefulWidget {
  const EstudiantesTab({super.key});
  @override
  State<EstudiantesTab> createState() => _EstudiantesTabState();
}

class _EstudiantesTabState extends State<EstudiantesTab> {
  final _repo = ConductorRepository();
  // Controla la carga asíncrona de la lista de pasajeros
  late Future<List<Map<String, dynamic>>> _futureEstudiantes;
  RealtimeChannel? _canalEstudiantes;
  // Mantiene la conexión en tiempo real para detectar cambios automáticos
  final _controladorBusqueda = TextEditingController();
  // Almacena la lista completa original para realizar filtrados locales
  List<Map<String, dynamic>> _todosLosEstudiantes = [];
  // Almacena los resultados visibles según el criterio de búsqueda
  List<Map<String, dynamic>> _estudiantesFiltrados = [];

  @override
  void initState() {
    super.initState();
    _refrescar();
    // Activa la escucha de actualizaciones automáticas desde la base de datos
    _canalEstudiantes = _repo.suscribirseACambiosDeEstudiantes(_refrescar);
    _controladorBusqueda.addListener(_filtrarEstudiantes);
  }

  @override
  void dispose() {
    if (_canalEstudiantes != null) {
      Supabase.instance.client.removeChannel(_canalEstudiantes!);
    }
    _controladorBusqueda.removeListener(_filtrarEstudiantes);
    _controladorBusqueda.dispose();
    super.dispose();
  }

  // Recarga los datos desde el servidor y actualiza la vista con la información más reciente
  void _refrescar() {
    if (mounted) {
      _futureEstudiantes = _repo.obtenerEstudiantes();
      _futureEstudiantes.then((listaCompleta) {
        if (mounted) {
          setState(() {
            _todosLosEstudiantes = listaCompleta;
            _filtrarEstudiantes();
          });
        }
      }).catchError((error) {
        print("Error al refrescar estudiantes: $error");
        if (mounted) {
          _mostrarDialogoError(_traducirError(error, "refrescar"));
          setState(() {
            _todosLosEstudiantes = [];
            _estudiantesFiltrados = [];
          });
        }
      });
      setState(() {});
    }
  }

  // Aplica el filtro de texto sobre la lista local para encontrar estudiantes por nombre
  void _filtrarEstudiantes() {
    final query = _controladorBusqueda.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _estudiantesFiltrados = List.from(_todosLosEstudiantes);
      } else {
        _estudiantesFiltrados = _todosLosEstudiantes.where((estudiante) {
          final nombre = estudiante['nombre_completo']?.toString().toLowerCase() ?? '';
          return nombre.contains(query);
        }).toList();
      }
    });
  }

  // Navega a la pantalla de formulario
  Future<void> _navegarAFormulario([Map<String, dynamic>? estudiante]) async {
    await context.push('/conductor/formulario-estudiante', extra: estudiante);
    _refrescar();
  }
  // Traduce errores técnicos a mensajes entendibles para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "refrescar") {
      return 'Error al cargar la lista de estudiantes.';
    }
    if (contexto == "eliminar") {
      return 'Error al intentar eliminar al estudiante.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  // Despliega una alerta visual estilizada para informar sobre errores graves
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

  // Muestra una notificación breve y discreta en la parte inferior de la pantalla
  void _mostrarToastOscuro(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: esError ? Colors.red.shade800 : AppTheme.negroPrincipal,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                esError ? 'assets/animations/bool/error.json' : 'assets/animations/bool/correct.json',
                height: 30,
                width: 30,
                repeat: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        // Centrado sobre la barra de navegación
        margin: EdgeInsets.only( 
          bottom: 120, 
          left: 24,
          right: 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // Muestra diálogo de confirmación y elimina al estudiante.
  Future<void> _eliminar(Map<String, dynamic> estudiante) async {    
    final bool tieneRepresentante = estudiante['representante'] != null;

    if (tieneRepresentante) {
      // Si tiene representante, mostrar un pop-up de error y detener la función.
      await _mostrarDialogoError(
        "Acción no permitida. Este estudiante tiene un representante asignado y no puede ser eliminado."
      );
      return; 
    }
    final String estudianteId = estudiante['estudiante_id'];
    final bool confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Eliminar Estudiante', style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.bold)), 
            content: Text('¿Estás seguro? El estudiante (sin representante) será marcado como inactivo.', style: GoogleFonts.montserrat(color: Colors.black87)), 
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Sí, eliminar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ?? false;

    if (confirmar && mounted) {
      try {
        await _repo.eliminarEstudiante(estudianteId);
        if (mounted) { 
          _mostrarToastOscuro('Estudiante eliminado.');
        }
      } catch (e) {
        if(mounted) await _mostrarDialogoError(_traducirError(e, "eliminar"));
      }
    }
  }
  // Construye la interfaz principal con barra de búsqueda, listado y controles de acción
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: Text('Mis Estudiantes', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco)),
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
        actions: [
          // Botón animado para actualizar manualmente la lista de estudiantes
          _LottieAppBarIcon(
            lottiePath: 'assets/animations/conductor/recargar_estu.json',
            onPressed: _refrescar,
            tooltip: 'Recargar Lista',
            errorIcon: FontAwesomeIcons.arrowsRotate,
          ),
          
          // Botón animado para iniciar el proceso de registro de un nuevo estudiante
          _LottieAppBarIcon(
            lottiePath: 'assets/animations/conductor/agregar_estu.json',
            onPressed: () => _navegarAFormulario(),
            tooltip: 'Registrar Nuevo Estudiante',
            errorIcon: FontAwesomeIcons.userPlus,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de texto para buscar estudiantes por nombre en tiempo real
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
              child: TextField(
                controller: _controladorBusqueda,
                style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
                cursorColor: AppTheme.negroPrincipal,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre...',
                  hintStyle: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.tonoIntermedio),
                  filled: true,
                  fillColor: AppTheme.fondoClaro,
                  isDense: true, 
                  border: OutlineInputBorder( 
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none, 
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  suffixIcon: _controladorBusqueda.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.tonoIntermedio, size: 20),
                          onPressed: () {
                            _controladorBusqueda.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
            
            // Lista de resultados con manejo de estados (carga, error, vacío, datos)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureEstudiantes, 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _todosLosEstudiantes.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.acentoBlanco));
                  }
                  if (snapshot.hasError && _todosLosEstudiantes.isEmpty) {
                    return _buildEstadoVacio(
                      'Error al Cargar', 
                      'No se pudieron cargar los estudiantes. Intenta recargar la lista.',
                      'assets/animations/conductor/error_search.json',
                    );
                  }

                  if (_controladorBusqueda.text.isNotEmpty && _estudiantesFiltrados.isEmpty) {
                    return _buildEstadoVacio(
                        'Sin resultados', 
                        'No se encontraron estudiantes que coincidan con "${_controladorBusqueda.text}".',
                        'assets/animations/conductor/error_search.json',
                    );
                  }
                  
                  if (_todosLosEstudiantes.isEmpty && snapshot.connectionState == ConnectionState.done) {
                      return _buildEstadoVacio(
                        'Aún no tienes estudiantes', 
                        'Presiona el botón (+) en la esquina superior para registrar tu primer estudiante.',
                        'assets/animations/conductor/error_search.json',
                      );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
                    itemCount: _estudiantesFiltrados.length,
                    itemBuilder: (context, index) {
                      final estudiante = _estudiantesFiltrados[index];
                      
                      final representante = estudiante['representante'];
                      final bool esHuerfano = representante == null;

                      String subtitulo;
                      if (esHuerfano) {
                        subtitulo = '¡Representante NO asignado!';
                      } else {
                        subtitulo = '${estudiante['grado'] ?? ''} "${estudiante['paralelo'] ?? ''}"';
                      }

                      return Card(
                        color: esHuerfano ? Colors.yellow.shade100 : AppTheme.fondoClaro,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: estudiante['foto_url'] != null ? NetworkImage(estudiante['foto_url']) : null,
                            backgroundColor: AppTheme.grisClaro.withOpacity(0.5),
                            child: estudiante['foto_url'] == null 
                                ? const FaIcon(FontAwesomeIcons.child, color: AppTheme.tonoIntermedio, size: 20)
                                : null,
                          ),
                          title: Text(
                            estudiante['nombre_completo'] ?? 'Sin nombre',
                            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.w600)
                          ),
                          subtitle: Text(
                            subtitulo,
                            style: GoogleFonts.montserrat(
                              color: esHuerfano ? Colors.red.shade700 : AppTheme.tonoIntermedio,
                              fontWeight: esHuerfano ? FontWeight.bold : FontWeight.normal
                            ) 
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.tonoIntermedio),
                            onSelected: (value) {
                              if (value == 'editar') {
                                _navegarAFormulario(estudiante);
                              } else if (value == 'eliminar') {
                                _eliminar(estudiante);
                              }
                            },
                            itemBuilder: (context) => [ 
                              PopupMenuItem(value: 'editar', child: Text('Actualizar/Asignar', style: GoogleFonts.montserrat())),
                              PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: GoogleFonts.montserrat(color: Colors.redAccent.shade200))),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Muestra una vista amigable cuando no hay datos disponibles o la búsqueda no arroja resultados
  Widget _buildEstadoVacio(String titulo, String subtitulo, String animacionPath) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          decoration: BoxDecoration(
            color: AppTheme.fondoClaro,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.grisClaro.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Lottie.asset(
                  animacionPath,
                  fit: BoxFit.contain,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => const FaIcon(FontAwesomeIcons.boxOpen, size: 60, color: AppTheme.tonoIntermedio),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.negroPrincipal,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppTheme.tonoIntermedio,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Muestra un botón con icono animado en la barra superior

class _LottieAppBarIcon extends StatefulWidget {
  final String lottiePath;
  final VoidCallback onPressed;
  final String tooltip;
  final IconData errorIcon;

  const _LottieAppBarIcon({
    required this.lottiePath,
    required this.onPressed,
    required this.tooltip,
    required this.errorIcon,
  });

  @override
  State<_LottieAppBarIcon> createState() => _LottieAppBarIconState();
}

class _LottieAppBarIconState extends State<_LottieAppBarIcon> with TickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    
    // Timer para disparar la animación cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });

    _controller.addStatusListener((status) {
       if (status == AnimationStatus.completed) {
       }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      icon: Lottie.asset(
        widget.lottiePath,
        controller: _controller,
        onLoaded: (composition) {
          // Asigna la duración y detiene
          _controller.duration = composition.duration;
          _controller.stop();
        },
        width: 30,
        height: 30,
        errorBuilder: (context, error, stackTrace) => FaIcon(widget.errorIcon, color: AppTheme.acentoBlanco, size: 22),
      ),
    );
  }
}