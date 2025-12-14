// Archivo - lib/features/admin/presentation/admin_flota_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../../app/app_theme.dart';
import '../data/admin_repository.dart';
// Gestiona la visualización centralizada de las métricas operativas y el estado actual de la flota de transporte
class AdminFlotaPage extends StatefulWidget {
  const AdminFlotaPage({super.key});

  @override
  State<AdminFlotaPage> createState() => _AdminFlotaPageState();
}

class _AdminFlotaPageState extends State<AdminFlotaPage> {
  final AdminRepository _repositorio = AdminRepository();
  late Future<Map<String, int>> _estadisticasFuture;

  @override
  void initState() {
    super.initState();
    // Inicia la recuperación de los indicadores clave al cargar la pantalla
    _estadisticasFuture = _cargarEstadisticas();
  }
  // Recopila y consolida en tiempo real los datos cuantitativos desde la base de datos para generar el reporte
  Future<Map<String, int>> _cargarEstadisticas() async {
    try {
      final resultados = await Future.wait([
        _repositorio.getNumeroRutas(),
        _repositorio.getNumeroConductoresActivos(),
        _repositorio.getNumeroConductoresReserva(),
        _repositorio.getNumeroTotalEstudiantes(),
        _repositorio.getNumeroTotalRepresentantes(),
      ]);

      return {
        'rutas': resultados[0],
        'conductoresActivos': resultados[1],
        'conductoresReserva': resultados[2],
        'estudiantes': resultados[3],
        'representantes': resultados[4],
      };
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      throw Exception('No se pudieron cargar las estadísticas');
    }
  }
  // Construye la estructura visual de la interfaz organizando títulos, gráficos y paneles informativos
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muestra el encabezado principal de la sección administrativa
          Text(
            "Función: Gestión y Monitoreo de Flota",
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.negroPrincipal,
            ),
          ),
          const SizedBox(height: 20),
          // Integración de elementos gráficos animados para mejorar la experiencia visual del usuario
          Center(
            child: Lottie.asset(
              'assets/animations/administrador_animacion.json',
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 25),

          _SectionTitle(title: "Descripción General"),
          _SectionContent(
            text:
                "Esta sección proporciona una vista general del estado operativo del sistema. Aquí puede monitorear las métricas clave de la flota y el personal en tiempo real.",
          ),
          const SizedBox(height: 25),

          _SectionTitle(title: "Estadísticas del Sistema"),
          const SizedBox(height: 15),
          // Gestión de los estados de espera y presentación de datos provenientes del servidor
          FutureBuilder<Map<String, int>>(
            future: _estadisticasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar datos: ${snapshot.error}',
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                );
              }
              if (snapshot.hasData) {
                final datos = snapshot.data!;
                return _buildGridViewEstadisticas(datos);
              }
              return const Center(child: Text('No hay datos.'));
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  // Organización de los indicadores numéricos en una cuadrícula adaptable para facilitar su lectura y comparación
  Widget _buildGridViewEstadisticas(Map<String, int> datos) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _TarjetaEstadistica(
          titulo: "Rutas Activas",
          numero: datos['rutas'] ?? 0,
          icono: FontAwesomeIcons.route,
          color: AppTheme.azulFuerte,
        ),
        _TarjetaEstadistica(
          titulo: "Estudiantes",
          numero: datos['estudiantes'] ?? 0,
          icono: FontAwesomeIcons.users,
          color: Colors.orange.shade600,
        ),
        _TarjetaEstadistica(
          titulo: "Conductores Activos",
          numero: datos['conductoresActivos'] ?? 0,
          icono: FontAwesomeIcons.userCheck,
          color: Colors.green.shade500,
        ),
        _TarjetaEstadistica(
          titulo: "Conductores Reserva",
          numero: datos['conductoresReserva'] ?? 0,
          icono: FontAwesomeIcons.userClock,
          color: AppTheme.tonoIntermedio,
        ),
        _TarjetaEstadistica(
          titulo: "Representantes",
          numero: datos['representantes'] ?? 0,
          icono: FontAwesomeIcons.userShield,
          color: Colors.blue.shade500,
        ),
      ],
    );
  }
}

// Widgets auxiliares
class _TarjetaEstadistica extends StatefulWidget {
  final String titulo;
  final int numero;
  final IconData icono;
  final Color color;

  const _TarjetaEstadistica({
    required this.titulo,
    required this.numero,
    required this.icono,
    required this.color,
  });

  @override
  State<_TarjetaEstadistica> createState() => _TarjetaEstadisticaState();
}

class _TarjetaEstadisticaState extends State<_TarjetaEstadistica> {
  bool _hover = false;
  // Controla la interactividad y los efectos de elevación visual al pasar el cursor sobre la tarjeta
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.secundario,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hover
                  ? Colors.black.withOpacity(0.25)
                  : Colors.black.withOpacity(0.1),
              blurRadius: _hover ? 15 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renderiza el ícono representativo dentro de un contenedor circular con transparencia
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: FaIcon(widget.icono, color: widget.color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.numero.toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.titulo,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// Estandariza la tipografía y el estilo de los encabezados de sección para mantener la coherencia visual
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: AppTheme.azulFuerte,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
// Renderiza el texto de una sección aplicando el estilo Montserrat y formato uniforme
class _SectionContent extends StatelessWidget {
  final String text;
  const _SectionContent({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: AppTheme.negroPrincipal.withOpacity(0.7),
        height: 1.5,
        fontSize: 15,
      ),
    );
  }
}

