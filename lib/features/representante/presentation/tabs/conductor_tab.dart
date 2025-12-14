// Archivo - lib/features/representante/presentation/tabs/conductor_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- IMPORTANTE: Para la funcionalidad de llamar
// Visualización de la información detallada del conductor asignado y los datos del vehículo de transporte
class ConductorTab extends ConsumerWidget {
  const ConductorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtiene los datos del conductor de forma asíncrona mediante el gestor de estado
    final dataAsync = ref.watch(datosConductorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información del Conductor',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppTheme.acentoBlanco,
          ),
        ),
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0, 
      ),
      backgroundColor: AppTheme.negroPrincipal,
      // Gestiona los estados de carga, error y visualización de la información del conductor
      body: dataAsync.when(
        data: (data) {
          // No hay datos 
          if (data == null) {
            return _buildEstadoMensaje(
                "Sin conductor asignado",
                "Tu estudiante aún no tiene un conductor asignado a su ruta.",
                FontAwesomeIcons.userSlash); 
          }

          // Extraemos los datos con seguridad, verificando si son Mapas
          final conductorData = data; // Datos de la tabla 'conductores'
          final perfilData = (data['perfil'] is Map<String, dynamic>)
                              ? data['perfil'] as Map<String, dynamic>
                              : null; // Datos de la tabla 'perfiles' puede ser null
          final rutaData = (data['ruta'] is Map<String, dynamic>)
                            ? data['ruta'] as Map<String, dynamic>
                            : null; // Datos de la tabla 'rutas' puede ser null

          // Falta información esencial del perfil
          if (perfilData == null) {
            return _buildEstadoMensaje(
                "Datos incompletos",
                "No se pudo cargar la información completa del perfil del conductor.",
                FontAwesomeIcons.triangleExclamation); 
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildTarjetaConductor(perfilData, rutaData), 
              const SizedBox(height: 16),
              _buildTarjetaVehiculo(conductorData), 
               const SizedBox(height: 16),
              _buildTarjetaContacto(context, perfilData), 
            ],
          );
        },
        // Cargando datos
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
        // Error al cargar
        error: (err, stack) => _buildEstadoMensaje( 
            "Error al cargar", err.toString(), FontAwesomeIcons.cloud), 
      ),
    );
  }
  // Renderiza la tarjeta principal con la identidad del conductor y la ruta asignada
  Widget _buildTarjetaConductor(Map<String, dynamic> perfil, Map<String, dynamic>? ruta) {
    final fotoUrl = perfil['foto_url'] as String?;
    final nombre = perfil['nombre_completo'] ?? 'Nombre no disponible';
    final numeroRuta = ruta?['numero_ruta'] ?? 'N/A'; 
    final sectorRuta = ruta?['sector'] ?? 'N/A';     

    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.grisClaro.withOpacity(0.5), 
              backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                  ? NetworkImage(fotoUrl)
                  : null,
              child: (fotoUrl == null || fotoUrl.isEmpty)
                  ? const FaIcon(FontAwesomeIcons.userTie, size: 50, color: AppTheme.tonoIntermedio,) 
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              nombre,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal, 
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container( // Contenedor para la ruta
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: AppTheme.azulFuerte.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(30),
               ),
              child: Text(
                "Ruta: $numeroRuta ($sectorRuta)",
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: AppTheme.azulFuerte,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Muestra los detalles técnicos y visuales del vehículo para su identificación
  Widget _buildTarjetaVehiculo(Map<String, dynamic> conductor) {
    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Información del Vehículo",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal,
              ),
            ),
            const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5), 
            _buildInfoRow(FontAwesomeIcons.hashtag, "Placa:", conductor['placa_vehiculo']),
            _buildInfoRow(FontAwesomeIcons.solidBuilding, "Marca:", conductor['marca_vehiculo']),
            _buildInfoRow(FontAwesomeIcons.car, "Modelo:", conductor['modelo_vehiculo']),
            _buildInfoRow(FontAwesomeIcons.palette, "Color:", conductor['color_vehiculo']),
          ],
        ),
      ),
    );
  }
  // Agrupa las opciones de contacto directo con el conductor llamada y correo
  Widget _buildTarjetaContacto(BuildContext context, Map<String, dynamic> perfil) {
    final telefono = perfil['telefono'] as String?;
    final correo = perfil['correo'] as String?; 

    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contacto",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal,
              ),
            ),
            const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5),
            _buildCopiableInfoRow(
              context: context,
              icon: FontAwesomeIcons.phone,
              label: "Teléfono",
              value: telefono,
              onCopy: () { 
                Clipboard.setData(ClipboardData(text: telefono ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teléfono copiado al portapapeles')),
                );
              },
            ),
            const SizedBox(height: 16), 
             _buildCopiableInfoRow(
              context: context,
              icon: FontAwesomeIcons.solidEnvelope,
              label: "Correo",
              value: correo,
              onCopy: () { // Lógica para copiar
                Clipboard.setData(ClipboardData(text: correo ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Correo copiado al portapapeles')),
                );
              },
            ),
            
            const Divider(color: AppTheme.grisClaro, height: 30, thickness: 0.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.negroPrincipal,
                  foregroundColor: AppTheme.acentoBlanco, 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: const FaIcon(FontAwesomeIcons.phoneVolume, size: 18),
                label: Text(
                  'Llamar al Conductor',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: (telefono != null && telefono.isNotEmpty) ? () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: telefono);
                  if (await canLaunchUrl(launchUri)) {
                    await launchUrl(launchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo llamar al número $telefono')),
                    );
                  }
                } : null, // Deshabilitar si no hay teléfono
              ),
            ),

          ],
        ),
      ),
    );
  }
  // Estructura una fila de datos simple para mostrar atributos del vehículo
  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    final String displayValue = (value != null && value.toString().isNotEmpty) ? value.toString() : 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: AppTheme.tonoIntermedio, size: 18), 
          const SizedBox(width: 16),
          Text(
            "$label ",
            style: GoogleFonts.montserrat(
              color: AppTheme.tonoIntermedio, 
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: GoogleFonts.montserrat(
                color: AppTheme.negroPrincipal, 
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Crea una fila de información interactiva que permite copiar el contenido al portapapeles
  Widget _buildCopiableInfoRow({
     required BuildContext context,
     required IconData icon,
     required String label,
     required String? value,
     required VoidCallback onCopy
  }) {
    final String displayValue = (value != null && value.isNotEmpty) ? value : 'N/A';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
           label,
           style: GoogleFonts.montserrat(
             color: AppTheme.tonoIntermedio, 
             fontSize: 14,
           ),
         ),
         const SizedBox(height: 4),
         // Valor y botón
         Row(
           children: [
             FaIcon(icon, color: AppTheme.negroPrincipal, size: 20), 
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 displayValue,
                 style: GoogleFonts.montserrat(
                   color: AppTheme.negroPrincipal, 
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
             IconButton(
               icon: const FaIcon(FontAwesomeIcons.copy, size: 20, color: AppTheme.tonoIntermedio),
               tooltip: 'Copiar $label',
               onPressed: (value != null && value.isNotEmpty) ? onCopy : null, // Deshabilita si no hay nada que copiar
             ),
           ],
         ),
      ],
    );
  }
  // Muestra mensajes informativos estandarizados para estados vacíos o de error
  Widget _buildEstadoMensaje(String titulo, String subtitulo, IconData icono) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        decoration: BoxDecoration(
          color: AppTheme.fondoClaro,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.grisClaro.withOpacity(0.5)),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icono, size: 50, color: AppTheme.tonoIntermedio), 
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
    );
  }
}