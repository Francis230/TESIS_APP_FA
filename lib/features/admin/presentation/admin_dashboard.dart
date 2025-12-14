// Archivo - lib/features/admin/presentation/admin_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../app/app_theme.dart';
import 'admin_flota_page.dart';
import 'perfil_admin.dart';
import '../../auth/data/auth_repository.dart'; 

// Pantalla del admin dashboard pantalla principal
// Gestiona la estructura visual principal y la navegación del panel administrativo
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final AuthRepository _authRepo = AuthRepository(); 
  // Almacena temporalmente los datos del perfil para mostrarlos en la cabecera
  String _adminNombre = "Admin";
  String? _adminFotoUrl;

  @override
  void initState() {
    super.initState();
    // Inicia la carga de la información del usuario al abrir la pantalla
    _loadAdminData(); 
  }

  // Recupera la información actualizada del perfil desde la base de datos
  Future<void> _loadAdminData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final perfil = await _authRepo.obtenerPerfilPorId(user.id);
      if (perfil != null && mounted) {
        setState(() {
          _adminNombre = perfil['nombre_completo'] ?? 'Admin';
          _adminFotoUrl = perfil['foto_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos de admin para header: $e");
    }
  }

    // Define las opciones disponibles en el menú de navegación inferior
  final List<Map<String, dynamic>> _navigationItems = const [
    {'label': 'Inicio', 'icon': FontAwesomeIcons.house},
    {'label': 'Descripción Rol', 'icon': FontAwesomeIcons.truckFast},
    {'label': 'Perfil', 'icon': FontAwesomeIcons.solidUser},
  ];

   // Configura las vistas correspondientes a cada pestaña del menú
  late final List<Widget> _widgetOptions = <Widget>[
    _HomeContent(),
    const AdminFlotaPage(),
    PerfilAdminPage(
      onProfileUpdated: _loadAdminData,
    ),
  ];
  // Actualiza el índice seleccionado cuando el usuario toca una opción del menú
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Inicia el proceso de confirmación para salir de la cuenta de forma segura
  void _cerrarSesion(BuildContext context) {
    _mostrarDialogoConfirmarCierre(context);
  }
  // Muestra una ventana emergente para confirmar la intención de cerrar sesión
  Future<void> _mostrarDialogoConfirmarCierre(BuildContext context) async {
    final bool confirmar = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text("Cerrar Sesión", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
            content: Text("¿Estás seguro de que deseas cerrar sesión?", style: GoogleFonts.montserrat(color: Colors.black87)),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.azulFuerte,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Sí, cerrar', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ) ??
        false;

    if (confirmar && context.mounted) {
      try {
        // Llama al AuthRepository para cerrar sesión
        await _authRepo.signOut(); 
        if (context.mounted) {
          context.go('/login');
          _mostrarToastOscuro("Sesión cerrada exitosamente.");
        }
      } catch (e) {
        if (context.mounted) {
          await _mostrarDialogoError(_traducirError(e, "cerrar sesion"));
        }
      }
    }
  }
  // Redirige al usuario directamente a la pestaña de perfil
  void _goToProfile(BuildContext context) {
    _onItemTapped(2);
  }
  // Convierte los mensajes de error técnicos en texto amigable para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cerrar sesion") {
      return 'Error al intentar cerrar sesión.';
    }
    return 'Ocurrió un error inesperado.';
  }
  // Presenta una alerta visual en caso de fallos en el sistema
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
  // Muestra una notificación flotante temporal en la parte inferior
  void _mostrarToastOscuro(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.negroPrincipal,
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
                'assets/animations/bool/correct.json',
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
  // Construye la interfaz gráfica completa integrando navegación y contenido
  @override
  Widget build(BuildContext context) {
    final acentoColor = AppTheme.azulFuerte;
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == _selectedIndex;

                  return _buildNavItem(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    isSelected: isSelected,
                    onTap: () => _onItemTapped(index),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions.map((widget) {
            if (widget is _HomeContent) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Integra la cabecera personalizada con los datos del usuario
                    _DashboardHeader(
                      acentoColor: acentoColor,
                      goToProfile: () => _goToProfile(context),
                      cerrarSesion: () => _cerrarSesion(context),
                      nombre: _adminNombre, 
                      fotoUrl: _adminFotoUrl, 
                    ),
                    widget,
                  ],
                ),
              );
            }
            return widget;
          }).toList(),
        ),
      ),
    );
  }
  // Renderiza cada botón individual de la barra de navegación con efectos visuales
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppTheme.azulFuerte : AppTheme.negroPrincipal.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
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
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              width: isSelected ? 16 : 5,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.azulFuerte : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Widget del Header y Avatar 
// Muestra la sección superior con el saludo, nombre y controles de sesión
class _DashboardHeader extends StatelessWidget {
  final Color acentoColor;
  final VoidCallback goToProfile;
  final VoidCallback cerrarSesion;
  final String nombre; 
  final String? fotoUrl; 

  const _DashboardHeader({
    required this.acentoColor,
    required this.goToProfile,
    required this.cerrarSesion,
    required this.nombre,
    this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Muestra el avatar interactivo del usuario
              _AdminAvatar(
                onTap: goToProfile, 
                acentoColor: acentoColor, 
                fotoUrl: fotoUrl, 
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visualiza el nombre del administrador de forma destacada
                  Text("¡Hola, $nombre!", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
                  Text("Gestión del Sistema", style: GoogleFonts.montserrat(fontSize: 12, color: const Color.fromARGB(255, 0, 0, 0))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: cerrarSesion,
                icon: const FaIcon(FontAwesomeIcons.rightFromBracket, color: AppTheme.negroPrincipal, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// Renderiza la imagen de perfil circular o un icono genérico si no hay foto
class _AdminAvatar extends StatelessWidget {
  final VoidCallback onTap;
  final Color acentoColor;
  final String? fotoUrl; 

  const _AdminAvatar({
    required this.onTap, 
    required this.acentoColor, 
    this.fotoUrl
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.negroPrincipal, width: 2),
        ),
        // Carga la imagen desde la red o muestra un icono por defecto
        child: CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.secundario,
          backgroundImage: (fotoUrl != null && fotoUrl!.isNotEmpty)
              ? NetworkImage(fotoUrl!)
              : null,
          child: (fotoUrl == null || fotoUrl!.isEmpty)
              ? const FaIcon(FontAwesomeIcons.userLarge, size: 25, color: Colors.white) 
              : null,
        ),
      ),
    );
  }
}
// Contenido de la pestaña de inicio
// Agrupa los accesos directos y banners informativos de la pantalla principal
class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}
class _HomeContentState extends State<_HomeContent> {
  // Controla la visibilidad del banner informativo superior
  bool _mostrarAviso = true; 

  @override
  Widget build(BuildContext context) {
    final acentoColor = AppTheme.azulFuerte;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Muestra un aviso recordatorio que el usuario puede ocultar
        if (_mostrarAviso)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.negroPrincipal, 
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: FaIcon(FontAwesomeIcons.circleInfo, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "¿Rol de conductor?",
                        style: GoogleFonts.montserrat(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Puedes activar tu rol de conductor en la sección 'Perfil' cuando lo necesites.",
                        style: GoogleFonts.montserrat(
                          color: Colors.white70, 
                          fontSize: 12,
                          height: 1.3
                        ),
                      ),
                    ],
                  ),
                ),
                // Permite al usuario cerrar y descartar el aviso
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _mostrarAviso = false; // Oculta el banner
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

        // Visualiza la tarjeta descriptiva de las funciones del rol
        _RolDescriptionCard(acentoColor: acentoColor),

        const SizedBox(height: 30),

        Text(
          "Acciones Rápidas",
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.negroPrincipal,
          ),
        ),
        const SizedBox(height: 15),
        // Botón de acceso directo al formulario de registro de conductores
        _ActionCard(
          lottieAssetPath: 'assets/animations/admin/add_conduc.json',
          titulo: "Registrar Conductor",
          subtitulo: "Añadir un nuevo conductor al sistema",
          onTap: () => context.push('/admin/registrar-conductor'),
        ),
        const SizedBox(height: 15),
        // Botón de acceso directo al listado de conductores activos
        _ActionCard(
          lottieAssetPath: 'assets/animations/admin/list_conduc.json', 
          titulo: "Ver Conductores",
          subtitulo: "Listar y editar conductores activos",
          onTap: () => context.push('/admin/conductores'),
        ),
        const SizedBox(height: 15),
        // Botón de acceso directo a la gestión de rutas
        _ActionCard(
          lottieAssetPath: 'assets/animations/admin/rut_conduc.json',
          titulo: "Gestionar Rutas",
          subtitulo: "Crear, editar o eliminar rutas",
          onTap: () => context.push('/admin/rutas'),
        ),
        
        const SizedBox(height: 30),
      ],
    );
  }
}
// Muestra información estática sobre las responsabilidades del administrador
class _RolDescriptionCard extends StatelessWidget {
    final Color acentoColor;
  const _RolDescriptionCard({
    required this.acentoColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secundario, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rol: Administrador de Flota",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white38, height: 20),
          Text(
            "Descripción y Responsabilidades:",
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Usted gestiona la operación completa de la flota escolar: asignación de rutas, monitoreo de conductores y vehículos, y es el punto clave para la coordinación de la seguridad y eficiencia del transporte.",
            style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
// Representa un botón de acción interactivo con animación Lottie incorporada
class _ActionCard extends StatefulWidget {
  final String lottieAssetPath; 
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _ActionCard({
    required this.lottieAssetPath,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> with TickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Configura el controlador para gestionar la reproducción de la animación
    _controller = AnimationController(vsync: this);
    // Programa la repetición periódica de la animación para atraer la atención
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });

    _controller.addStatusListener((status) {
       if (status == AnimationStatus.completed) {
       }
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
    return Material(
      color: AppTheme.secundario, 
      borderRadius: BorderRadius.circular(15),
      elevation: 0,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Lottie.asset(
                  widget.lottieAssetPath,
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _controller.stop();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitulo,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.chevronRight, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
