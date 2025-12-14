// Archivo - lib/features/auth/presentation/cambio_clave_perfil.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../core/utils/validadores.dart';
import '../data/auth_repository.dart';
import '../../../app/app_theme.dart';
// Gestiona la interfaz que permite al usuario autenticado actualizar voluntariamente su contraseña de acceso
class CambioClavePerfil extends StatefulWidget {
  const CambioClavePerfil({super.key});

  @override
  State<CambioClavePerfil> createState() => _CambioClavePerfilState();
}

class _CambioClavePerfilState extends State<CambioClavePerfil> {
  final _formKey = GlobalKey<FormState>();
  final _claveCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _repositorio = AuthRepository();
  // visibilidad del texto en los campos de contraseña
  bool _cargando = false;
  bool _mostrarClave = true;
  bool _mostrarConfirmClave = true;

  @override
  void dispose() {
    _claveCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
  // Traduce los códigos de error a mensajes comprensibles
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
  // Despliega una alerta visual estilizada cuando la operación de cambio falla
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
  // Muestra una confirmación visual exitosa y facilita el retorno a la pantalla anterior
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
                context.pop(); 
              },
              child: Text('Aceptar', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
  // Valida las entradas y ejecuta la solicitud de actualización de credenciales
  Future<void> _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_claveCtrl.text.trim() != _confirmCtrl.text.trim()) {
      _mostrarDialogoError(
        'Las contraseñas no coinciden. Por favor, inténtalo de nuevo.',
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) throw Exception('No hay usuario autenticado');

      await _repositorio.cambiarClaveUsuario(_claveCtrl.text.trim());

      if (mounted) {
        await _mostrarDialogoExito(
          'Tu contraseña ha sido actualizada.',
        );
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
  // Construcción la interfaz gráfica con el formulario de cambio de contraseña.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: Text('Cambiar contraseña', style: GoogleFonts.montserrat()),
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
                    'assets/images/key_icon.json', // ⚠️ 
                    height: 250,
                    width: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.lock_reset, size: 150, color: AppTheme.azulFuerte);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Actualizar Contraseña',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu nueva contraseña segura.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.grisClaro,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _claveCtrl,
                    obscureText: _mostrarClave,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    cursorColor: AppTheme.acentoBlanco,
                    decoration: _inputDecoration(
                      label: 'Nueva contraseña',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarClave ? Icons.visibility_off : Icons.visibility, color: AppTheme.grisClaro),
                        onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                      ),
                    ),
                    validator: Validadores.validarClave,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _mostrarConfirmClave,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    cursorColor: AppTheme.acentoBlanco,
                    decoration: _inputDecoration(
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_clock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarConfirmClave ? Icons.visibility_off : Icons.visibility, color: AppTheme.grisClaro),
                        onPressed: () => setState(() => _mostrarConfirmClave = !_mostrarConfirmClave),
                      ),
                    ),
                    validator: (v) {
                       if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                       if (v != _claveCtrl.text) return 'Las contraseñas no coinciden';
                       return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  BotonPrincipal(
                      texto: 'Guardar Cambios',
                      onPressed: _cambiarClave,
                      cargando: _cargando),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Configuración del estilo visual de los campos de entrada de contraseña
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: AppTheme.grisClaro),
      prefixIcon: Icon(icon, color: AppTheme.grisClaro, size: 20),
      suffixIcon: suffixIcon,
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
    );
  }
}