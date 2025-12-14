// Archivo - lib/core/constantes/formatos.dart
// Este archivo contiene funciones de formato para mostrar datos en la interfaz.
// El estudiante lo usa para convertir fechas, horas y otros datos.
import 'package:intl/intl.dart';

class Formatos {
  // Formatea una fecha en formato dd/MM/yyyy
  static String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }
  // Formatea una hora en formato HH:mm
  static String formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }
  // Formatea un número de teléfono con espacios
  static String formatearTelefono(String telefono) {
    return telefono.replaceAllMapped(
      RegExp(r'(\d{3})(\d{3})(\d+)'),
      (m) => "\${m[1]} \${m[2]} \${m[3]}",
    );
  }
}
