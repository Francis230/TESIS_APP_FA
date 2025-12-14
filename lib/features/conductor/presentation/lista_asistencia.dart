// Archivo - lib/features/conductor/presentation/lista_asistencia.dart
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart'; 
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import '../data/conductor_repository.dart';
// Gestión la interfaz para el registro diario de asistencia y novedades de los estudiantes
class ListaAsistencia extends StatefulWidget {
  const ListaAsistencia({super.key});

  @override
  State<ListaAsistencia> createState() => _ListaAsistenciaState();
}

class _ListaAsistenciaState extends State<ListaAsistencia> with SingleTickerProviderStateMixin {
  final _repo = ConductorRepository();

  // Controla el estado de la fecha seleccionada, la jornada y la lista de datos
  DateTime _fechaSeleccionada = DateTime.now();
  String _jornadaSeleccionada = 'manana';
  Future<List<Map<String, dynamic>>>? _futureEstudiantesConAsistencia;
  List<Map<String, dynamic>> _estudiantes = [];

  final TextEditingController _observacionController = TextEditingController();
  late final AnimationController _animController;
  String _fechaSeleccionadaFormateada = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _initLocaleAndLoad();
  }
  // Configura el formato regional de fechas e inicia la carga de datos inicial
  Future<void> _initLocaleAndLoad() async {
    await initializeDateFormatting('es_ES', null);
    _actualizarFechaFormateada();
    _refrescar();
    _animController.forward();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    _animController.dispose();
    super.dispose();
  }
  // Formatea la fecha seleccionada para mostrarla de forma legible en el encabezado
  void _actualizarFechaFormateada() {
    final fechaFormato = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(_fechaSeleccionada);
    _fechaSeleccionadaFormateada = fechaFormato[0].toUpperCase() + fechaFormato.substring(1);
  }

  // Consolida la lista de estudiantes combinándola con sus registros de asistencia correspondientes
  Future<List<Map<String, dynamic>>> _cargarDatos() async {
    try {
      final results = await Future.wait([
        _repo.obtenerEstudiantes(),
        _repo.obtenerAsistenciaPorFecha(_fechaSeleccionada),
      ]);
      final List<Map<String, dynamic>> estudiantes = List<Map<String, dynamic>>.from(results[0] as List);
      final List<Map<String, dynamic>> asistencias = List<Map<String, dynamic>>.from(results[1] as List);

      final combinado = estudiantes.map((est) {
        final asistencia = asistencias.firstWhere(
          (a) => a['estudiante_id'] == est['estudiante_id'],
          orElse: () => <String, dynamic>{},
        );
        return {
          ...Map<String, dynamic>.from(est),
          'asistencia_manana': asistencia['asistencia_manana'] as bool?,
          'asistencia_tarde': asistencia['asistencia_tarde'] as bool?,
          'notas': asistencia['notas'] as String?,
        };
      }).toList();

      return combinado;
    } catch (e) {
      await _mostrarDialogoError(_traducirError(e, "cargar datos"));
      throw Exception('Error al cargar datos de asistencia: $e');
    }
  }
  // Recarga la interfaz para reflejar los cambios más recientes en la base de datos
  void _refrescar() {
    if (!mounted) return;
    _actualizarFechaFormateada();
    setState(() {
      _futureEstudiantesConAsistencia = null;
      _futureEstudiantesConAsistencia = _cargarDatos();
    });
  }
  // Gestión de mensajes y alertas 
  // Traduce los errores técnicos a mensajes comprensibles para el usuario.
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión.';
    }
    if (contexto == "cargar datos") {
      return 'Error al cargar los datos de asistencia.';
    }
    if (contexto == "guardar") {
      return 'Error al guardar la asistencia.';
    }
    if (contexto == "observacion") {
       return 'Error al guardar la observación.';
    }
    return 'Ocurrió un error inesperado.';
  }

  // Despliega una ventana emergente para comunicar errores graves u operativos
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

  // Muestra notificaciones breves y discretas sobre el éxito de una acción
  void _mostrarToastOscuro(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        margin: EdgeInsets.only( 
          bottom: 120, // Flota sobre la barra de navegación
          left: 24,
          right: 24,
        ),
        duration: const Duration(seconds: 2), 
      ),
    );
  }
  // Permite seleccionar una fecha pasada o presente mediante un calendario interactivo
  Future<void> _seleccionarFecha(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (ctx, child) {
        // Tema claro para el DatePicker
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.azulFuerte, 
              onPrimary: Colors.white, 
              surface: Colors.white, 
              onSurface: AppTheme.negroPrincipal,
            ),
            dialogBackgroundColor: Colors.white,
            textTheme: GoogleFonts.montserratTextTheme(Theme.of(ctx).textTheme)
                .apply(bodyColor: AppTheme.negroPrincipal, displayColor: AppTheme.negroPrincipal),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null && !DateUtils.isSameDay(fecha, _fechaSeleccionada)) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
      _refrescar();
    }
  }

  // Logica de tomar la asistencia
  bool get _esHoy {
    final ahora = DateTime.now();
    return _fechaSeleccionada.year == ahora.year &&
        _fechaSeleccionada.month == ahora.month &&
        _fechaSeleccionada.day == ahora.day;
  }
  // Registra el estado de asistencia y envía automáticamente una notificación al representante
  Future<void> _marcarAsistencia(Map<String, dynamic> estudiante, bool? nuevoEstado) async {
    if (!_esHoy) {
      _mostrarToastOscuro('Solo se puede modificar la asistencia de hoy.', esError: true);
      return;
    }

    final String estudianteId = estudiante['estudiante_id'];
    final String nombreEstudiante = estudiante['nombre_completo'] ?? 'Estudiante';

    String? representanteId;
    if (estudiante['representante'] is Map) {
      final rep = estudiante['representante'] as Map;
      if (rep['perfil'] is Map) {
        final perfil = rep['perfil'] as Map;
        representanteId = perfil['id']?.toString();
      } else {
        representanteId = rep['representante_id']?.toString() ?? rep['id']?.toString();
      }
    } else if (estudiante['representante_id'] != null) {
      representanteId = estudiante['representante_id'].toString();
    }

    if (representanteId == null) {
      await _mostrarDialogoError('Error: Este estudiante no tiene un representante asignado.');
      return;
    }

    // Actualización optimista de UI (Sin cambios)
    final idx = _estudiantes.indexWhere((e) => e['estudiante_id'] == estudianteId);
    if (idx != -1) {
      setState(() {
        if (_jornadaSeleccionada == 'manana') {
          _estudiantes[idx]['asistencia_manana'] = nuevoEstado;
        } else {
          _estudiantes[idx]['asistencia_tarde'] = nuevoEstado;
        }
      });
    }

    try {
      await _repo.registrarAsistenciaYNotificar(
        estudianteId: estudianteId,
        representanteId: representanteId,
        nombreEstudiante: nombreEstudiante,
        fecha: _fechaSeleccionada,
        esManana: _jornadaSeleccionada == 'manana',
        asistio: nuevoEstado,
      );

      if (!mounted) return;
      String estadoTexto = "marcada como Pendiente";
      if (nuevoEstado == true) estadoTexto = "marcada como PRESENTE";
      if (nuevoEstado == false) estadoTexto = "marcada como AUSENTE";
      _mostrarToastOscuro('$nombreEstudiante: $estadoTexto.');

    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogoError(_traducirError(e, "guardar"));
      _refrescar(); 
    }
  }

  // Abre un cuadro de diálogo para ingresar notas detalladas sobre el estudiante
  Future<void> _mostrarDialogoObservacion(Map<String, dynamic> estudiante) async {
    if (!_esHoy) {
      _mostrarToastOscuro('Solo se pueden añadir observaciones de hoy.', esError: true);
      return;
    }
    final String estudianteId = estudiante['estudiante_id'];
    final String nombreEstudiante = estudiante['nombre_completo'] ?? 'Estudiante';
    _observacionController.text = (estudiante['notas'] ?? '').toString();
    String? representanteId;
    if (estudiante['representante'] is Map) {
      final rep = estudiante['representante'] as Map;
      if (rep['perfil'] is Map) {
        representanteId = (rep['perfil'] as Map)['id']?.toString();
      } else {
        representanteId = rep['representante_id']?.toString() ?? rep['id']?.toString();
      }
    } else if (estudiante['representante_id'] != null) {
      representanteId = estudiante['representante_id'].toString();
    }
    if (representanteId == null) {
      await _mostrarDialogoError('Error: Este estudiante no tiene un representante asignado.');
      return;
    }
    final String? textoGuardado = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Observación para $nombreEstudiante',
              style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.bold)),
          content: TextFormField(
            controller: _observacionController,
            maxLines: 4,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal), 
            decoration: InputDecoration(
              hintText: 'Ej: Salió con su madre, no subió al bus...',
              hintStyle: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio),
              filled: true,
              fillColor: AppTheme.fondoClaro, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () => Navigator.of(ctx).pop(_observacionController.text.trim()),
              child: Text('Guardar', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (textoGuardado != null) {
      try {
        await _repo.registrarObservacionYNotificar(
          estudianteId: estudianteId,
          representanteId: representanteId,
          nombreEstudiante: nombreEstudiante,
          fecha: _fechaSeleccionada,
          observacion: textoGuardado,
          esManana: _jornadaSeleccionada == 'manana',
        );
        if (!mounted) return;
        _mostrarToastOscuro('Observación guardada para $nombreEstudiante.');
        _refrescar();
      } catch (e) {
        if (!mounted) return;
        await _mostrarDialogoError(_traducirError(e, "observacion"));
      }
    }
  }
  // Construye la pantalla principal integrando encabezados, calendario y lista de alumnos
  @override
  Widget build(BuildContext context) {
    final dias = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14), // Fondo negro principal
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.fondoClaro,
              pinned: true,
              expandedHeight: 140, 
              elevation: 6,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text('Asistencia',
                  style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
              centerTitle: true,
              actions: [
                // Icono de calendario por Lottie intermitente
                _LottieAppBarIcon(
                  lottiePath: 'assets/animations/conductor/calendar_conduc.json',
                  onPressed: () => _seleccionarFecha(context),
                  tooltip: 'Seleccionar Fecha',
                  errorIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(width: 8), 
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    _fechaSeleccionadaFormateada, 
                    style: GoogleFonts.montserrat(
                      color: Colors.black87, 
                      fontSize: 18, 
                      fontWeight: FontWeight.w600, 
                    ),
                  ),
                ),
              ),
            ),
            // Renderiza el selector de días horizontal tipo carrusel
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  itemCount: dias.length,
                  itemBuilder: (context, idx) {
                    final dia = dias[idx];
                    final seleccionado = DateUtils.isSameDay(dia, _fechaSeleccionada);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _fechaSeleccionada = dia;
                        });
                        _refrescar();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        width: 66,
                        decoration: BoxDecoration(
                          color: seleccionado ? AppTheme.azulFuerte : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: seleccionado ? Border.all(color: AppTheme.azulFuerte, width: 0) : Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E', 'es_ES').format(dia).substring(0, 2).toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: seleccionado ? Colors.white : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${dia.day}',
                                style: GoogleFonts.montserrat(
                                  color: seleccionado ? Colors.white : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Muestra los botones para alternar entre jornada matutina y vespertina
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('Mañana', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                            selected: _jornadaSeleccionada == 'manana',
                            onSelected: (v) {
                              setState(() => _jornadaSeleccionada = 'manana');
                              _refrescar();
                            },
                            selectedColor: AppTheme.azulFuerte,
                            backgroundColor: Colors.white.withOpacity(0.06),
                            labelStyle: TextStyle(color: _jornadaSeleccionada == 'manana' ? Colors.white : Colors.white70),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text('Tarde', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                            selected: _jornadaSeleccionada == 'tarde',
                            onSelected: (v) {
                              setState(() => _jornadaSeleccionada = 'tarde');
                              _refrescar();
                            },
                            selectedColor: AppTheme.azulFuerte,
                            backgroundColor: Colors.white.withOpacity(0.06),
                            labelStyle: TextStyle(color: _jornadaSeleccionada == 'tarde' ? Colors.white : Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _refrescar,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
                        child: const FaIcon(FontAwesomeIcons.arrowsRotate, color: Colors.white70, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Despliega la lista interactiva de estudiantes para marcar asistencia
            SliverFillRemaining(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureEstudiantesConAsistencia,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.acentoBlanco));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error al cargar.', style: GoogleFonts.montserrat(color: Colors.redAccent)));
                  }

                  if (snap.hasData) {
                    _estudiantes = snap.data!;
                  }

                  if (_estudiantes.isEmpty) {
                    return Center(child: Text('No hay estudiantes asignados.', style: GoogleFonts.montserrat(color: AppTheme.grisClaro)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                    itemCount: _estudiantes.length,
                    itemBuilder: (context, i) {
                      final estudiante = _estudiantes[i];
                      final String nombre = estudiante['nombre_completo'] ?? 'Estudiante';
                      final String grado = estudiante['grado'] ?? '';
                      final String paralelo = estudiante['paralelo'] ?? '';
                      final bool? asistio = _jornadaSeleccionada == 'manana' ? estudiante['asistencia_manana'] as bool? : estudiante['asistencia_tarde'] as bool?;
                      final notas = (estudiante['notas'] ?? '').toString();

                      Color cardColor = Colors.white.withOpacity(0.04);
                      if (asistio == true) cardColor = Colors.green.shade900.withOpacity(0.22);
                      if (asistio == false) cardColor = Colors.red.shade900.withOpacity(0.22);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: estudiante['foto_url'] != null ? NetworkImage(estudiante['foto_url']) : null,
                            backgroundColor: AppTheme.negroPrincipal.withOpacity(0.4),
                            child: estudiante['foto_url'] == null ? const FaIcon(FontAwesomeIcons.child, color: AppTheme.grisClaro) : null,
                          ),
                          title: Text(nombre, style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('$grado ${paralelo.isNotEmpty ? "\"$paralelo\"" : ''}'.trim(), style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontSize: 13)),
                              if (notas.isNotEmpty) Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Nota: $notas', style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio, fontSize: 12)),
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 130, // Ancho fijo para alinear
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Observación
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.solidCommentDots),
                                  color: AppTheme.grisClaro,
                                  iconSize: 20,
                                  tooltip: 'Añadir Observación',
                                  onPressed: !_esHoy ? null : () => _mostrarDialogoObservacion(estudiante),
                                ),
                                // Faltó
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.solidCircleXmark),
                                  color: asistio == false ? Colors.redAccent.shade200 : AppTheme.grisClaro,
                                  iconSize: 22,
                                  tooltip: 'Marcar como Faltó',
                                  onPressed: !_esHoy ? null : () => _marcarAsistencia(estudiante, false),
                                ),
                                // Asistió
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.solidCircleCheck),
                                  color: asistio == true ? Colors.greenAccent.shade200 : AppTheme.grisClaro,
                                  iconSize: 22,
                                  tooltip: 'Marcar como Asistió',
                                  onPressed: !_esHoy ? null : () => _marcarAsistencia(estudiante, true),
                                ),
                              ],
                            ),
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
    
    // Configuración la repetición automática de la animación cada intervalo
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });

    _controller.addStatusListener((status) {
       if (status == AnimationStatus.completed) {}
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
          _controller.duration = composition.duration;
          _controller.stop();
        },
        width: 30,
        height: 30,
        errorBuilder: (context, error, stackTrace) => FaIcon(widget.errorIcon, color: AppTheme.negroPrincipal, size: 22),
      ),
    );
  }
}
