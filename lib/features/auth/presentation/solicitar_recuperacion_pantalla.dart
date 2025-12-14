// Archivo - lib/features/auth/presentation/solicitar_recuperacion_pantalla.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../app/app_theme.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/boton_principal.dart';
import '../data/auth_repository.dart';
// Gestión de la interfaz para que el usuario solicite el restablecimiento de su contraseña olvidada
class SolicitarRecuperacionPantalla extends StatefulWidget {
  const SolicitarRecuperacionPantalla({super.key});

  @override
  State<SolicitarRecuperacionPantalla> createState() => _SolicitarRecuperacionPantallaState();
}

class _SolicitarRecuperacionPantallaState extends State<SolicitarRecuperacionPantalla> {
  final _formKey = GlobalKey<FormState>();
  // Controla la captura del correo electrónico ingresado por el usuario
  final _correoCtrl = TextEditingController();
  final _repositorio = AuthRepository();
  bool _cargando = false;
  // Traduce los errores técnicos del servidor a mensajes comprensibles para el usuario
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original al solicitar código: $errorStr");

    if (errorStr.contains('user not found') || errorStr.contains('no user with this email')) {
      return 'No se encontró ninguna cuenta asociada a ese correo electrónico.';
    }
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Muestra una alerta visual estilizada para informar sobre problemas en la solicitud
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
  // Valida el correo ingresado y envía la petición de código de recuperación a Supabase
  Future<void> _solicitarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final correo = _correoCtrl.text.trim();

    try {
      await _repositorio.solicitarCodigoDeRecuperacion(correo);

      if (mounted) {
        // Redirige al usuario a la pantalla de verificación tras el envío exitoso
        context.go('/verificar-codigo', extra: correo);
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  void dispose() {
    // Libera los recursos de memoria del controlador de texto al cerrar la pantalla
    _correoCtrl.dispose();
    super.dispose();
  }
  // Construcción de la estructura visual de la pantalla con las instrucciones y el formulario de entrada
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.acentoBlanco),
          onPressed: () => context.go('/login'), 
        ),
        title: Text('Recuperar Contraseña', style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          color: AppTheme.acentoBlanco,
        )),
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Muestra una animación alusiva al envío de correos o seguridad
                  Lottie.asset(
                    'assets/animations/pre_login/code_login.json',
                    height: 180,
                    errorBuilder: (context, error, stackTrace) {
                       return Icon(Icons.mail_lock_outlined, size: 120, color: AppTheme.azulFuerte);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Recuperar Contraseña',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu correo. Te enviaremos un código de 6 dígitos para restablecer tu clave.',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.grisClaro, 
                      fontSize: 16
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Campo de entrada para el correo electrónico con validación
                  TextFormField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    cursorColor: AppTheme.acentoBlanco,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: GoogleFonts.montserrat(color: AppTheme.grisClaro),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.grisClaro, size: 20),
                      filled: true,
                      fillColor: AppTheme.secundario,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    ),
                    validator: Validadores.validarCorreo,
                  ),
                  const SizedBox(height: 32),
                  // Botón principal para iniciar el proceso de recuperación
                  BotonPrincipal(
                    texto: 'Enviar Código',
                    onPressed: _solicitarCodigo,
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
}