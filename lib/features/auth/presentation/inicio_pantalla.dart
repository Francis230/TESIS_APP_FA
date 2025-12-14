// Archivo - lib/features/auth/presentation/inicio_pantalla.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
// Gestión de la pantalla de bienvenida y el punto de entrada principal para usuarios no autenticados
class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtiene las dimensiones actuales del dispositivo para el diseño responsivo
    final size = MediaQuery.of(context).size;
    const double buttonRadius = 25;
    // Calcula la posición vertical estratégica para el logotipo institucional
    final double logoPositionTop = size.height * 0.20;

    return Scaffold(
      // Organiza los elementos visuales en capas superpuestas
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Renderiza la imagen de fondo cubriendo toda la superficie de la pantalla
          Image.asset(
            "assets/images/inicio/background_inicio.png", 
            fit: BoxFit.cover,
          ),
          // Estructura el panel inferior interactivo con bordes redondeados y sombra
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.45,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 40), 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Presenta el título de bienvenida destacado al usuario
                  Text(
                    "Bienvenido",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.azulFuerte, 
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Muestra las instrucciones breves para continuar en la aplicación
                  Text(
                    "Inicia sesión o regístrate para continuar.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Usamos Spacer para empujar los botones al fondo de la tarjeta
                  const Spacer(),

                  // Habilitación la navegación hacia la pantalla de inicio de sesión
                  ElevatedButton(
                    onPressed: () => GoRouter.of(context).go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.azulFuerte,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                    ),
                    child: const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Habilita la navegación hacia el formulario de registro de nuevos usuarios
                  OutlinedButton(
                    onPressed: () => GoRouter.of(context).go('/registro'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.azulFuerte, width: 2),
                      foregroundColor: AppTheme.azulFuerte,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonRadius),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("Registrarse"),
                  ),
                ],
              ),
            ),
          ),
          // Posició del logotipo y el nombre de la institución sobre las demás capas
          Positioned(
            top: logoPositionTop,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Creación del contenedor circular con sombra para resaltar el logo
                Container(
                  width: size.width * 0.35, 
                  height: size.width * 0.35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  // Recorta la imagen rectangular para adaptarla al diseño circular
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/inicio/logo_emaus.jpg", 
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, 
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // Muestra el nombre principal de la institución con sombra para contraste
                Text(
                  "EMAÚS",
                  style: GoogleFonts.montserrat(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shadows: const [ 
                      Shadow(
                        blurRadius: 6.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                
                // Muestra el subtítulo descriptivo del propósito del sistema
                Text(
                  "Sistema de Transporte",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 0, 0, 0),
                     shadows: const [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
