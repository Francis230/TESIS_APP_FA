// Archivo - lib/features/auth/presentation/clave_temporal_obligatoria.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:lottie/lottie.dart'; 
import '../../../core/widgets/boton_principal.dart';
import '../../../core/utils/validadores.dart';
import '../data/auth_repository.dart';
import '../../../app/app_theme.dart';
// Gestiona el cambio obligatorio de contraseña temporal
class ClaveTemporalObligatoriaPantalla extends StatefulWidget {
  const ClaveTemporalObligatoriaPantalla({super.key});

  @override
  State<ClaveTemporalObligatoriaPantalla> createState() =>
      _ClaveTemporalObligatoriaPantallaState();
}

class _ClaveTemporalObligatoriaPantallaState
    extends State<ClaveTemporalObligatoriaPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _claveCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _repositorio = AuthRepository();

  bool _cargando = false;
  bool _mostrarClave = true; 
  bool _mostrarConfirmClave = true; 

  @override
  void dispose() {
    _claveCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
  // Traduce los códigos de error técnicos a explicaciones sencillas para el usuario
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original al cambiar clave: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (errorStr.contains('weak password')) {
      return 'La contraseña es demasiado débil. Intenta con una más segura.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Muestra una alerta visual cuando ocurre un problema durante la actualización
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
  // Despliega una confirmación visual cuando la contraseña se actualiza correctamente
  Future<void> _mostrarDialogoExito(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Lottie.asset('assets/animations/bool/correct.json', height: 100, repeat: false),
          title: Text('¡Éxito!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text(mensaje, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                // La redirección al login se hace en _cambiarClave
              },
              child: Text('Aceptar', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
  // Muestra un mensaje flotante temporal en la pantalla de inicio de sesión
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
          bottom: MediaQuery.of(context).size.height / 2 - 50,
          left: 24,
          right: 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // Valida, actualiza la contraseña en el sistema y fuerza un nuevo inicio de sesión
  Future<void> _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_claveCtrl.text.trim() != _confirmCtrl.text.trim()) {
      await _mostrarDialogoError(
        'Las contraseñas no coinciden. Por favor, inténtalo de nuevo.',
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) throw Exception('No hay usuario autenticado');

      await _repositorio.cambiarClaveUsuario(_claveCtrl.text.trim());
      await _repositorio.actualizarFlagCambioClave(usuario.id, false);

      if (mounted) {
        await _mostrarDialogoExito(
          'Tu contraseña ha sido actualizada. Por favor, inicia sesión de nuevo.',
        );
        
        // Cierra la sesión actual para obligar al usuario a entrar con la nueva clave
        await _repositorio.signOut();
        
        if (mounted) {
          GoRouter.of(context).go('/login');
          _mostrarToastOscuro("¡Listo! Inicia sesión.");
        }
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(
          _traducirError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
  // Construcción de la interfaz gráfica con el formulario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: Text('Establecer Contraseña', style: GoogleFonts.montserrat()),
        // No permite retroceder
        automaticallyImplyLeading: false, 
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Lottie.asset(
                    'assets/animations/bool/alert_pass.json',
                    height: 120,
                    width: 120,
                    repeat: false, 
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Actualización Requerida', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Debe establecer una nueva contraseña por seguridad para continuar.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.grisClaro,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campos de la contraseña
                  _buildPasswordField(
                    controller: _claveCtrl,
                    label: 'Nueva contraseña',
                    validator: Validadores.validarClave,
                    mostrarOcultar: _mostrarClave,
                    onToggleVisibility: () => setState(() => _mostrarClave = !_mostrarClave),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _confirmCtrl,
                    label: 'Confirmar contraseña',
                    validator: (v) {
                       if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                       if (v != _claveCtrl.text) return 'Las contraseñas no coinciden';
                       return null;
                    },
                    mostrarOcultar: _mostrarConfirmClave,
                    onToggleVisibility: () => setState(() => _mostrarConfirmClave = !_mostrarConfirmClave),
                  ),
                  const SizedBox(height: 32),
                  BotonPrincipal(
                    texto: 'Guardar y Continuar',
                    onPressed: _cambiarClave,
                    cargando: _cargando,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Configura el diseño y comportamiento de los campos de entrada de contraseña
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool mostrarOcultar,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: mostrarOcultar,
      style: GoogleFonts.montserrat(color: Colors.white),
      cursorColor: AppTheme.acentoBlanco,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: AppTheme.grisClaro),
        prefixIcon: const Icon(Icons.lock, color: AppTheme.grisClaro, size: 20),
        suffixIcon: IconButton(
          icon: Icon(mostrarOcultar ? Icons.visibility_off : Icons.visibility, color: AppTheme.grisClaro),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: AppTheme.secundario,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.tonoIntermedio),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.azulFuerte),
        ),
      ),
      validator: validator,
    );
  }
}
