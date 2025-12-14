// Archivo - lib/features/conductor/presentation/registrar_editar_estudiante.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/core/utils/validadores.dart'; 
import 'package:tesis_appmovilfaj/core/widgets/boton_principal.dart';
import 'package:tesis_appmovilfaj/features/conductor/data/conductor_repository.dart';
import 'package:google_fonts/google_fonts.dart';
// Gestión del formulario para inscribir nuevos estudiantes o modificar la información de los existentes
class RegistrarEditarEstudiantePage extends StatefulWidget {
  final Map<String, dynamic>? estudiante;

  const RegistrarEditarEstudiantePage({super.key, this.estudiante});

  @override
  State<RegistrarEditarEstudiantePage> createState() =>
      _RegistrarEditarEstudiantePageState();
}

class _RegistrarEditarEstudiantePageState
    extends State<RegistrarEditarEstudiantePage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ConductorRepository();
  bool _cargando = false;
  // Administra los controladores de texto para capturar los datos del estudiante
  late final TextEditingController _nombreCtrl,
      _cedulaCtrl,
      _gradoCtrl,
      _paraleloCtrl,
      _alergiasCtrl,
      _obsCtrl,
      _direccionCtrl;

  DateTime? _fechaNacimiento;
  gmaps.LatLng? _coordenadasCasa;
  XFile? _fotoSeleccionada;
  String? _fotoUrlExistente;
  Uint8List? _fotoBytesPreview;
  String? _representanteIdSeleccionado;
  String _representanteNombreSeleccionado = 'Ninguno seleccionado';
  // Determina si el formulario se encuentra en modo de edición o registro
  bool get _esEdicion => widget.estudiante != null;

  @override
  void initState() {
    super.initState();
    final est = widget.estudiante;
    _nombreCtrl = TextEditingController(text: est?['nombre_completo'] ?? '');
    _cedulaCtrl = TextEditingController(text: est?['cedula'] ?? '');
    _gradoCtrl = TextEditingController(text: est?['grado'] ?? '');
    _paraleloCtrl = TextEditingController(text: est?['paralelo'] ?? '');
    _direccionCtrl = TextEditingController(text: est?['direccion'] ?? '');
    _alergiasCtrl = TextEditingController(text: est?['alergias'] ?? '');
    _obsCtrl = TextEditingController(text: est?['observaciones'] ?? '');
    _fotoUrlExistente = est?['foto_url'];
    if (est?['fecha_nacimiento'] != null) {
      try { _fechaNacimiento = DateTime.parse(est!['fecha_nacimiento']); } catch (_) { _fechaNacimiento = null; }
    }
    if (est?['latitud_casa'] != null && est?['longitud_casa'] != null) {
      try {
        _coordenadasCasa = gmaps.LatLng(
          double.parse(est!['latitud_casa'].toString()),
          double.parse(est['longitud_casa'].toString()),
        );
      } catch (e) { debugPrint("Error al parsear coordenadas: $e"); }
    }
    if (_esEdicion && est != null) {
      if (est['representante'] is Map<String, dynamic>) {
        final datosRepresentante = est['representante'] as Map<String, dynamic>;
        if (datosRepresentante['perfil'] is Map<String, dynamic>) {
          final perfil = datosRepresentante['perfil'] as Map<String, dynamic>;
          _representanteIdSeleccionado = perfil['id'];
          _representanteNombreSeleccionado =
              perfil['nombre_completo'] ?? 'Nombre no encontrado';
        }
      }
    }
  }

  @override
  void dispose() {
    // Libera los recursos de memoria utilizados por los controladores al cerrar la pantalla
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _gradoCtrl.dispose();
    _paraleloCtrl.dispose();
    _direccionCtrl.dispose();
    _alergiasCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }
  // Permite seleccionar una imagen desde la galería para usarla como foto de perfil
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _fotoSeleccionada = pickedFile;
        _fotoBytesPreview = bytes;
        _fotoUrlExistente = null;
      });
    }
  }

  // Despliega un calendario para definir la fecha de nacimiento del estudiante
  Future<void> _seleccionarFechaNacimiento() async {
    final hoy = DateTime.now();
    final initial = _fechaNacimiento ?? DateTime(hoy.year - 8);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: hoy,
      locale: const Locale('es', 'ES'), 
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.azulFuerte, 
              onPrimary: Colors.white, 
              surface: Colors.white, 
              onSurface: AppTheme.negroPrincipal, 
            ),
            dialogBackgroundColor: Colors.white, 
            textTheme: GoogleFonts.montserratTextTheme(Theme.of(ctx).textTheme)
                .apply(bodyColor: AppTheme.negroPrincipal, displayColor: AppTheme.negroPrincipal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }
  
  // Traduce los errores técnicos del sistema a mensajes comprensibles para el usuario
  String _traducirError(Object e) {
    final errorStr = e.toString().toLowerCase();
    print("Error original al guardar estudiante: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (errorStr.contains('duplicate key value violates unique constraint')) {
      return 'La cédula ingresada ya pertenece a otro estudiante.';
    }
    
    return 'Ocurrió un error inesperado al guardar.';
  }
  // Muestra una confirmación visual cuando la operación se completa exitosamente
  Future<void> _mostrarDialogoExito(String titulo, String mensaje) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            lottie.Lottie.asset(
              'assets/animations/bool/correct.json', 
              repeat: false,
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) =>
                  const FaIcon(FontAwesomeIcons.solidCircleCheck,
                      color: Colors.green, size: 60),
            ),
            const SizedBox(height: 12),
            Text(titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: AppTheme.negroPrincipal,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: AppTheme.tonoIntermedio, fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte, 
                foregroundColor: AppTheme.acentoBlanco,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Aceptar',
                style:
                    GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
  // Despliega una alerta visual estilizada para informar sobre fallos en el proceso
  Future<void> _mostrarDialogoError(String titulo, String mensaje) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: lottie.Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text(titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        content: Text(mensaje,
             textAlign: TextAlign.center,
             style: GoogleFonts.montserrat(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Aceptar', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte, fontWeight: FontWeight.w600)),
          )
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }
  // Abre un mapa interactivo para que el usuario fije la ubicación exacta del domicilio
  Future<void> _seleccionarUbicacionEnMapa() async {
    // Si no hay coordenadas, centramos en Quito 
    gmaps.LatLng posicionInicial = _coordenadasCasa ?? const gmaps.LatLng(-0.22985, -78.52498);
    gmaps.LatLng? posicionSeleccionada;
    
    // Variable para controlar la tarjeta de instrucción
    bool mostrarInstruccion = true; 

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog( 
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bordes muy redondeados
            insetPadding: const EdgeInsets.all(16), // Margen respecto a la pantalla
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Text(
                    'Ubicación del Domicilio',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.negroPrincipal, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  ),
                ),

                // Renderiza el mapa de Google dentro del diálogo para la selección
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55, // 55% de la altura de la pantalla
                  width: double.maxFinite,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Google Map
                          gmaps.GoogleMap(
                            initialCameraPosition: gmaps.CameraPosition(
                              target: posicionInicial,
                              zoom: 15,
                            ),
                            myLocationButtonEnabled: true, // Botón de "mi ubicación"
                            myLocationEnabled: true,
                            markers: {
                              gmaps.Marker(
                                markerId: const gmaps.MarkerId('domicilio_estudiante'),
                                position: posicionSeleccionada ?? posicionInicial,
                                draggable: true,
                                onDragEnd: (nuevaPosicion) {
                                  setDialogState(() {
                                    posicionSeleccionada = nuevaPosicion;
                                  });
                                },
                              ),
                            },
                            onTap: (nuevaPosicion) {
                              setDialogState(() {
                                posicionSeleccionada = nuevaPosicion;
                              });
                            },
                          ),

                          // arjeta Flotante de Instrucción
                          if (mostrarInstruccion)
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.negroPrincipal.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.touch_app, color: AppTheme.acentoBlanco, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Arrastra el pin para ubicar la dirección del estudiante.',
                                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setDialogState(() => mostrarInstruccion = false),
                                      child: const Icon(Icons.close, color: Colors.white70, size: 18),
                                    )
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botones de accion
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Cancelar', 
                            style: GoogleFonts.montserrat(color: Colors.grey.shade700, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _coordenadasCasa = posicionSeleccionada ?? posicionInicial;
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.azulFuerte,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Confirmar', 
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    setState(() {}); // Actualiza la pantalla principal al cerrar el mapa
  }
  
  // Abre un diálogo para buscar y vincular a un representante registrado en el sistema
  Future<void> _buscarYSeleccionarRepresentante() async {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> representantes = [];
    bool cargando = true;

    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          
          Future<void> cargarRepresentantes([String q = '']) async {
            setStateDialog(() => cargando = true);
            try {
              representantes = await _repo.buscarRepresentantes(q);
            } catch (e) {
              print("Error buscando representantes: $e");
              representantes = [];
            }
            setStateDialog(() => cargando = false);
          }
          
          if (representantes.isEmpty && cargando) {
            cargarRepresentantes();
          }

          return AlertDialog(
            backgroundColor: AppTheme.fondoClaro,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Seleccionar Representante',
                    style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o correo...',
                      hintStyle: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.tonoIntermedio),
                      filled: true,
                      fillColor: AppTheme.grisClaro.withOpacity(0.3),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => cargarRepresentantes(value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: cargando
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.azulFuerte))
                        : representantes.isEmpty
                            ? Center(
                                child: Text('No se encontraron representantes.',
                                    style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio)))
                            : ListView.separated(
                                itemCount: representantes.length,
                                separatorBuilder: (_, __) => const Divider(color: AppTheme.grisClaro, height: 1),
                                itemBuilder: (context, index) {
                                  final rep = representantes[index];
                                  final fotoUrl = rep['foto_url'] as String?;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.grisClaro.withOpacity(0.5),
                                      backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                                      child: (fotoUrl == null || fotoUrl.isEmpty)
                                        ? const FaIcon(FontAwesomeIcons.solidUser, size: 18, color: AppTheme.tonoIntermedio)
                                        : null,
                                    ),
                                    title: Text(rep['nombre_completo'] ?? '',
                                        style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.w600)),
                                    subtitle: Text(rep['correo'] ?? '',
                                        style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio, fontSize: 13)),
                                    onTap: () => Navigator.of(ctx).pop(rep),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio, fontWeight: FontWeight.w600)),
              )
            ],
          );
        });
      },
    ).then((seleccionado) {
      if (seleccionado != null) {
        setState(() {
          _representanteIdSeleccionado = seleccionado['id'];
          _representanteNombreSeleccionado = seleccionado['nombre_completo'] ?? 'Seleccionado';
        });
      }
    });
  }

  // Valida los datos del formulario y ejecuta el guardado en la base de datos
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_representanteIdSeleccionado == null) {
      await _mostrarDialogoError(
          'Falta representante', 'Debes buscar y seleccionar un representante.');
      return;
    }

    if (_fechaNacimiento == null) {
      await _mostrarDialogoError(
          'Fecha requerida', 'Selecciona la fecha de nacimiento.');
      return;
    }

    if (_coordenadasCasa == null) {
      await _mostrarDialogoError(
          'Ubicación requerida',
          'Por favor selecciona la ubicación del domicilio en el mapa.');
      return;
    }

    setState(() => _cargando = true);

    final datos = {
      'nombre_completo': _nombreCtrl.text.trim(),
      'cedula': _cedulaCtrl.text.trim(),
      'grado': _gradoCtrl.text.trim(),
      'paralelo': _paraleloCtrl.text.trim(),
      'alergias': _alergiasCtrl.text.trim(),
      'observaciones': _obsCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'fecha_nacimiento':
          _fechaNacimiento!.toIso8601String().substring(0, 10),
      'representante_id': _representanteIdSeleccionado,
      'latitud_casa': _coordenadasCasa!.latitude,
      'longitud_casa': _coordenadasCasa!.longitude,
    };

    try {
      String estudianteId;
      String tituloExito = "¡Éxito!";
      String mensajeExito = "Estudiante guardado correctamente.";

      if (_esEdicion) {
        estudianteId = widget.estudiante!['estudiante_id'];
        await _repo.actualizarEstudiante(estudianteId, datos);
        tituloExito = "Actualizado";
        mensajeExito = "Datos del estudiante actualizados.";
      } else {
        await _repo.registrarEstudiante(datos);
        final res = await Supabase.instance.client
            .from('estudiantes')
            .select('estudiante_id')
            .eq('nombre_completo', datos['nombre_completo'])
            .eq('cedula', datos['cedula'])
            .order('creado_en', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (res == null || res['estudiante_id'] == null) {
            throw Exception('No se pudo recuperar el ID del estudiante creado.');
        }
        estudianteId = res['estudiante_id'];
        tituloExito = "Registrado";
        mensajeExito = "Nuevo estudiante creado con éxito.";
      }

      // Subir foto si existe 
      if (_fotoSeleccionada != null && estudianteId.isNotEmpty) {
        final url = await _repo.subirFotoEstudiante(
            foto: _fotoSeleccionada!, estudianteId: estudianteId);
        await Supabase.instance.client
            .from('estudiantes')
            .update({'foto_url': url})
            .eq('estudiante_id', estudianteId);
      }
      await _mostrarDialogoExito(tituloExito, mensajeExito);
      Navigator.pop(context, true); // Regresar a la lista

    } catch (e) {
      debugPrint("Error guardando estudiante: $e");
      await _mostrarDialogoError("Error al Guardar", _traducirError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Configura el estilo visual estandarizado para los campos de entrada de texto
  InputDecoration _inputDecoration(
      {required String label, required IconData icon, Widget? suffixIcon, String? hintText}) { 
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio),
      hintText: hintText, 
      hintStyle: GoogleFonts.montserrat(color: AppTheme.grisClaro), 
      
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14.0, right: 10.0),
        child: FaIcon(icon, color: AppTheme.tonoIntermedio, size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),

      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.grisClaro.withOpacity(0.2),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.grisClaro.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.azulFuerte, width: 2),
      ),
    );
  }

  // Muestra el selector de foto para visualizar la imagen elegida o la actual
  Widget _buildPhotoSelector() {
    Widget imageWidget;
    if (_fotoBytesPreview != null) {
      imageWidget = Image.memory(_fotoBytesPreview!, fit: BoxFit.cover, width: 140, height: 140,);
    } else if (_fotoUrlExistente != null) {
      imageWidget = Image.network(_fotoUrlExistente!, fit: BoxFit.cover, width: 140, height: 140,);
    } else {
      imageWidget = const FaIcon(FontAwesomeIcons.child,
          size: 40, color: AppTheme.tonoIntermedio);
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 140,
            width: 140,
            color: AppTheme.grisClaro.withOpacity(0.3),
            child: Center(child: imageWidget),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _seleccionarFoto,
          icon: const FaIcon(FontAwesomeIcons.camera,
              color: AppTheme.negroPrincipal, size: 18),
          label: Text(
            _fotoBytesPreview != null || _fotoUrlExistente != null
                ? 'Cambiar Foto'
                : 'Seleccionar Foto',
            style: GoogleFonts.montserrat(
                color: AppTheme.negroPrincipal,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
  // Construye la interfaz principal organizando los elementos en columnas adaptables
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
        title: Text(
          _esEdicion ? 'Editar Estudiante' : 'Registrar Estudiante',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold, color: AppTheme.acentoBlanco),
        ),
        iconTheme:
            const IconThemeData(color: AppTheme.acentoBlanco),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLeftColumn()),
                          const SizedBox(width: 16),
                          SizedBox(width: 240, child: _buildRightColumn()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRightColumn(),
                          const SizedBox(height: 16),
                          _buildLeftColumn(),
                        ],
                      ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fondoClaro,
                      foregroundColor: AppTheme.negroPrincipal, 
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    
                    // Icono de carga o de guardado
                    icon: _cargando
                        ? SizedBox( // Indicador de carga
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppTheme.negroPrincipal,
                              strokeWidth: 2,
                            ),
                          )
                        : FaIcon( 
                            _esEdicion 
                              ? FontAwesomeIcons.userPen 
                              : FontAwesomeIcons.userPlus, 
                            size: 18
                          ),
                          
                    label: Text(
                      _cargando 
                        ? 'Guardando...' 
                        : (_esEdicion ? 'Actualizar Estudiante' : 'Guardar Estudiante'),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _cargando ? null : _guardar,
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          if (_cargando)
            Container(
              color: AppTheme.negroPrincipal.withOpacity(0.7),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.fondoClaro)),
            ),
        ],
      ),
    );
  }

  // Agrupa los campos de datos personales, ubicación y representante en un panel visual
  Widget _buildLeftColumn() {
    return Card(
      color: AppTheme.fondoClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Datos del Estudiante',
              style: GoogleFonts.montserrat(
                  color: AppTheme.negroPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5),
          
          TextFormField(
            controller: _nombreCtrl,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
            decoration:
                _inputDecoration(
                  label: 'Nombre Completo', 
                  icon: FontAwesomeIcons.user,
                  hintText: 'Ej: Samantha García', 
                ),
            validator: (v) => Validadores.validarTexto(v, 'Nombre completo'), 
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _seleccionarFechaNacimiento,
            child: AbsorbPointer(
              child: TextFormField(
                style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
                controller: TextEditingController(
                    text: _fechaNacimiento == null
                        ? ''
                        : DateFormat('dd/MM/yyyy')
                            .format(_fechaNacimiento!)),
                decoration: _inputDecoration(
                    label: 'Fecha de Nacimiento', icon: FontAwesomeIcons.cakeCandles),
                validator: (_) =>
                    _fechaNacimiento == null ? 'Selecciona una fecha' : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _gradoCtrl,
                style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
                decoration: _inputDecoration(
                    label: 'Grado/Curso', 
                    icon: FontAwesomeIcons.school,
                    hintText: 'Ej: Noveno',
                ),
                validator: (v) => Validadores.validarTexto(v, 'Grado'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _paraleloCtrl,
                style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
                decoration:
                    _inputDecoration(
                      label: 'Paralelo', 
                      icon: FontAwesomeIcons.tag,
                      hintText: 'Ej: A',
                    ),
                validator: (v) => Validadores.validarTexto(v, 'Paralelo'), 
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cedulaCtrl,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
            decoration: _inputDecoration(
                label: 'Cédula (Opcional)', 
                icon: FontAwesomeIcons.idCard,
                hintText: '10 dígitos (opcional)', 
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return null; // Permite estar vacío
              if (v.length != 10) return 'Debe tener 10 dígitos';
              if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Solo números';
              return null;
            },
          ),
          const Divider(color: AppTheme.grisClaro, height: 30, thickness: 0.5),

          Text('Ubicación del Domicilio',
              style: GoogleFonts.montserrat(
                  color: AppTheme.negroPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.mapPin, size: 16),
            label: Text('Seleccionar en Mapa',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            onPressed: _seleccionarUbicacionEnMapa,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secundario,
                foregroundColor: AppTheme.acentoBlanco,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
          if (_coordenadasCasa != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Lat: ${_coordenadasCasa!.latitude.toStringAsFixed(5)}, Lng: ${_coordenadasCasa!.longitude.toStringAsFixed(5)}',
                style: GoogleFonts.montserrat(
                    color: AppTheme.tonoIntermedio, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccionCtrl,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
            decoration: _inputDecoration(
                label: 'Dirección (Referencia)',
                icon: FontAwesomeIcons.locationDot,
                hintText: 'Ej: Av. 10 de Agosto',
            ),
            validator: (v) => Validadores.validarTexto(v, 'Dirección'), 
          ),
          const Divider(color: AppTheme.grisClaro, height: 30, thickness: 0.5),

          Text('Vincular Representante',
              style: GoogleFonts.montserrat(
                  color: AppTheme.negroPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
                backgroundColor: AppTheme.tonoIntermedio.withOpacity(0.3), 
                child: const FaIcon(FontAwesomeIcons.solidUser, color: AppTheme.negroPrincipal, size: 18)),
            title: Text('Representante Asignado', style: GoogleFonts.montserrat(color: AppTheme.tonoIntermedio)),
            subtitle: Text(_representanteNombreSeleccionado, style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.w600, fontSize: 15)),
            trailing: ElevatedButton(
              onPressed: _buscarYSeleccionarRepresentante,
              child: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secundario,
                foregroundColor: AppTheme.acentoBlanco,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const Divider(color: AppTheme.grisClaro, height: 30, thickness: 0.5),

          Text('Información Adicional',
              style: GoogleFonts.montserrat(
                  color: AppTheme.negroPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alergiasCtrl,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
            decoration: _inputDecoration(
                label: 'Alergias (Opcional)',
                icon: FontAwesomeIcons.prescriptionBottle),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _obsCtrl,
            style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal),
            decoration: _inputDecoration(
                label: 'Observaciones (Opcional)',
                icon: FontAwesomeIcons.noteSticky),
            maxLines: 3,
          ),
        ]),
      ),
    );
  }

  // Agrupa la foto del perfil y el botón de carga en la columna derecha
  Widget _buildRightColumn() {
    return Card(
      color: AppTheme.fondoClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Foto del Estudiante',
              style: GoogleFonts.montserrat(
                  color: AppTheme.negroPrincipal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildPhotoSelector(),
        ]),
      ),
    );
  }
}

