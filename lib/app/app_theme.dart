// Archivo - lib/app/app_theme.dart
import 'package:flutter/material.dart';
// Estilo visual de la aplicación y estilos goblales de la aplicación.
class AppTheme {
  // Definición de la paleta de colores
  // Fondo principal para la aplicación de color oscuro
  static const Color negroPrincipal = Color(0xFF06141B);
  // Color secundario utilizado para superficies como las tarjetas y contadores
  static const Color secundario = Color(0xFF11212D);
  // Color de color primario (azul,gris oscuro)
  static const Color azulFuerte = Color(0xFF253745);
  // Tono Intermedio (azul grisáceo)
  static const Color tonoIntermedio = Color(0xFF4A5C6A);
  // Color para el texto secundario y placeholders (hints)
  static const Color grisClaro = Color(0xFF9BA8AB);
  // Color para variaciones en modo claro
  static const Color fondoClaro = Color(0xFFCCD0CF);
  // Color base para las terjetas de alta iluminacion
  static const Color cardClaro = Color(0xFFFFFFFF);
  // Color para el contraste Blanco
  static const Color acentoBlanco = Colors.white;
  // Color estandar para las superficies
  static const Color superficie = Color(0xFFF5F5F5);
  // Color estandar para delimitadores y bordes
  static const Color bordes = Color(0xFFE0E0E0);
  // Configuracion del tema
  static final ThemeData temaPrincipal = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: negroPrincipal,

    // Esquema de colores asimetricos para la paleta de colores personalizado a los roles
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: azulFuerte, 
      onPrimary: Colors.white,
      secondary: secundario,
      onSecondary: Colors.white,
      background: negroPrincipal,
      onBackground: Colors.white,
      surface: secundario,
      onSurface: Colors.white,
      error: Colors.red,
      onError: Colors.white,
    ),
    // Configuración de la barra de aplicación superior
    appBarTheme: const AppBarTheme(
      backgroundColor: negroPrincipal,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Estilo global para los botones elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: azulFuerte,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // EStilo para las tarjetas
    cardTheme: CardThemeData(
      color: secundario,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),

    // Configuracion de los campos de entrada de texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tonoIntermedio.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tonoIntermedio, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintStyle: TextStyle(color: grisClaro),
    ),

    // Definición de la tipografía global de la aplicación.
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF9BA8AB), fontSize: 14),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: TextStyle(color: Colors.white, fontSize: 14),
    ),

    // Configuración de los iconos
    iconTheme: const IconThemeData(color: Color(0xFF4A5C6A)),

    // Configuración de la barra de navegación inferior
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: secundario,
      selectedItemColor: azulFuerte,
      unselectedItemColor: Color(0xFF9BA8AB),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedIconTheme: IconThemeData(color: azulFuerte),
      unselectedIconTheme: IconThemeData(color: Color(0xFF9BA8AB)),
    ),
    //  Configuración de la barra inferior  para el FAB
    bottomAppBarTheme: const BottomAppBarTheme(
      color: secundario,
      elevation: 8,
      shape: CircularNotchedRectangle(), 
    ),
    // Estilo del botón de acción flotante 
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: acentoBlanco,
      foregroundColor: Colors.black,
    ),
  );
}
