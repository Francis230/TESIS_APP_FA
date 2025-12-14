// Archivo - lib/core/widgets/tarjeta_uber.dart

import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

// Componente visual tipo tarjeta diseñado para presentar opciones de menú o información resumida
class TarjetaUber extends StatelessWidget {
  
  // Título principal que describe la acción o el contenido de la tarjeta
  final String titulo;

  // Texto descriptivo secundario que aporta contexto adicional al usuario
  final String subtitulo;

  // Elemento gráfico que refuerza visualmente el significado de la tarjeta
  final IconData icono;

  // Acción que se ejecuta al detectar un toque sobre la superficie de la tarjeta
  final VoidCallback onTap;

  const TarjetaUber({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Renderiza un contenedor elevado con el color secundario del tema oscuro
    return Card(
      color: AppTheme.secundario,
      // Organiza los elementos en un formato estándar de lista como icono, texto y subtitulo.
      child: ListTile(
        leading: Icon(icono, color: AppTheme.azulFuerte),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitulo,
          // Texto atenuado para jerarquía visual
          style: const TextStyle(color: Colors.white70),
        ),
        // Habilita la interactividad de todo el bloque
        onTap: onTap, 
      ),
    );
  }
}
