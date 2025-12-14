// Archivo - lib/features/conductor/presentation/conductor_home.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/app_theme.dart';
import 'tabs/alertas_tab.dart';
import 'tabs/inicio_tab.dart';
import 'tabs/estudiantes_tab.dart';
import 'tabs/perfil_tab.dart';
import '../../notificaciones/presentation/lista_notificaciones.dart';
// Configuración la estructura de navegación principal y el acceso a las funcionalidades del conductor
class ConductorHome extends StatefulWidget {
  const ConductorHome({super.key});

  @override
  State<ConductorHome> createState() => _ConductorHomeState();
}

class _ConductorHomeState extends State<ConductorHome> {
  int _selectedIndex = 0;
  // Centraliza las vistas principales disponibles para la gestión operativa del transporte
  static final List<Widget> _pages = <Widget>[
    const InicioTab(),
    const EstudiantesTab(),
    const AlertasTab(),
    const PerfilTab(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);
  // Organiza el diseño visual integrando la barra de navegación y el contenido dinámico
  @override
  Widget build(BuildContext context) {
    // Mantiene el estado de las pestañas activas para evitar recargas innecesarias
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // Provee un botón de acción rápida para el control de asistencia inmediato
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/conductor/asistencia'),
        backgroundColor: AppTheme.fondoClaro,
        foregroundColor: AppTheme.negroPrincipal,
        elevation: 4.0,
        child: const FaIcon(FontAwesomeIcons.listCheck),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Despliega el menú inferior con diseño ergonómico para la alternancia entre módulos
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10), // margen para efecto flotante
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0), // Fondo negro
          borderRadius: BorderRadius.circular(30), // Bordes redondeados
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomAppBar(
            color: Colors
                .transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            elevation: 0,
            child: SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildNavItem(
                    icon: FontAwesomeIcons.house,
                    index: 0,
                    label: 'Inicio',
                  ),
                  _buildNavItem(
                    icon: FontAwesomeIcons.users,
                    index: 1,
                    label: 'Lista Est',
                  ),
                  const SizedBox(width: 48),
                  _buildNavItem(
                    icon: FontAwesomeIcons.solidBell,
                    index: 2,
                    label: 'Alertas',
                  ),
                  _buildNavItem(
                    icon: FontAwesomeIcons.solidUser,
                    index: 3,
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Genera los iconos de navegación con retroalimentación visual del estado activo
  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.acentoBlanco : AppTheme.grisClaro;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            // Indicador visual inferior para resaltar la selección actual
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              width: isSelected ? 16 : 5,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.acentoBlanco : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
