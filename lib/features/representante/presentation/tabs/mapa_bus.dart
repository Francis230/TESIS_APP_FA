// Archivo - lib/features/representante/presentation/tabs/mapa_bus.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
// Esta clase define la interfaz principal del módulo de rastreo satelital para el representante
class InicioTabRepresentante extends ConsumerStatefulWidget {
  const InicioTabRepresentante({super.key});

  @override
  ConsumerState<InicioTabRepresentante> createState() =>
      _InicioTabRepresentanteState();
}
// Gestiona la lógica de visualización, control del mapa y actualización del bus
class _InicioTabRepresentanteState
    extends ConsumerState<InicioTabRepresentante> {
  final Completer<GoogleMapController> _mapController = Completer();
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    // Inicializa los recursos visuales necesarios al cargar el módulo
    _loadBusIcon();
  }

  // Carga un ícono personalizado para identificar el bus escolar dentro del mapa
  void _loadBusIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/images/bus_icon.png',
    );
    if (mounted) {
      setState(() {
        _busIcon = icon;
      });
    }
  }
  // Centra automáticamente la cámara del mapa en la ubicación actual del bus
  void _centrarCamara(LatLng posicion) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(posicion, 16.5));
  }

  @override
  Widget build(BuildContext context) {
    // El sistema escucha en tiempo real el flujo de datos de ubicación del conductor
    final ubicacionAsync = ref.watch(ubicacionStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      // Muestra una barra superior que identifica el módulo de ubicación del bus
      appBar: AppBar(
        title: Text(
          'Ubicación del Bus',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppTheme.acentoBlanco,
          ),
        ),
        backgroundColor: AppTheme.negroPrincipal,
      ),
      // Gestiona los distintos estados del rastreo satelital
      body: ubicacionAsync.when(
        data: (ubicacionData) {
          if (ubicacionData == null) {
            return _buildEstadoTarjeta(
                "Sin Conductor",
                "Tu estudiante no tiene un conductor asignado.",
                Icons.person_off_outlined);
          }
          // Verifica si el conductor ha iniciado el recorrido
          final bool compartiendo =
              ubicacionData['compartiendo_ubicacion'] ?? false;
          if (!compartiendo) {
            return _buildEstadoTarjeta(
                "Recorrido no iniciado",
                "El conductor no está compartiendo su ubicación.",
                Icons.bus_alert);
          }
          // Obtiene las coordenadas actuales del bus escolar
          final double lat =
              (ubicacionData['latitud_actual'] as num?)?.toDouble() ?? 0.0;
          final double lng =
              (ubicacionData['longitud_actual'] as num?)?.toDouble() ?? 0.0;
          final LatLng busPosicion = LatLng(lat, lng);

          // Centramos la cámara si la posición es válida
          if (lat != 0.0) {
            _centrarCamara(busPosicion);
          }
          // Crea el marcador que representa la posición del bus escolar
          final Set<Marker> markers = {
            Marker(
              markerId: const MarkerId('bus_escolar'),
              position: busPosicion,
              icon: _busIcon,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              infoWindow: const InfoWindow(title: 'Bus Escolar'),
            ),
          };
          // Renderiza el mapa y las alertas informativas
          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: busPosicion,
                  zoom: 16.5,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                },
                markers: lat == 0.0 ? {} : markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              _buildTarjetaAlerta(
                "¡El bus está cerca!",
                "Se estima que llegará en 5 minutos.",
              ),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
        error: (err, stack) =>
            _buildEstadoTarjeta("Error", err.toString(), Icons.error),
      ),
    );
  }
  // Construye una tarjeta informativa cuando no existe rastreo disponible
  Widget _buildEstadoTarjeta(String titulo, String subtitulo, IconData icono) {
    return Center(
      child: Card(
        color: AppTheme.secundario,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 50, color: AppTheme.grisClaro),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.acentoBlanco,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppTheme.grisClaro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
   // Construye una tarjeta de alerta para notificar la cercanía del bus
  Widget _buildTarjetaAlerta(String titulo, String subtitulo) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Card(
        color: AppTheme.secundario,
        elevation: 5,
        child: ListTile(
          leading: const Icon(Icons.notifications_active,
              color: AppTheme.azulFuerte, size: 30),
          title: Text(
            titulo,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: AppTheme.acentoBlanco,
            ),
          ),
          subtitle: Text(
            subtitulo,
            style: GoogleFonts.montserrat(color: AppTheme.grisClaro),
          ),
        ),
      ),
    );
  }
}
