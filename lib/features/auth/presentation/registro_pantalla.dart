// Archivo - lib/features/auth/presentation/registro_pantalla.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/utils/validadores.dart';
import '../data/auth_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/app_theme.dart';
// Gestión del formulario de inscripción para nuevos representantes en la plataforma
class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}
// Administra los campos de texto para capturar la información del usuario
class _RegistroPantallaState extends State<RegistroPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _confirmClaveCtrl = TextEditingController();
  final _parentescoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _repositorio = AuthRepository();

  bool _cargando = false;
  // Controla la visibilidad de la contraseña en los campos de seguridad
  bool _mostrarClave = false;
  bool _mostrarConfirmClave = false;

  @override
  void dispose() {
    // Libera recursos de memoria al cerrar la pantalla
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _claveCtrl.dispose();
    _confirmClaveCtrl.dispose();
    _parentescoCtrl.dispose();
    _cedulaCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }
  // Tradución de errores técnicos a mensajes amigables.
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original de registro: $errorStr");

    if (errorStr.contains('email already in use') || 
        errorStr.contains('user already exists')) {
      return 'Este correo electrónico ya está registrado. Por favor, inicia sesión.';
    }
    
    if (errorStr.contains('invalid-credential') || 
        errorStr.contains('wrong-password') ||
        errorStr.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  // Confirma la creación de la cuenta antes de redirigir al inicio de sesión
  Future<void> _mostrarDialogoError(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset(
          'assets/animations/bool/error.json', 
          height: 100,
          repeat: false,
        ),
        title: Text("Error en el Registro",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold)),
        content: Text(mensaje,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Aceptar',
                style: GoogleFonts.montserrat(color: AppTheme.azulFuerte)),
          )
        ],
      ),
    );
  }
  Future<void> _mostrarDialogoExito() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Lottie.asset(
            'assets/animations/bool/correct.json', 
            height: 100,
            repeat: false,
          ),
          title: Text('¡Registro Exitoso!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal,
              )),
          content: const Text(
            'Tu cuenta ha sido creada. Ahora serás redirigido para iniciar sesión.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
              },
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }
  // Valida la información y envía la solicitud de registro
  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      await _repositorio.registrarRepresentante(
        correo: _correoCtrl.text.trim(),
        clave: _claveCtrl.text.trim(),
        nombreCompleto: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        parentesco: _parentescoCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
      );

      // Si el registro fue exitoso y el widget todavía está montado...
      if (!mounted) return;
      await _mostrarDialogoExito();

      // Después de que el diálogo se cierray se redirige al login.
      if (mounted) {
        GoRouter.of(context).go('/login');
      }

    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogoError(_traducirError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
  // Estructura la interfaz visual con el formulario de datos y controles de navegación
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double cardRadius = 50;
    const double buttonRadius = 25;

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Container(
              height: size.height * 0.25,
              width: double.infinity,
              color: AppTheme.azulFuerte,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => GoRouter.of(context).go('/inicio'),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          "Crear Cuenta",
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tarjeta inferior que contiene el formulario de registro
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: size.height * 0.80,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(cardRadius),
                    topRight: Radius.circular(cardRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          "Registro Representante",
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.negroPrincipal,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildTextFormField(
                          controller: _nombreCtrl,
                          label: 'Nombre completo',
                          hintText: 'ej: Maria Peréz',
                          icon: Icons.person_outline,
                          validator: (v) => Validadores.validarTexto(v, 'Nombre'),
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _correoCtrl,
                          label: 'Correo',
                          hintText: 'ej: mariaperez@correo.com',
                          icon: Icons.email_outlined,
                          validator: Validadores.validarCorreo,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _telefonoCtrl,
                          label: 'Teléfono',
                          hintText: 'ej: 0912345678 (10 Digitos)',
                          icon: Icons.phone_outlined,
                          validator: Validadores.validarTelefono,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _parentescoCtrl,
                          label: 'Relación con el estudiante',
                          hintText: 'ej: Padre, Madre, Tío....',
                          icon: Icons.family_restroom_outlined,
                          validator: (v) => Validadores.validarTexto(v, 'Relación con el estudiante'),
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _cedulaCtrl,
                          label: 'Cédula',
                          hintText: 'ej: 1712345678 (10 Digitos)',
                          icon: Icons.badge_outlined,
                          validator: Validadores.validarIdentificacion,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _direccionCtrl,
                          label: 'Dirección',
                          hintText: 'ej: Av. Amazonas y América',
                          icon: Icons.location_on_outlined,
                          validator: (v) => Validadores.validarTexto(v, 'Dirección'),
                          keyboardType: TextInputType.streetAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordFormField(
                          controller: _claveCtrl,
                          label: 'Contraseña',
                          hintText: 'Mínimo 6 caracteres',
                          mostrarClave: _mostrarClave,
                          onPressedSuffix: () =>
                              setState(() => _mostrarClave = !_mostrarClave),
                          validator: Validadores.validarClave,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordFormField(
                          controller: _confirmClaveCtrl,
                          label: 'Confirmar contraseña',
                          hintText: 'Repite tu contraseña',
                          mostrarClave: _mostrarConfirmClave,
                          onPressedSuffix: () => setState(
                              () => _mostrarConfirmClave = !_mostrarConfirmClave),
                          validator: Validadores.validarClave,
                        ),
                        const SizedBox(height: 32),
                        // Botón de registro con estado de carga animado
                        ElevatedButton(
                          onPressed: _cargando ? null : _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.azulFuerte,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(buttonRadius),
                            ),
                          ),
                          child: _cargando
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 25, 
                                      width: 25,
                                      child: Image.asset(
                                        "assets/animations/login/loding_bus.gif", 
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Registrando...',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                )
                              : const Text(
                                  'Registrar',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                        TextButton(
                          onPressed: () => GoRouter.of(context).go('/login'),
                          child: Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: GoogleFonts.montserrat(
                              color: AppTheme.azulFuerte,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Configuración del diseño y validación de los campos de texto estándar
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6)),
        labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6)),
        fillColor: Colors.grey.shade100,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: AppTheme.tonoIntermedio),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      ),
      style: const TextStyle(color: AppTheme.negroPrincipal),
      validator: validator,
    );
  }
  // Configura los campos de contraseña con opción para mostrar u ocultar caracteres
  Widget _buildPasswordFormField({
    required TextEditingController controller,
    required String label,
    required bool mostrarClave,
    required VoidCallback onPressedSuffix,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !mostrarClave,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6)),
        labelStyle: TextStyle(color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6)),
        fillColor: Colors.grey.shade100,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.tonoIntermedio),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        suffixIcon: IconButton(
          icon: Icon(mostrarClave ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.tonoIntermedio),
          onPressed: onPressedSuffix,
        ),
      ),
      style: const TextStyle(color: AppTheme.negroPrincipal),
      validator: validator,
    );
  }
}

