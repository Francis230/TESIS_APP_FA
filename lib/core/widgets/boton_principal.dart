// Archivo - lib/core/widgets/boton_principal.dart
import 'package:flutter/material.dart';
import '../../../app/app_theme.dart'; 
//  Componente de interfaz reutilizable que representa el botón de acción principal dentro de la aplicación.
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final bool cargando;
  final Color? color;
  final double? radioBorde;
  final VoidCallback? onPressed;
  final IconData? icono;
  final double iconoSize; 
  //  Constructor constante para la inicialización del widget.
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.color,
    this.radioBorde,
    this.icono,      
    this.iconoSize = 22,
  });
  // Construye la representación visual del botón en el árbol de widgets.
  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.azulFuerte;
    final borderRadiusValue = radioBorde ?? 12.0;
    // Se anula el callback onPressed si está cargando para evitar múltiples envíos.
    return ElevatedButton(
      onPressed: cargando ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusValue),
        ),
        elevation: 3,
      ),
      // Renderizado condicional del contenido hijo.
      child: cargando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Renderizado condicional del icono si este existe.
                if (icono != null) ...[
                  Icon(icono, size: iconoSize, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  texto,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}