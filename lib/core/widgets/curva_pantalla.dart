// Archivo - lib/core/constantes/curva_pantalla.dart
import 'package:flutter/material.dart';
// Define una forma de recorte personalizada con un borde inferior curvo.
class CurvaInferiorClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    final controlPoint = Offset(size.width / 2, size.height + 40);
    final endPoint = Offset(size.width, size.height - 80);
    // Dibuja la curva Bezier
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    // Cierra el trazado volviendo a la parte superior
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  // Retorna `false` indicando al framework que la forma es estática y no necesita recalcularse constantemente.
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

