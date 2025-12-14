// Archivo - lib/features/representante/presentation/tabs/inicio_tab.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker; 
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/auth_provider.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';

// Controla la visibilidad del mapa para alternar entre la vista de tarjeta y el mapa completo
final mapVisibleProvider = StateProvider<bool>((ref) => false);
// Gestiona la pantalla principal del representante con el rastreo del bus y estado del recorrido
class InicioTabRepresentante extends ConsumerStatefulWidget {
  const InicioTabRepresentante({super.key});

  @override
  ConsumerState<InicioTabRepresentante> createState() =>
      _InicioTabRepresentanteState();
}

class _InicioTabRepresentanteState
    extends ConsumerState<InicioTabRepresentante> {
  bool _ocultarBanner = false; 
  final Completer<GoogleMapController> _mapController = Completer();
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    // Prepara el ícono del autobús al iniciar la pantalla
    _loadBusIcon();
  }

  // Carga y optimiza la imagen del marcador del autobús para el mapa
  Future<void> _loadBusIcon() async {
    try {
      if (kIsWeb) {
        setState(() {
          _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        });
        return;
      }
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/bus_icon.png', 100);
      setState(() {
        _busIcon = BitmapDescriptor.fromBytes(markerIcon);
      });
    } catch (e) {
      debugPrint(" Error cargando ícono del bus: $e");
      setState(() {
        _busIcon = BitmapDescriptor.defaultMarker;
      });
    }
  }
  // Convierte el archivo de imagen a un formato compatible con el mapa de Google
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  // Mueve la cámara del mapa suavemente hacia la nueva posición del vehículo
  void _centrarCamara(LatLng posicion) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(posicion, 16.5));
  }
  // Traducción de errores para el ususario se muestra
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cerrar sesion") {
      return 'Error al intentar cerrar sesión.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Errores visuales para mostrar al ususario de manera corta y sencilla
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
  // Despliega una alerta visual estilizada para informar sobre fallos en el proceso
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
  // Muestra una notificación breve y discreta en la parte inferior de la pantalla
  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: GoogleFonts.montserrat(
                color: AppTheme.negroPrincipal, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.azulFuerte,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(supabaseProvider).auth.signOut();
                ref.read(mapVisibleProvider.notifier).state = false;
                if (mounted) {
                  context.go('/login');
                  _mostrarToastOscuro("Sesión cerrada exitosamente.");
                }
              } catch (e) {
                if (mounted) { 
                  _mostrarDialogoError(_traducirError(e, "cerrar sesion"));
                }
              }
            },
            child: Text('Cerrar sesión',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  // Construye la interfaz principal reaccionando a los cambios de ubicación en tiempo real
  Widget _buildBannerPerfilIncompleto() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secundario,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.tonoIntermedio.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/bool/warning.json', 
            height: 40,
            width: 40
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Completa tu perfil para habilitar todas las funciones de la app.",
              style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.3),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _ocultarBanner = true), 
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  // Lógica para detectar si faltan datos en el perfil
  bool _esPerfilIncompleto(Map<String, dynamic>? perfil) {
    if (perfil == null) return true; // Si no hay perfil, está incompleto
    
    // Campos que se validan (los mismos de perfil_tab_representante.dart)
    final campos = ['telefono', 'direccion', 'parentesco', 'documento_identidad'];
    
    for (final campo in campos) {
      final valor = perfil[campo];
      // Si el valor es nulo O es un string vacío
      if (valor == null || (valor is String && valor.trim().isEmpty)) {
        return true; // Perfil incompleto
      }
    }
    return false; // Perfil completo
  }
  
   // Construye la interfaz principal reaccionando a los cambios de ubicación en tiempo real
  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(miPerfilProvider);
    final ubicacionAsync = ref.watch(ubicacionStreamProvider);
    final isMapVisible = ref.watch(mapVisibleProvider);
    final estudiantesAsync = ref.watch(misEstudiantesProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.negroPrincipal,
        
        appBar: AppBar(
          backgroundColor: AppTheme.negroPrincipal,
          elevation: 0,
          toolbarHeight: 90,
          title: perfilAsync.when(
            data: (perfil) => _buildHeader(perfil),
            loading: () => const SizedBox(height: 56),
            error: (e, s) => const Icon(Icons.error, color: Colors.red),
          ),
        ),

        body: perfilAsync.when(
          data: (perfil) {
            // Esta lógica para el banner es correcta
            final bool perfilIncompleto = _esPerfilIncompleto(perfil);

            return Stack(
              children: [
                ubicacionAsync.when(
                  data: (ubicacionData) {
                    if (!isMapVisible) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB( 
                            16.0,
                            (perfilIncompleto && !_ocultarBanner) ? 95.0 : 16.0, 
                            16.0,
                            16.0
                          ),
                          child: _buildEstudianteCard(
                              context, ref, estudiantesAsync, ubicacionData),
                        ),
                      );
                    }
                    // Gestiona los diferentes estados de la conexión (cargando, error, sin datos, activo)
                    if (ubicacionData == null) {
                      return _buildEstadoTarjeta("Sin Conductor",
                          "Tu estudiante no tiene un conductor asignado.",
                          FontAwesomeIcons.userSlash);
                    }
                    final bool compartiendo = ubicacionData['compartiendo_ubicacion'] ?? false;
                    if (!compartiendo) {
                      return _buildEstadoTarjeta("Recorrido no iniciado",
                          "El conductor no está compartiendo su ubicación.",
                          FontAwesomeIcons.triangleExclamation);
                    }
                    final double lat = (ubicacionData['latitud_actual'] as num?)?.toDouble() ?? 0.0;
                    final double lng = (ubicacionData['longitud_actual'] as num?)?.toDouble() ?? 0.0;
                    final LatLng busPosicion = LatLng(lat, lng);
                    // Centra el mapa si las coordenadas recibidas son válidas
                    if (lat != 0.0 && lng != 0.0) _centrarCamara(busPosicion);

                    final Marker busMarker = Marker(
                      markerId: const MarkerId('bus_escolar'),
                      position: busPosicion,
                      icon: _busIcon,
                      infoWindow: const InfoWindow(title: 'Bus Escolar'),
                    );

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition:
                              CameraPosition(target: busPosicion, zoom: 16.5),
                          onMapCreated: (controller) {
                            if (!_mapController.isCompleted) {
                              _mapController.complete(controller);
                            }
                          },
                          markers: {busMarker},
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          myLocationEnabled: false,
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
                  error: (err, _) => _buildEstadoTarjeta("Error", "Error de conexión: $err", FontAwesomeIcons.cloud),
                ),

                // Botón "Ocultar Mapa"
                if (isMapVisible)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton.extended(
                      heroTag: 'ocultarMapaBtn',
                      onPressed: () =>
                          ref.read(mapVisibleProvider.notifier).state = false,
                      backgroundColor: AppTheme.fondoClaro,
                      foregroundColor: AppTheme.negroPrincipal,
                      icon: const FaIcon(FontAwesomeIcons.mapLocation, size: 18),
                      label: Text('Ocultar Mapa',
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Banner de Perfil Incompleto
                if (perfilIncompleto && !_ocultarBanner)
                  Positioned(
                    top: 15,
                    left: 12,
                    right: 12,
                    child: _buildBannerPerfilIncompleto(),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
          error: (err, stack) => _buildEstadoTarjeta("Error", _traducirError(err, "cargar perfil"), FontAwesomeIcons.cloud),
        ),
      ),
    );
  }

  // Header del inicio del representante
  Widget _buildHeader(Map<String, dynamic>? perfil) {
    String nombreCorto = (perfil?['nombre_completo']?.toString() ?? 'Representante').split(' ').first;
    final fotoUrl = perfil?['foto_url'] as String?;

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¡Bienvenido, $nombreCorto!',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.acentoBlanco,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rol: Representante',
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
            onPressed: _confirmarCerrarSesion,
          ),
        ],
      ),
    );
  }
  // Tarjeta blanca para la informacion del estudiante si esta asignado ademas del conductor asignado
  Widget _buildEstudianteCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> estudiantesAsync,
    Map<String, dynamic>? ubicacionData,
  ) {
    String tituloMapa = "Ubicación del Bus";
    String subtituloMapa = "Presiona para ver la ubicación del bus en tiempo real.";
    Widget iconoWidget; 
    bool puedeVerMapa = false;

    if (ubicacionData == null) {
      tituloMapa = "Sin Conductor";
      subtituloMapa = "Tu estudiante no tiene un conductor asignado.";
      iconoWidget = FaIcon(FontAwesomeIcons.userSlash,
          size: 40, color: AppTheme.tonoIntermedio);
          
    } else if (ubicacionData['compartiendo_ubicacion'] != true) {
      tituloMapa = "Recorrido no iniciado";
      subtituloMapa = "El conductor no está compartiendo su ubicación.";
      iconoWidget = Lottie.asset(
        'assets/animations/repre/offline_driver.json', 
        width: 60, 
        height: 60,
        fit: BoxFit.contain,
      );
    } else {
      tituloMapa = "Recorrido en Progreso";
      subtituloMapa = "El bus está compartiendo su ubicación.";
      iconoWidget = SizedBox( 
        width: 60, height: 60,
        child: Image.asset(
            'assets/animations/repre/pin_maps.gif',
             fit: BoxFit.contain,
            ),
      );
      puedeVerMapa = true;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.fondoClaro,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Estudiante(s) a Cargo:",
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.negroPrincipal)),
          const SizedBox(height: 15),
          estudiantesAsync.when(
            data: (estudiantes) {
              if (estudiantes.isEmpty) {
                return Text("No tienes estudiantes asignados.",
                    style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio));
              }
              return Column(
                children:
                    estudiantes.map((est) => _buildEstudianteTile(est)).toList(),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, s) => Text("Error al cargar estudiantes.",
                style: GoogleFonts.montserrat(color: Colors.red)),
          ),
          const Divider(color: AppTheme.grisClaro, height: 30, thickness: 0.5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconoWidget, 
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tituloMapa,
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.negroPrincipal)),
                    const SizedBox(height: 4),
                    Text(subtituloMapa,
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: AppTheme.tonoIntermedio)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.map, size: 16),
              label: Text('Ver Mapa',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: puedeVerMapa
                  ? () => ref.read(mapVisibleProvider.notifier).state = true
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: puedeVerMapa ? Colors.black : Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.grisClaro.withOpacity(0.5),
                disabledForegroundColor: AppTheme.tonoIntermedio.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: puedeVerMapa ? 6 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tile de Estudiante
  Widget _buildEstudianteTile(Map<String, dynamic> estudiante) {
    final fotoUrl = estudiante['foto_url'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.grisClaro.withOpacity(0.5),
            backgroundImage:
                (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
            child: (fotoUrl == null || fotoUrl.isEmpty)
                ? const FaIcon(FontAwesomeIcons.child,
                    color: AppTheme.tonoIntermedio, size: 22)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estudiante['nombre_completo'] ?? 'Sin Nombre',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.negroPrincipal)),
                Text(
                  "${estudiante['grado'] ?? ''} ${estudiante['paralelo'] ?? ''}",
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: AppTheme.tonoIntermedio)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Muestra un mensaje informativo cuando el rastreo no está disponible o el recorrido no ha iniciado
  Widget _buildEstadoTarjeta(String titulo, String subtitulo, IconData icono) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.secundario,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.tonoIntermedio.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icono, size: 44, color: AppTheme.azulFuerte),
              const SizedBox(height: 20),
              Text(titulo,
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.acentoBlanco)),
              const SizedBox(height: 8),
              Text(subtitulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: AppTheme.grisClaro, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
