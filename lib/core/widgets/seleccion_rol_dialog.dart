// Archivo - lib/core/widgets/seleccion_rol_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
// Ventana emergente del administrador a elegir un perfil de acceso antes de continuar
class SeleccionRolDialog extends StatelessWidget {
  const SeleccionRolDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Construye la caja de diálogo con fondo blanco y esquinas redondeadas.
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          // Ajusta el tamaño de la ventana al contenido necesario.
          mainAxisSize: MainAxisSize.min, 
          children: [
            // Encabezado principal del diálogo
            Text(
              "Seleccionar Rol",
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            // Texto de instrucción secundaria para al administrador de que rol escoger
            Text(
              "¿Cómo deseas ingresar a la plataforma?",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // Lista vertical que contiene los botones de selección.
            Column(
              children: [
                // Botón para perfil de Administrador con animación vectorial (Lottie)
                _BotonRolAncho(
                  titulo: "Administrador",
                  // Usamos un Lottie o Icono
                  animacion: Lottie.asset(
                    'assets/animations/login/rol_admin.json', 
                    height: 60,
                    width: 60,
                    fit: BoxFit.contain,
                  ),
                  color: AppTheme.azulFuerte.withOpacity(0.1),
                  // Cierra la ventana y confirma la selección 'administrador'
                  onTap: () => Navigator.of(context).pop('administrador'),
                ),
                // Espacio vertical entre botones
                const SizedBox(height: 16), 

                // Botón para perfil de Conductor con imagen animada (GIF)
                _BotonRolAncho(
                  titulo: "Conductor",
                  animacion: Image.asset(
                    'assets/animations/login/rol_conductor.gif',
                    height: 60,
                    width: 60,
                    fit: BoxFit.contain,
                  ),
                  color: AppTheme.tonoIntermedio.withOpacity(0.1),
                  // Cierra la ventana y confirma la selección 'conductor'
                  onTap: () => Navigator.of(context).pop('conductor'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Componente auxiliar que estandariza el diseño visual de cada botón de rol
class _BotonRolAncho extends StatelessWidget {
  const _BotonRolAncho({
    required this.titulo,
    required this.animacion,
    required this.color,
    required this.onTap,
  });

  final String titulo;
  final Widget animacion;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Crea la superficie táctil con el color de fondo específico del rol
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // Detecta el toque del usuario para ejecutar la acción
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6), 
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: animacion,
                ),
              ),
              
              const SizedBox(width: 20),

              // Sección de texto y flecha indicadora alineada a la derecha
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre del rol con tipografía legible
                    Text(
                      titulo,
                      style: GoogleFonts.montserrat(
                        fontSize: 18, 
                        fontWeight: FontWeight.w600,
                        color: AppTheme.negroPrincipal,
                      ),
                    ),
                    // Icono sutil que invita a pulsar el botón
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: AppTheme.negroPrincipal.withOpacity(0.5),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}