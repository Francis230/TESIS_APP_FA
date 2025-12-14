// Archivo - lib/features/admin/presentation/registrar_conductor.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:go_router/go_router.dart'; 
import 'package:google_fonts/google_fonts.dart'; 
import 'package:lottie/lottie.dart'; 
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/boton_principal.dart';
import '../../../app/app_theme.dart';
import '../data/admin_repository.dart';
// Gestiona el formulario de inscripción para dar de alta nuevos conductores en la plataforma
class RegistrarConductor extends StatefulWidget {
  const RegistrarConductor({super.key});

  @override
  State<RegistrarConductor> createState() => _RegistrarConductorState();
}
// Administra el contenido de los campos de texto para capturar la información del usuario
class _RegistrarConductorState extends State<RegistrarConductor> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _licenciaCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  final _repositorio = AdminRepository();
  bool _cargando = false;
  XFile? _fotoSeleccionada;
  // Almacena las rutas disponibles para asignarlas durante el registro
  List<Map<String, dynamic>> _rutasDisponibles = [];
  String? _rutaSeleccionadaId;

  @override
  void initState() {
    super.initState();
    // Inicia la recuperación de rutas libres al cargar la pantalla
    _cargarRutas();
  }

  @override
  void dispose() {
    // Libera los recursos de memoria de los controladores al cerrar la pantalla
    _correoCtrl.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _placaCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    _licenciaCtrl.dispose();
    _cedulaCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }
  // Obtiene y organiza numéricamente las rutas que no tienen conductor asignado
  Future<void> _cargarRutas() async {
    try {
      final rutas = await _repositorio.listarRutasTotalmenteLibres();
      // Orden númerico en el filtro
      rutas.sort((a, b) {
        final nombreA = a['numero_ruta']?.toString() ?? '';
        final nombreB = b['numero_ruta']?.toString() ?? '';
        final numA = _extraerNumeroRuta(nombreA);
        final numB = _extraerNumeroRuta(nombreB);
        return numA.compareTo(numB);
      });

      setState(() {
        _rutasDisponibles = rutas;
      });
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e, "cargar rutas"));
      }
    }
  }
  // Permite seleccionar una imagen desde la galería del dispositivo para el perfil
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _fotoSeleccionada = picked);
    }
  }
  // Borra la imagen seleccionada temporalmente antes de guardar
  void _eliminarFoto() {
    setState(() => _fotoSeleccionada = null);
  }
  // Analiza el nombre de la ruta para permitir un ordenamiento lógico en la lista
  int _extraerNumeroRuta(String nombreRuta) {
    // Busca el primer grupo de dígitos en el string
    final match = RegExp(r'\d+').firstMatch(nombreRuta);

    if (match != null) {
      // Si encuentra un número, lo convierte a entero
      return int.tryParse(match.group(0) ?? '99999') ?? 99999;
    }

    // Si la ruta no tiene número (ej. "Ruta sin asignar"), la manda al final
    return 99999;
  }
  // Convierte errores técnicos en mensajes claros para el usuario final
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('email already in use') ||
        errorStr.contains('user already exists')) {
      return 'Este correo electrónico ya está registrado.';
    }
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cargar rutas") {
      return "Error al cargar la lista de rutas.";
    }
    return 'Ocurrió un error inesperado al registrar al conductor.';
  }
  // Muestra una alerta visual estilizada cuando ocurre un fallo en el proceso
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
        title: Text(
          "Error en el Registro",
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
  // Muestra una confirmación visual cuando el registro se completa exitosamente
  Future<void> _mostrarDialogoExito(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Lottie.asset(
            'assets/animations/bool/correct.json',
            height: 100,
            repeat: false,
          ),
          title: Text(
            '¡Éxito!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: AppTheme.negroPrincipal,
            ),
          ),
          content: Text(mensaje, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
  // Valida el formulario y envía los datos al servidor para crear el nuevo usuario
  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _cargando = true);

    try {
      final id = await _repositorio.registrarConductor(
        correo: _correoCtrl.text.trim(),
        nombreCompleto: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        rutaId: _rutaSeleccionadaId,
        placa: _placaCtrl.text.trim().toUpperCase().replaceAll(
          '-',  
          '',
        ), 
        marca: _marcaCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        licencia: _licenciaCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        fotoFile: _fotoSeleccionada,
      );

      if (mounted && id != null) {
        await _mostrarDialogoExito(
          "Conductor registrado. Se envió un correo con su clave temporal.",
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e, "registrar"));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Crea un campo de entrada de texto estandarizado con el diseño de la aplicación
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      cursorColor: Colors.white,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppTheme.secundario,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  // Genera el menú desplegable para asignar una ruta al conductor
  Widget _buildRutaDropdown() {
    return DropdownButtonFormField<String?>(
      value: _rutaSeleccionadaId,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
        labelText: 'Ruta Asignada',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(FontAwesomeIcons.route, color: Colors.white),
        filled: true,
        fillColor: AppTheme.secundario,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      dropdownColor: AppTheme.secundario,
      style: const TextStyle(color: Colors.white),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            "Ninguna (Guardar como Reserva)",
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ..._rutasDisponibles.map((ruta) {
          final numeroRuta = ruta['numero_ruta'] ?? 'Sin número';
          final sector = ruta['sector'] ?? '';
          return DropdownMenuItem<String?>(
            value: ruta['ruta_id'] as String?,
            child: Text(
              "Ruta $numeroRuta • $sector",
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ],
      onChanged: (String? nuevoIdSeleccionado) {
        setState(() {
          _rutaSeleccionadaId = nuevoIdSeleccionado;
        });
      },
    );
  }
  // Estructura la interfaz gráfica principal con todos los campos y botones
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: const Text('Registrar Conductor'),
        backgroundColor: AppTheme.negroPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Datos Personales",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _correoCtrl,
                label: 'Correo electrónico',
                hint: 'ej: juancho@gmail.com',
                validator: Validadores.validarCorreo,
                inputType: TextInputType.emailAddress,
                icon: FontAwesomeIcons.solidEnvelope,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nombreCtrl,
                label: 'Nombre completo',
                hint: 'ej: Juan Pérez',
                validator: (v) =>
                    Validadores.validarTexto(v, 'Nombre completo'), 
                icon: FontAwesomeIcons.user,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cedulaCtrl,
                label: 'Cédula de Identidad',
                hint: 'ej: 1709999999',
                validator: Validadores.validarIdentificacion, 
                inputType: TextInputType.number,
                icon: FontAwesomeIcons.idCardClip,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _telefonoCtrl,
                label: 'Teléfono',
                hint: 'ej: 0999999999',
                inputType: TextInputType.phone,
                validator: Validadores.validarTelefono, 
                icon: FontAwesomeIcons.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _direccionCtrl,
                label: 'Dirección Domiciliaria',
                hint: 'Calle principal y número',
                validator: (v) =>
                    Validadores.validarTexto(v, 'Dirección'), 
                icon: FontAwesomeIcons.locationDot,
              ),
              const SizedBox(height: 28),

              const Text(
                "Ruta Asignada",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRutaDropdown(),
              const SizedBox(height: 28),

              const Text(
                "Datos del Vehículo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _placaCtrl,
                label: 'Placa',
                icon: FontAwesomeIcons.carOn,
                hint: 'ej: ABC-1234 o ABC1234',
                validator: Validadores.validarPlaca, 
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _marcaCtrl,
                label: 'Marca',
                icon: FontAwesomeIcons.car,
                hint: 'ej: Chevrolet',
                validator: (v) =>
                    Validadores.validarTexto(v, 'Marca'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _modeloCtrl,
                label: 'Modelo',
                icon: FontAwesomeIcons.vanShuttle,
                hint: 'ej: Aveo',
                validator: (v) =>
                    Validadores.validarTexto(v, 'Modelo'), 
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _colorCtrl,
                label: 'Color',
                icon: FontAwesomeIcons.palette,
                hint: 'ej: Rojo',
                validator: (v) =>
                    Validadores.validarTexto(v, 'Color'), 
              ),
              const SizedBox(height: 28),

              const Text(
                "Licencia",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _licenciaCtrl,
                label: 'Licencia de Conducir',
                hint: 'ej: 1709999999 (10 dígitos)',
                icon: FontAwesomeIcons.idCard,
                validator: Validadores.validarLicencia, 
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Muestra la vista previa de la foto seleccionada o el botón para cargarla
              Center(
                child: _fotoSeleccionada != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _fotoSeleccionada!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator(
                                          color: Colors.white,
                                        );
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_fotoSeleccionada!.path),
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _eliminarFoto,
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            label: const Text(
                              'Eliminar foto',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: _seleccionarFoto,
                        icon: const FaIcon(
                          FontAwesomeIcons.camera,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Seleccionar Foto de Perfil (Rostro)',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Botón principal para confirmar el registro y guardar los datos
              SizedBox(
                width: double.infinity,
                child: BotonPrincipal(
                  texto: 'Registrar Conductor',
                  cargando: _cargando, 
                  onPressed: _registrar,
                  color: AppTheme.azulFuerte,
                  radioBorde: 25,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
