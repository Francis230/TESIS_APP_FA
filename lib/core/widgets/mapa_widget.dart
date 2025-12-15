// Archivo - lib/core/widgets/mapa_widget.dart
import 'dart:async';
import 'dart:ui' as ui; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tesis_appmovilfaj/servicios/ubicacion_servicio.dart';
// Widget principal que muestra el mapa y gestiona el rastreo del bus en tiempo real
class MapaWidget extends StatefulWidget {
  final UbicacionServicio ubicacionServicio;

  const MapaWidget({
    super.key,
    required this.ubicacionServicio,
  });

  @override
  State<MapaWidget> createState() => _MapaWidgetState();
}

class _MapaWidgetState extends State<MapaWidget> {
  // Permite controlar la cámara y el movimiento del mapa visualmente
  final Completer<GoogleMapController> _controladorMapa = Completer();
  // Mantiene la conexión activa recibiendo datos del GPS constantemente
  StreamSubscription<Position>? _subscripcionPosicion;
  // Variables para gestionar la imagen y posición del bus en el mapa
  Marker? _marcadorBus;
  BitmapDescriptor? _iconoBus;
  // Configura dónde empieza la cámara antes de recibir la primera ubicación real
  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(-0.1924, -78.5085), 
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    // Prepara la imagen del bus y activa el rastreo al abrir la pantalla
    _cargarIconoPersonalizado();
    _iniciarEscuchaDeUbicacion();
  }

  @override
  void dispose() {
    // Detiene el uso del GPS al salir de la pantalla para ahorrar batería
    _subscripcionPosicion?.cancel();
    super.dispose();
  }

  // Gestión de la imagen
  // Prepara la imagen del bus ajustando su tamaño para que se vea bien en el mapa.
  Future<void> _cargarIconoPersonalizado() async {
    final iconoRedimensionado = await _obtenerIconoDeAssetRedimensionado('assets/images/bus_icon.png', 150);
    
    if (mounted) {
      setState(() {
        _iconoBus = iconoRedimensionado;
      });
    }
  }

  // Convierte el archivo de imagen original a un formato compatible con el mapa y reduce su tamaño
  Future<BitmapDescriptor> _obtenerIconoDeAssetRedimensionado(String rutaAsset, int ancho) async {
    final ByteData datos = await rootBundle.load(rutaAsset);
    final ui.Codec codec = await ui.instantiateImageCodec(
      datos.buffer.asUint8List(),
      targetWidth: ancho,
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteDataFinal = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteDataFinal!.buffer.asUint8List());
  }
  
  // Gestión de la ubicación
  // Conecta la aplicación con el servicio de GPS para reaccionar a cada movimiento
  void _iniciarEscuchaDeUbicacion() {
    _subscripcionPosicion = widget.ubicacionServicio.positionStream.listen((Position posicion) {
      if (mounted) {
        _actualizarMarcadorYCamara(posicion);
      }
    });
  }

  // Variable para recordar hacia dónde miraba el bus por última vez
  double _ultimaRotacionConocida = 0.0;
  void _actualizarMarcadorYCamara(Position posicion) async {
    final nuevaPosicion = LatLng(posicion.latitude, posicion.longitude);
    // Calcula la rotación del bus solo si está en movimiento para evitar giros erráticos
    // if (posicion.speed * 3.6 > 3) {
    //   _ultimaRotacionConocida = posicion.heading;
    // }
    // Dibuja nuevamente el marcador del bus en la nueva coordenada
    setState(() {
      _marcadorBus = Marker(
        markerId: const MarkerId('bus_marker'),
        position: nuevaPosicion,
        icon: _iconoBus ?? BitmapDescriptor.defaultMarker,
        // rotation: _ultimaRotacionConocida,
        // flat: true,
        anchor: const Offset(0.5, 0.5),
      );
    });
    // Mueve la cámara siguiendo al bus con una animación fluida
    final GoogleMapController controller = await _controladorMapa.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: nuevaPosicion, zoom: 16.5, tilt: 30.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Renderiza el mapa de Google en la pantalla con los marcadores actuales
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _posicionInicial,
      onMapCreated: (GoogleMapController controller) {
        _controladorMapa.complete(controller);
      },
      markers: _marcadorBus != null ? {_marcadorBus!} : {},
      myLocationButtonEnabled: false,
    );
  }
}