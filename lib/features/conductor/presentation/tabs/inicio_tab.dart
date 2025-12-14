// Archivo - lib/features/conductor/presentation/tabs/inicio_tab.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/core/widgets/boton_principal.dart';
import 'package:tesis_appmovilfaj/core/widgets/mapa_widget.dart';
import 'package:tesis_appmovilfaj/features/auth/data/auth_repository.dart';
import 'package:tesis_appmovilfaj/features/conductor/data/conductor_repository.dart';
import 'package:tesis_appmovilfaj/servicios/ubicacion_servicio.dart';
// Gestión del panel principal del conductor permitiendo el inicio del recorrido y la visualización del estado actual
class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  // Administra las conexiones con los servicios de datos, autenticación y geolocalización
  final _conductorRepo = ConductorRepository();
  final _authRepo = AuthRepository();
  final _ubicacionServicio = UbicacionServicio();

  bool _enRecorrido = false;
  bool _cargando = true;
  String _numeroRuta = '...';
  String _descripcionRuta = '...';
  Map<String, dynamic>? _perfil;

  @override
  void initState() {
    super.initState();
     // Inicia la carga de datos y configura los oyentes para detectar cambios en el perfil
    _cargarDatosCompletos();
    perfilActualizadoNotifier.addListener(() {
      _cargarDatosCompletos();
    });
  }

  @override
  void dispose() {
    perfilActualizadoNotifier.removeListener(_cargarDatosCompletos);
    super.dispose();
  }
  // Convierte los códigos de error técnicos en mensajes claros y comprensibles para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('permiso de ubicación denegado')) {
      return 'No diste permiso para acceder a la ubicación. No se puede iniciar el recorrido.';
    }
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cargar datos") {
      return 'Error al cargar tus datos. Intenta refrescar.';
    }
    if (contexto == "cerrar sesion") {
      return 'Error al intentar cerrar sesión.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Despliega una alerta visual estilizada para comunicar fallos operativos importantes
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
        margin: EdgeInsets.only( 
          bottom: 120,
          left: 24,
          right: 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // Recupera la información actualizada del perfil y el estado de la ruta desde el servidor
  Future<void> _cargarDatosCompletos() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final [statusData, perfilData] = await Future.wait([
        _conductorRepo.getConductorStatus(),
        _authRepo.getMyProfile(),
      ]);

      if (!mounted) return;
      setState(() {
        _perfil = perfilData;
        if (statusData != null) {
          _enRecorrido = statusData['compartiendo_ubicacion'] ?? false;
          _numeroRuta = statusData['rutas']?['numero_ruta'] ?? 'No asignada';
          _descripcionRuta =
              statusData['rutas']?['descripcion'] ??
              'Presiona "Iniciar Recorrido" para empezar.';
        } else {
          _numeroRuta = 'No asignada';
          _descripcionRuta =
              'No tienes una ruta asignada actualmente.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogoError(_traducirError(e, "cargar datos"));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // Activa o detiene el rastreo GPS y notifica el cambio de estado a los representantes
  Future<void> _toggleRecorrido() async {
    setState(() => _cargando = true);
    final nuevoEstado = !_enRecorrido;
    final conductorId = Supabase.instance.client.auth.currentUser?.id;

    if (conductorId == null) {
      await _mostrarDialogoError("No se pudo identificar al conductor. Intenta iniciar sesión de nuevo.");
      setState(() => _cargando = false);
      return;
    }

    try {
      if (nuevoEstado) {
        final tienePermisos = await _ubicacionServicio.verificarPermisos();
        if (!tienePermisos) throw Exception('Permiso de ubicación denegado.');
      }

      await _conductorRepo.setSharingLocation(nuevoEstado);

      if (nuevoEstado) {
        final estudiantes = await _conductorRepo.obtenerEstudiantes();
        await _ubicacionServicio.iniciarEscuchaConductor(conductorId, estudiantes);

        final nombreConductor = _perfil?['nombre_completo'] ?? 'El conductor';
        await _conductorRepo.enviarNotificacionInicioRecorrido(nombreConductor);
      } else {
        await _ubicacionServicio.detenerEscucha();
      }

      setState(() => _enRecorrido = nuevoEstado);
      
      _mostrarToastOscuro(
        nuevoEstado
            ? 'Recorrido iniciado. Compartiendo ubicación.'
            : 'Recorrido finalizado.',
      );

    } catch (e) {
      await _mostrarDialogoError(_traducirError(e, "iniciar recorrido"));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
  // Finaliza la sesión actual y detiene cualquier proceso de rastreo activo
  Future<void> _signOut() async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Cerrar Sesión',
              style: GoogleFonts.montserrat(
                color: AppTheme.negroPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '¿Estás seguro? Cualquier recorrido activo se detendrá.',
              style: GoogleFonts.montserrat(color: Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.azulFuerte,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Cerrar sesión',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmar && mounted) {
      try {
        if (_enRecorrido) {
          await _conductorRepo.setSharingLocation(false);
          await _ubicacionServicio.detenerEscucha();
        }
        await _authRepo.signOut();
        if (mounted) {
          context.go('/login');
          _mostrarToastOscuro("Sesión cerrada exitosamente.");
        }
      } catch (e) {
        if (mounted) {
          await _mostrarDialogoError(_traducirError(e, "cerrar sesion"));
        }
      }
    }
  }
  // Construye la interfaz adaptativa alternando entre la vista de mapa y el panel
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _enRecorrido
            ? _buildEnRecorrido()
            : _buildFueraDeRecorrido(),
      ),
    );
  }
  // Muestra el panel informativo cuando el conductor no está transmitiendo su ubicación
  Widget _buildFueraDeRecorrido() {
    return SafeArea(
      key: const ValueKey('fuera_recorrido'),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDashboardCard(),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
          ),
          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.acentoBlanco),
              ),
            ),
        ],
      ),
    );
  }
  // Presenta la información personal del conductor y las opciones de sesión en la cabecera
  Widget _buildHeader() {
    String nombreCorto =
        _perfil?['nombre_completo']?.toString().split(' ').first ?? 'Conductor';
    final fotoUrl = _perfil?['foto_url'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.secundario,
            backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                ? NetworkImage(fotoUrl)
                : null,
            child: (fotoUrl == null || fotoUrl.isEmpty)
                ? const FaIcon(
                    FontAwesomeIcons.solidUser,
                    color: AppTheme.grisClaro,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido conduct@r, $nombreCorto!',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.acentoBlanco,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Listo para iniciar el recorrido',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.grisClaro,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: AppTheme.grisClaro,
              size: 22,
            ),
            tooltip: 'Cerrar Sesión',
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
   // Visualiza los detalles de la ruta asignada y el estado actual de la operación
  Widget _buildDashboardCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.fondoClaro,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            "Ruta Asignada",
            style: GoogleFonts.montserrat(
              color: AppTheme.tonoIntermedio,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "$_numeroRuta - $_descripcionRuta",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppTheme.negroPrincipal,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Transform.scale(
              scale: 1.6,
              child: SizedBox(
                width: 180,
                height: 180,
                child: Lottie.asset(
                  'assets/animations/conductor/inicio_conductor.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Presiona "Iniciar Recorrido" para empezar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppTheme.tonoIntermedio,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: BotonPrincipal(
              texto: _enRecorrido ? 'FINALIZAR RECORRIDO' : 'INICIAR RECORRIDO',
              color: _enRecorrido
                  ? Colors.red.shade700
                  : AppTheme.negroPrincipal,
              cargando: _cargando,
              onPressed: _toggleRecorrido,
            ),
          ),
        ],
      ),
    );
  }
  // Despliega el mapa interactivo en tiempo real cuando el recorrido está activo
  Widget _buildEnRecorrido() {
    return Stack(
      key: const ValueKey('en_recorrido'),
      children: [
        MapaWidget(ubicacionServicio: _ubicacionServicio),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: BotonPrincipal(
                texto: 'FINALIZAR RECORRIDO',
                color: Colors.red.shade700,
                cargando: _cargando,
                onPressed: _toggleRecorrido,
              ),
            ),
          ),
        ),
        if (_cargando)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.acentoBlanco),
            ),
          ),
      ],
    );
  }
}

// Notifica a otros componentes de la app cuando se produce un cambio en el perfil
final perfilActualizadoNotifier = ValueNotifier<bool>(false);
