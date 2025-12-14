// Archivo - lib/core/constantes/validadores.dart
// Funciones de validación de campos de formularios.

class Validadores {
  // Valida que un correo tenga formato válido
  static String? validarCorreo(String? valor) {
    if (valor == null || valor.isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(valor)) return 'Formato de correo inválido';
    return null;
  }

  // Valida que una contraseña tenga al menos 6 caracteres
  static String? validarClave(String? valor) {
    if (valor == null || valor.isEmpty) return 'La contraseña es obligatoria';
    if (valor.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  // Valida para confirmar que las contraseñas coinciden
  static String? validarConfirmarClave(String? valor, String clave) {
    if (valor == null || valor.isEmpty) return 'Confirma tu contraseña';
    if (valor != clave) return 'Las contraseñas no coinciden';
    return null;
  }

  // Valida que un campo de texto no esté vacío
  static String? validarTexto(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) return '$campo es obligatorio';
    return null;
  }

  // Valida teléfono de ecuador (10 dígitos y empieza con 09)
  static String? validarTelefono(String? valor) {
    if (valor == null || valor.isEmpty) return 'El teléfono es obligatorio';
    
    final tel = valor.replaceAll(RegExp(r'\s+|-'), '');
    
    if (tel.length != 10) return 'Debe tener 10 dígitos';
    if (!tel.startsWith('09')) return 'Debe empezar con 09';
    if (!RegExp(r'^[0-9]+$').hasMatch(tel)) return 'Solo se permiten números';
    
    return null;
  }

  // Valida cédula ecuatoriana algoritmo módulo 10
  static String? validarIdentificacion(String? valor) {
    if (valor == null || valor.isEmpty) return 'La cédula es obligatoria';

    final ci = valor.replaceAll(RegExp(r'\s+|-'), '');

    if (ci.length != 10) return 'La Cédula debe tener 10 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(ci)) return 'Solo se permiten números';

    try {
      int provincia = int.parse(ci.substring(0, 2));
      if (provincia < 1 || provincia > 24) {
         // Se añade la provincia 30 para los ecuatorianos nacidos en el exterior
        if (provincia != 30) {
          return 'Código de provincia inválido';
        }
      }

      int digitoVerificador = int.parse(ci.substring(9, 10));
      int suma = 0;

      for (int i = 0; i < 9; i++) {
        int digito = int.parse(ci.substring(i, i + 1));
        int coeficiente = (i % 2 == 0) ? 2 : 1;
        int producto = digito * coeficiente;
        
        suma += (producto >= 10) ? (producto - 9) : producto;
      }

      int residuo = suma % 10;
      int resultado = (residuo == 0) ? 0 : (10 - residuo);

      if (resultado == digitoVerificador) {
        return null;
      } else {
        return 'Número de cédula inválido';
      }
    } catch (e) {
      return 'Formato de cédula incorrecto';
    }
  }
  // Valida las placas 3 letras y 3-4 números
  static String? validarPlaca(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La placa es obligatoria';
    
    // Normaliza la placa: quita guiones y espacios, y a mayúsculas
    final placa = valor.trim().toUpperCase().replaceAll('-', '');

    if (placa.length < 6 || placa.length > 7) return 'Formato inválido (ej: ABC1234)';
    
    // Expresión regular: 3 letras (A-Z) seguidas de 3 o 4 números (0-9)
    final regex = RegExp(r'^[A-Z]{3}[0-9]{3,4}$'); 
    
    if (!regex.hasMatch(placa)) {
      return 'Formato inválido (ej: ABC1234)';
    }
    return null;
  }

  // Valida las licencias de 10 dígitos numéricos
  static String? validarLicencia(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'La licencia es obligatoria';
    
    final lic = valor.trim();

    if (lic.length != 10) return 'La licencia debe tener 10 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(lic)) return 'Solo se permiten números';
    
    return null;
  }
  // Valida el formato de regsitro de las rutas
  static String? validarFormatoRuta(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'El nombre es obligatorio';
    final regex = RegExp(r'^Ruta \d+$', caseSensitive: false);
    
    if (!regex.hasMatch(valor.trim())) {
      return 'Formato inválido. Use "Ruta #" (ej: Ruta 1)';
    }
    return null;
  }
}