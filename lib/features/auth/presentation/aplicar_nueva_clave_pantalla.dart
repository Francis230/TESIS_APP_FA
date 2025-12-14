// Archivo - lib/features/auth/presentation/aplicar_nueva_clave_pantalla.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../app/app_theme.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/boton_principal.dart';
import '../data/auth_repository.dart';
// Gestión de la interfaz para validar el código de recuperación y establecer una nueva contraseña segura
class AplicarNuevaClavePantalla extends StatefulWidget {
  final String email;
  const AplicarNuevaClavePantalla({super.key, required this.email});

  @override
  State<AplicarNuevaClavePantalla> createState() => _AplicarNuevaClavePantallaState();
}
// Controladores para capturar el código numérico y las nuevas credenciales
class _AplicarNuevaClavePantallaState extends State<AplicarNuevaClavePantalla> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _confirmarClaveCtrl = TextEditingController();
  final _repositorio = AuthRepository();
  bool _cargando = false;
  bool _mostrarClave = true;
  bool _mostrarConfirmClave = true;

  // Funciones de errores para mostrar al ususario el tipo de error
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original al aplicar clave: $errorStr");

    if (errorStr.contains('invalid token') || errorStr.contains('token has invalid')) {
      return 'El código ingresado es incorrecto o ha expirado. Por favor, solicita uno nuevo.';
    }
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (errorStr.contains('weak password')) {
      return 'La contraseña es demasiado débil. Intenta con una más segura.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Despliega una ventana emergente para informar sobre fallos
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
  // Muestra una confirmación visual de éxito y redirige al usuario a la pantalla de inicio de sesión
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
                context.go('/login'); 
              },
              child: Text('Ir a Login', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
  // Ejecuta la validación del código y la actualización de la contraseña
  Future<void> _aplicarNuevaClave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      await _repositorio.verificarCodigoYActualizarClave(
        email: widget.email,
        token: _codigoCtrl.text.trim(),
        newPassword: _claveCtrl.text.trim(),
      );

      if (mounted) {
        await _mostrarDialogoExito(
          '¡Contraseña actualizada con éxito! Ahora puedes iniciar sesión.'
        );
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
  // Libera los recursos de los controladores de texto al cerrar la pantalla
  @override
  void dispose() {
    _codigoCtrl.dispose();
    _claveCtrl.dispose();
    _confirmarClaveCtrl.dispose();
    super.dispose();
  }
  // Construcción de la interfaz con los campos de entrada y botones de acción
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: Text('Establecer Nueva Clave', style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          color: AppTheme.acentoBlanco,
        )),
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.acentoBlanco),
          onPressed: () => context.pop(), 
        ),
        iconTheme: const IconThemeData(color: AppTheme.acentoBlanco),
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
                    'assets/animations/pre_login/newpass_login.json', 
                    height: 180,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Revisa tu Correo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos un código de 6 dígitos a:\n${widget.email}',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.grisClaro, 
                      fontSize: 16
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Campo para ingresar el código de verificación numérico
                  TextFormField(
                    controller: _codigoCtrl,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 22, 
                      letterSpacing: 10, 
                    ),
                    cursorColor: AppTheme.acentoBlanco,
                    textAlign: TextAlign.center, 
                    decoration: _inputDecoration(
                      label: 'Código de 6 dígitos',
                      icon: Icons.pin_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6, 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                    validator: (v) => v == null || v.length != 6 ? 'El código debe tener 6 dígitos' : null,
                  ),
                  const SizedBox(height: 16),
                  // Campo para ingresar la nueva contraseña
                  TextFormField(
                    controller: _claveCtrl,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    cursorColor: AppTheme.acentoBlanco,
                    decoration: _inputDecoration(
                      label: 'Nueva Contraseña',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarClave ? Icons.visibility_off : Icons.visibility, color: AppTheme.grisClaro),
                        onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                      ),
                    ),
                    obscureText: _mostrarClave,
                    validator: Validadores.validarClave,
                  ),
                  const SizedBox(height: 16),
                  // Campo para confirmar la nueva contraseña y evitar errores de escritura
                  TextFormField(
                    controller: _confirmarClaveCtrl,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    cursorColor: AppTheme.acentoBlanco,
                    decoration: _inputDecoration(
                      label: 'Confirmar Nueva Contraseña',
                      icon: Icons.lock_clock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarConfirmClave ? Icons.visibility_off : Icons.visibility, color: AppTheme.grisClaro),
                        onPressed: () => setState(() => _mostrarConfirmClave = !_mostrarConfirmClave),
                      ),
                    ),
                    obscureText: _mostrarConfirmClave,
                    validator: (v) {
                      if (v != _claveCtrl.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  BotonPrincipal(
                    texto: 'Confirmar y Cambiar',
                    onPressed: _aplicarNuevaClave,
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

  // Configuración del estilo visual estandarizado para los campos del formulario
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
        borderSide: const BorderSide(color: AppTheme.azulFuerte, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}