// Archivo - lib/features/representante/presentation/mapa_bus.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
// Visualiza la ubicación en tiempo real del transporte escolar en un mapa interactivo para los representantes
class InicioTabRepresentante extends ConsumerStatefulWidget {
  const InicioTabRepresentante({super.key});

  @override
  ConsumerState<InicioTabRepresentante> createState() =>
      _InicioTabRepresentanteState();
}

class _InicioTabRepresentanteState
    extends ConsumerState<InicioTabRepresentante> {
  final Completer<GoogleMapController> _mapController = Completer();
  BitmapDescriptor _busIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    // Inicia la carga del recurso gráfico para el marcador del autobús
    _loadBusIcon();
  }
  // Prepara el icono personalizado del autobús para su representación visual en el mapa
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
  // Ajusta el enfoque de la cámara automáticamente siguiendo el movimiento del vehículo
  void _centrarCamara(LatLng posicion) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(posicion, 16.5));
  }
  // Construye la interfaz principal reaccionando a los cambios de ubicación en tiempo real
  @override
  Widget build(BuildContext context) {
    // Escuchamos el stream de la ubicación
    final ubicacionAsync = ref.watch(ubicacionStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
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
      // Gestiona los diferentes estados de la conexión (cargando, error, sin datos, activo)
      body: ubicacionAsync.when(
        data: (ubicacionData) {
          if (ubicacionData == null) {
            return _buildEstadoTarjeta(
                "Sin Conductor",
                "Tu estudiante no tiene un conductor asignado.",
                Icons.person_off_outlined);
          }

          final bool compartiendo =
              ubicacionData['compartiendo_ubicacion'] ?? false;
          if (!compartiendo) {
            return _buildEstadoTarjeta(
                "Recorrido no iniciado",
                "El conductor no está compartiendo su ubicación.",
                Icons.bus_alert);
          }

          final double lat =
              (ubicacionData['latitud_actual'] as num?)?.toDouble() ?? 0.0;
          final double lng =
              (ubicacionData['longitud_actual'] as num?)?.toDouble() ?? 0.0;
          final LatLng busPosicion = LatLng(lat, lng);

          // Centramos la cámara si la posición es válida
          if (lat != 0.0) {
            _centrarCamara(busPosicion);
          }

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

          return Stack(
            children: [
              // Renderiza el mapa de Google con la posición actualizada del transporte
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
               // Superpone una tarjeta informativa con detalles relevantes del viaje
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
  // Muestra un mensaje informativo cuando el rastreo no está disponible o el recorrido no ha iniciado
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
  // Despliega una notificación flotante sobre el mapa para alertar sobre la proximidad del bus
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
