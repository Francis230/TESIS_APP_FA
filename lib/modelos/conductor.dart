// Archivo - lib/modelos/conductor.dart
// Modelo que representa a los conductores.
// Corresponde a la tabla "conductores" en Supabase.
// Define la estructura de datos para la gestión operativa de conductores y sus unidades de transporte
class Conductor {
  final String conductorId;
  final String? numeroRutaAsignada;
  final String? placaVehiculo;
  final String? marcaVehiculo;
  final String? modeloVehiculo;
  final String? colorVehiculo;
  final String? fotoVehiculoUrl;
  final double? latitudActual;
  final double? longitudActual;
  final bool compartiendoUbicacion;
  final String? licenciaConducir;
  final bool permisoActivo;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  // Instancia el objeto garantizando la integridad de los datos obligatorios y opcionales
  Conductor({
    required this.conductorId,
    this.numeroRutaAsignada,
    this.placaVehiculo,
    this.marcaVehiculo,
    this.modeloVehiculo,
    this.colorVehiculo,
    this.fotoVehiculoUrl,
    this.latitudActual,
    this.longitudActual,
    required this.compartiendoUbicacion,
    this.licenciaConducir,
    required this.permisoActivo,
    required this.creadoEn,
    required this.actualizadoEn,
  });
  // Convierte la respuesta JSON de la base de datos en un objeto manipulable por la aplicación
  factory Conductor.fromMap(Map<String, dynamic> map) {
    return Conductor(
      conductorId: map['conductor_id'] ?? '',
      numeroRutaAsignada: map['numero_ruta_asignada'],
      placaVehiculo: map['placa_vehiculo'],
      marcaVehiculo: map['marca_vehiculo'],
      modeloVehiculo: map['modelo_vehiculo'],
      colorVehiculo: map['color_vehiculo'],
      fotoVehiculoUrl: map['foto_vehiculo_url'],
      latitudActual: map['latitud_actual'] != null ? (map['latitud_actual'] as num).toDouble() : null,
      longitudActual: map['longitud_actual'] != null ? (map['longitud_actual'] as num).toDouble() : null,
      compartiendoUbicacion: map['compartiendo_ubicacion'] ?? false,
      licenciaConducir: map['licencia_conducir'],
      permisoActivo: map['permiso_activo'] ?? true,
      creadoEn: DateTime.parse(map['creado_en']),
      actualizadoEn: DateTime.parse(map['actualizado_en']),
    );
  }
  // Serializa la estructura del objeto a formato mapa para su envío o persistencia
  Map<String, dynamic> toMap() {
    return {
      'conductor_id': conductorId,
      'numero_ruta_asignada': numeroRutaAsignada,
      'placa_vehiculo': placaVehiculo,
      'marca_vehiculo': marcaVehiculo,
      'modelo_vehiculo': modeloVehiculo,
      'color_vehiculo': colorVehiculo,
      'foto_vehiculo_url': fotoVehiculoUrl,
      'latitud_actual': latitudActual,
      'longitud_actual': longitudActual,
      'compartiendo_ubicacion': compartiendoUbicacion,
      'licencia_conducir': licenciaConducir,
      'permiso_activo': permisoActivo,
      'creado_en': creadoEn.toIso8601String(),
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}
