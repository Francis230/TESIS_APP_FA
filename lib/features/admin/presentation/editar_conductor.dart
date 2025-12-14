// Archivo - lib/features/admin/presentation/editar_conductor.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:lottie/lottie.dart'; 
import 'package:tesis_appmovilfaj/core/widgets/boton_principal.dart';
import '../data/admin_repository.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/validadores.dart';
// Gestiona la interfaz de modificación de datos personales y operativos de un conductor existente
class EditarConductorPage extends StatefulWidget {
  final Map<String, dynamic> conductorData;
  final List<Map<String, dynamic>> rutasDisponibles;

  const EditarConductorPage({
    super.key,
    required this.conductorData,
    required this.rutasDisponibles,
  });

  @override
  State<EditarConductorPage> createState() => _EditarConductorPageState();
}

class _EditarConductorPageState extends State<EditarConductorPage> {
  final _formKey = GlobalKey<FormState>();
  final AdminRepository _repo = AdminRepository();
  // Controla el estado temporal de los campos de texto durante la edición
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _placaCtrl;
  late TextEditingController _marcaCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _licenciaCtrl;
  
  String? _rutaSeleccionadaId;
  XFile? _fotoSeleccionada;
  bool _guardando = false;
  // Se almacena en la lista de itinerarios libres procesada para su visualización
  List<Map<String, dynamic>> _rutasFiltradas = [];

  @override
  void initState() {
    super.initState();
    // Prepara los controladores con la información actual del conductor y carga recursos auxiliares
    final perfil = widget.conductorData['perfiles'] != null
        ? Map<String, dynamic>.from(widget.conductorData['perfiles'])
        : <String, dynamic>{};

    _nombreCtrl = TextEditingController(
        text: perfil['nombre_completo'] ??
            widget.conductorData['nombre_completo'] ??
            '');
    _telefonoCtrl = TextEditingController(
        text: perfil['telefono'] ?? widget.conductorData['telefono'] ?? '');
    _correoCtrl = TextEditingController(
        text: perfil['correo'] ?? widget.conductorData['correo'] ?? '');
    _direccionCtrl = TextEditingController(
        text: perfil['direccion'] ?? widget.conductorData['direccion'] ?? '');
    _placaCtrl =
        TextEditingController(text: widget.conductorData['placa_vehiculo'] ?? '');
    _marcaCtrl =
        TextEditingController(text: widget.conductorData['marca_vehiculo'] ?? '');
    _modeloCtrl =
        TextEditingController(text: widget.conductorData['modelo_vehiculo'] ?? '');
    _colorCtrl =
        TextEditingController(text: widget.conductorData['color_vehiculo'] ?? '');
    _licenciaCtrl = TextEditingController(
        text: widget.conductorData['licencia_conducir'] ?? '');
    _rutaSeleccionadaId = widget.conductorData['numero_ruta_asignada'];
    // Carga de las rutas de manera origanizada
    _cargarRutasLibresOrdenadas();
  }
  int _extraerNumeroRuta(String nombreRuta) {
    final match = RegExp(r'\d+').firstMatch(nombreRuta);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '99999') ?? 99999;
    }
    return 99999;
  }

  @override
  void dispose() {
    // Libera los recursos de memoria asociados a los controladores de texto
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    _placaCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    _licenciaCtrl.dispose();
    super.dispose();
  }
  // Funcion para cargar las rutas libres sin asignacion de conductores
  Future<void> _cargarRutasLibresOrdenadas() async {
    try {
      final conductorId = widget.conductorData['conductor_id'];
      // Trae rutas disponibles (Backend filtra ocupadas)
      final rutas = await _repo.listarRutasDisponiblesParaConductor(conductorId);
      
      // Aplicamos el ordenamiento numérico
      rutas.sort((a, b) {
        final nombreA = a['numero_ruta']?.toString() ?? '';
        final nombreB = b['numero_ruta']?.toString() ?? '';
        final numA = _extraerNumeroRuta(nombreA);
        final numB = _extraerNumeroRuta(nombreB);
        return numA.compareTo(numB);
      });

      if (mounted) setState(() => _rutasFiltradas = rutas);
    } catch (e) {
      debugPrint("Error cargando rutas: $e");
    }
  }
  // Interpreta las excepciones técnicas y retorna mensajes comprensibles para el usuario.
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original al actualizar conductor: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    // Error por defecto
    return 'Ocurrió un error inesperado al actualizar el conductor.';
  }

  /// Muestra un pop-up de ERROR estilizado de color Blanco
  Future<void> _mostrarDialogoError(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text("Error al Actualizar",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(mensaje,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.black87)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Aceptar', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte)),
          )
        ],
      ),
    );
  }

  // Despliega una notificación visual de confirmación tras una operación exitosa
  Future<void> _mostrarDialogoExito(String mensaje) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Lottie.asset('assets/animations/bool/correct.json', height: 100, repeat: false),
          title: Text('¡Éxito!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text(mensaje, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();      
                Navigator.of(context).pop(true);        
              },
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }
  // Gestiona la captura o selección de una imagen desde el dispositivo
  Future<void> _seleccionarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _fotoSeleccionada = picked);
  }
  // Valida el formulario y ejecuta la transacción de actualización en la base de datos
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final rutaParaEnviar = _rutaSeleccionadaId ?? 'SIN_RUTA';
      await _repo.actualizarConductor(
        conductorId: widget.conductorData['conductor_id'],
        nombreCompleto: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        correo: _correoCtrl.text.trim(), 
        direccion: _direccionCtrl.text.trim(),
        placaVehiculo: _placaCtrl.text.trim().toUpperCase().replaceAll('-', ''),
        marcaVehiculo: _marcaCtrl.text.trim(),
        modeloVehiculo: _modeloCtrl.text.trim(),
        colorVehiculo: _colorCtrl.text.trim(),
        licenciaConducir: _licenciaCtrl.text.trim(),
        rutaId: rutaParaEnviar, 
        fotoFile: _fotoSeleccionada,
      );

      if (mounted) {
        await _mostrarDialogoExito('Conductor actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        await _mostrarDialogoError(_traducirError(e));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
  // Genera una vista previa visual de la fotografía seleccionada o la actual del perfil
  Widget _fotoPreview() {
    final perfil = widget.conductorData['perfiles'] != null
        ? Map<String, dynamic>.from(widget.conductorData['perfiles'])
        : <String, dynamic>{};
    
    final fotoPerfilUrl = perfil['foto_url'] as String?; 
    final currentUrl = _fotoSeleccionada != null ? null : fotoPerfilUrl;

    if (_fotoSeleccionada != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _fotoSeleccionada!.readAsBytes(),
          builder: (context, snap) {
            if (!snap.hasData) return const CircularProgressIndicator(color: AppTheme.azulFuerte);
            return Image.memory(snap.data!, fit: BoxFit.cover);
          },
        );
      } else {
        return Image.file(File(_fotoSeleccionada!.path), fit: BoxFit.cover);
      }
    }

    if (currentUrl != null && currentUrl.isNotEmpty) {
      return Image.network(
        currentUrl,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(Icons.person, size: 64, color: Colors.white24);
        },
      );
    }
    return const FaIcon(FontAwesomeIcons.solidUser, size: 80, color: Colors.white24);
  }
  // Creación de encabezados visuales para separar las secciones del formulario
  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Construye un campo de entrada de texto estandarizado con validación y diseño
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      enabled: enabled,
      controller: controller,
      cursorColor: Colors.white, 
      validator: validator,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        isDense: true,
        
        prefixIcon: SizedBox(
          width: 55,
          child: Center(
            child: FaIcon(icon, color: Colors.white, size: 20), 
          ),
        ),
        
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        
        filled: true,
        fillColor: AppTheme.negroPrincipal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
         enabledBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.azulFuerte, width: 2),
        ),
        errorBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder( 
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.tonoIntermedio.withOpacity(0.5)),
        ),
      ),
    );
  }
  // Ensamblaje de la estructura visual completa de la pantalla de edición
  @override
  Widget build(BuildContext context) {
    final rutas = widget.rutasDisponibles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Conductor'),
        backgroundColor: AppTheme.negroPrincipal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.negroPrincipal,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de gestión y previsualización de la fotografía del conductor
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    color: AppTheme.secundario,
                  ),
                  child: _fotoPreview(),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _seleccionarFoto(ImageSource.gallery),
                    icon: const FaIcon(FontAwesomeIcons.camera, size: 18, color: Colors.white70),
                    label: const Text('Galería', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _seleccionarFoto(ImageSource.camera),
                    icon: const FaIcon(FontAwesomeIcons.cameraRetro, size: 18, color: Colors.white70),
                    label: const Text('Cámara', style: TextStyle(color: Colors.white70)),
                  ),
                  if (_fotoSeleccionada != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _fotoSeleccionada = null),
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Contenedor principal para la modificación de datos personales y vehiculares
              Card(
                color: AppTheme.secundario,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datos Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Divider(color: Colors.white24, height: 24),
                      
                      _buildTextField(
                        controller: _nombreCtrl,
                        label: 'Nombre completo',
                        icon: FontAwesomeIcons.user,
                        validator: (value) => Validadores.validarTexto(value, 'Nombre completo'),
                        inputType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _telefonoCtrl, 
                        label: 'Teléfono', 
                        icon: FontAwesomeIcons.phone, 
                        inputType: TextInputType.phone,
                        validator: Validadores.validarTelefono, 
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _correoCtrl, 
                        label: 'Correo electrónico', 
                        icon: FontAwesomeIcons.envelope, 
                        inputType: TextInputType.emailAddress, 
                        enabled: false, 
                        validator: Validadores.validarCorreo,
                      ), 
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _direccionCtrl, 
                        label: 'Dirección', 
                        icon: FontAwesomeIcons.locationDot, 
                        inputType: TextInputType.text,
                        validator: (value) => Validadores.validarTexto(value, 'Dirección'),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      
                      const Text('Datos del Vehículo y Ruta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Divider(color: Colors.white24, height: 24),

                      _buildTextField(
                        controller: _placaCtrl, 
                        label: 'Placa del vehículo', 
                        icon: FontAwesomeIcons.carOn, 
                        inputType: TextInputType.text,
                        validator: Validadores.validarPlaca, 
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _marcaCtrl, 
                        label: 'Marca', 
                        icon: FontAwesomeIcons.car, 
                        inputType: TextInputType.text,
                        validator: (value) => Validadores.validarTexto(value, 'Marca'),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _modeloCtrl, 
                        label: 'Modelo', 
                        icon: FontAwesomeIcons.vanShuttle, 
                        inputType: TextInputType.text,
                        validator: (value) => Validadores.validarTexto(value, 'Modelo'),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _colorCtrl, 
                        label: 'Color', 
                        icon: FontAwesomeIcons.palette, 
                        inputType: TextInputType.text,
                        validator: (value) => Validadores.validarTexto(value, 'Color'),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _licenciaCtrl, 
                        label: 'Licencia de conducir', 
                        icon: FontAwesomeIcons.idCard, 
                        inputType: TextInputType.number,
                        validator: Validadores.validarLicencia, 
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSectionHeader('Ruta', FontAwesomeIcons.route, color: Colors.white, ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.secundario.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.azulFuerte.withOpacity(0.5))),
                          child: DropdownButtonFormField<String?>(
                            value: _rutaSeleccionadaId,
                            dropdownColor: AppTheme.secundario,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.map, color: Color.fromARGB(255, 255, 255, 255)), labelText: 'Asignar Ruta', labelStyle: TextStyle(color: Colors.white70)),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin asignar (Reserva)', style: TextStyle(color: Colors.orangeAccent))),
                              ..._rutasFiltradas.map((r) => DropdownMenuItem(value: r['ruta_id'], child: Text(r['numero_ruta'] ?? 'Ruta s/n', style: const TextStyle(color: Colors.white)))),
                            ],
                            onChanged: (v) => setState(() => _rutaSeleccionadaId = v),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón de acción principal para confirmar y guardar los cambios realizados
              BotonPrincipal(
                texto: 'Guardar cambios',
                cargando: _guardando,
                onPressed: _guardarCambios,
                color: AppTheme.azulFuerte,
                radioBorde: 25,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}



