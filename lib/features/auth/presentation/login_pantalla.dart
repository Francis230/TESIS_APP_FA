// Archivo - lib/features/auth/presentation/login_pantalla.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // 🚀 1. Importar Lottie
import '../../../core/widgets/boton_principal.dart'; // (No se usa aquí, pero lo mantenemos por si acaso)
import '../../../core/utils/validadores.dart';
import '../data/auth_repository.dart';
import '../../../app/app_theme.dart';
import 'package:tesis_appmovilfaj/servicios/notificaciones_servicio.dart';
import 'package:tesis_appmovilfaj/core/widgets/seleccion_rol_dialog.dart';

// Gestión de la interfaz de inicio de sesión, validación de credenciales y redirección de usuarios según su rol
class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _repositorio = AuthRepository();

  bool _cargando = false;
  // Controla la visibilidad de la contraseña en el campo de texto.
  bool _mostrarClave = false;
  // Despliega una ventana emergente visual para informar sobre fallos en la autenticación
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
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 50,
          ),
        ),
        title: Text(
          "Error al Iniciar Sesión",
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Aceptar',
              style: GoogleFonts.montserrat(color: AppTheme.azulFuerte),
            ),
          ),
        ],
      ),
    );
  }
  // Traducción de códigos de errores a mensajes aceptables
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();

    print("Error original: $errorStr"); 

    if (errorStr.contains('invalid-credential') ||
        errorStr.contains('wrong-password') ||
        errorStr.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos. Por favor, verifica tus datos.';
    }

    if (errorStr.contains('user-not-found') ||
        errorStr.contains('no user found')) {
      return 'No se encontró un usuario con ese correo electrónico.';
    }

    if (errorStr.contains('network request failed') ||
        errorStr.contains('network-request-failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }

    // Error por defecto si no lo reconocemos
    return 'Ocurrió un error inesperado. Inténtalo de nuevo más tarde.';
  }
  // Ejecución de la validación de credenciales y redirige al usuario al módulo correspondiente a su perfil
  Future<void> _hacerLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final usuario = await _repositorio.iniciarSesion(
        _correoCtrl.text.trim(),
        _claveCtrl.text.trim(),
      );

      final perfil = await _repositorio.obtenerPerfilPorId(usuario.id);

      if (perfil == null) {
        await _mostrarDialogoError(
          'Perfil no encontrado. Contacte al administrador.',
        );
        setState(() => _cargando = false);
        return;
      }

      // Registra el dispositivo para recibir notificaciones push personalizadas
      await NotificacionesServicio.inicializarYGuardarToken();

      // Redirige obligatoriamente al cambio de contraseña si es el primer acceso
      if (perfil['debe_cambiar_clave'] == true) {
        GoRouter.of(context).go('/clave-temporal-obligatoria');
        setState(() => _cargando = false);
        return;
      }

      final rolId = perfil['rol_id'];
      final nombreRol = await _repositorio.obtenerNombreRolPorId(rolId ?? '');
      // Verifica roles múltiples para administradores que también son conductores
      if (nombreRol == 'administrador') {
        
        // Preguntamos a la BD si ya es conductor activo
        final tienePerfilConductor = await _repositorio.esConductorActivo(usuario.id);

        if (!tienePerfilConductor) {
          // CASO A: Solo es Admin y está desactivado como conductor
          if (mounted) GoRouter.of(context).go('/admin');
        
        } else {
          // CASO B: Tiene los dos roles activos
          if (!mounted) return;
          // Permite al usuario con doble rol elegir con qué perfil desea ingresar
          final opcion = await showDialog<String>(
            context: context,
            barrierDismissible: false, 
            builder: (ctx) => const SeleccionRolDialog(),
          );

          if (opcion == null) {
            setState(() => _cargando = false);
            return;
          }
          // Redirección estándar para conductores y representantes
          if (opcion == 'conductor') {
            if (mounted) GoRouter.of(context).go('/conductor');
          } else {
            if (mounted) GoRouter.of(context).go('/admin');
          }
        }
        setState(() => _cargando = false);
        return;
      }
      if (nombreRol == 'conductor') {
        GoRouter.of(context).go('/conductor');
      } else {
        GoRouter.of(context).go('/representante');
      }
    } catch (e) {
      await _mostrarDialogoError(_traducirError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
  // Construcción la interfaz gráfica con el formulario de acceso y opciones de recuperación
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double cardRadius = 50; 
    const double buttonRadius = 25; 

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro, 
      body: Stack(
        children: [
          // Panel superior de color con botón de retorno
          Container(
            height: size.height * 0.30,
            width: double.infinity,
            color: AppTheme.azulFuerte,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => GoRouter.of(context).go('/inicio'),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        "Bienvenido de Nuevo",
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

          // Tarjeta contenedora del formulario de inicio de sesión
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.75,
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
                        "Iniciar Sesión",
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.negroPrincipal,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Campo para ingresar el correo electrónico
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          labelStyle: TextStyle(
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          hintText: 'Ingresa tu correo',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppTheme.tonoIntermedio,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
                        ),
                        style: const TextStyle(color: AppTheme.negroPrincipal),
                        validator: Validadores.validarCorreo,
                      ),
                      const SizedBox(height: 20),

                      // Campo para ingresar la contraseña con opción de visualización
                      TextFormField(
                        controller: _claveCtrl,
                        obscureText: !_mostrarClave,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          hintText: 'Ingresa tu contraseña',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ).withOpacity(0.6),
                          ),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppTheme.tonoIntermedio,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarClave
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.tonoIntermedio,
                            ),
                            onPressed: () =>
                                setState(() => _mostrarClave = !_mostrarClave),
                          ),
                        ),
                        style: const TextStyle(color: AppTheme.negroPrincipal),
                        validator: Validadores.validarClave,
                      ),
                      const SizedBox(height: 12),

                      // Enlace para recuperar la contraseña olvidada
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => GoRouter.of(
                            context,
                          ).go('/solicitar-recuperacion'),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.montserrat(
                              color: AppTheme
                                  .azulFuerte, 
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botón principal para ejecutar la acción de inicio de sesión
                      ElevatedButton(
                        onPressed: _cargando
                            ? null
                            : _hacerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.azulFuerte,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              buttonRadius,
                            ), 
                          ),
                          disabledBackgroundColor: AppTheme.azulFuerte
                              .withOpacity(0.7),
                        ),
                        child: _cargando
                            // Estado de carga e icono 
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 35, 
                                    width: 35,
                                    child: Image.asset(
                                      "assets/animations/login/loding_bus.gif", 
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Ingresando...',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Ingresar',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}
