// Archivo - lib/features/conductor/presentation/tabs/perfil_tab.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/core/utils/validadores.dart'; 
import 'package:tesis_appmovilfaj/core/widgets/boton_principal.dart';
import 'package:tesis_appmovilfaj/features/conductor/data/conductor_repository.dart';
// Gestión de la visualización y edición de la información personal y los datos del vehículo del conductor
class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  final _repositorioConductor = ConductorRepository();
  final _seleccionadorImagen = ImagePicker();  
  final _formKey = GlobalKey<FormState>();
  // Controladores para capturar y modificar los datos del formulario
  final _controladorNombre = TextEditingController();
  final _controladorTelefono = TextEditingController();
  final _controladorDireccion = TextEditingController();
  final _controladorPlaca = TextEditingController();

  bool _estaCargando = true;
  bool _estaGuardando = false;
  Map<String, dynamic>? _datosPerfil;
  String? _urlFoto;
  String _correoUsuario = '';
  XFile? _fotoSeleccionadaParaPreview;
  Uint8List? _fotoBytesPreview;

  @override
  void initState() {
    super.initState();
    // Inicia la recuperación de los datos del perfil al cargar la pantalla
    _cargarDatos();
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorTelefono.dispose();
    _controladorDireccion.dispose();
    _controladorPlaca.dispose();
    super.dispose();
  }
  // Recupera la información actual del conductor y del vehículo
  Future<void> _cargarDatos() async {
    setState(() => _estaCargando = true);
    try {
      final datosDesdeRepo = await _repositorioConductor.cargarConductoresPerfil(); 
      if (datosDesdeRepo != null && mounted) {
        setState(() {
          _datosPerfil = datosDesdeRepo;
          _urlFoto = datosDesdeRepo['foto_url'];
          _correoUsuario = datosDesdeRepo['correo'] ?? 'Correo no disponible';
          _controladorNombre.text = datosDesdeRepo['nombre_completo'] ?? '';
          _controladorTelefono.text = datosDesdeRepo['telefono'] ?? '';
          _controladorDireccion.text = datosDesdeRepo['direccion'] ?? '';
          _controladorPlaca.text = datosDesdeRepo['placa_vehiculo'] ?? '';
          _fotoSeleccionadaParaPreview = null;
          _fotoBytesPreview = null;
        });
      }
    } catch (error) {
      if (mounted) {
        await _mostrarDialogoError(
          titulo: 'Error de Carga',
          mensaje: _traducirError(error, "cargar perfil"),
        );
      }
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }
  // Valida los campos, sube la nueva foto si existe y actualiza la información
  Future<void> _actualizarPerfil() async {
    // Validación del formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _estaGuardando = true);
    try {
      final idUsuario = Supabase.instance.client.auth.currentUser!.id;
      String? nuevaFotoUrl;

      if (_fotoSeleccionadaParaPreview != null) {
        final bytes = await _fotoSeleccionadaParaPreview!.readAsBytes();
        String mimeType = _fotoSeleccionadaParaPreview!.mimeType ?? 'image/png';
        String ext = mimeType.split('/').last;
        if (ext == 'jpeg') ext = 'jpg';
        if (!['jpg', 'png', 'gif', 'webp'].contains(ext)) ext = 'png';

        nuevaFotoUrl = await _repositorioConductor.subirFotoPerfilConductor(
          fotoBytes: bytes,
          mimeType: mimeType,
          fileExtension: ext,
          idUsuario: idUsuario,
        );
      }

      final datosPerfilActualizar = {
        'nombre_completo': _controladorNombre.text.trim(),
        'telefono': _controladorTelefono.text.trim(),
        'direccion': _controladorDireccion.text.trim(),
        if (nuevaFotoUrl != null) 'foto_url': nuevaFotoUrl,
      };

      final datosVehiculoActualizar = {
        'placa_vehiculo': _controladorPlaca.text.trim().toUpperCase().replaceAll('-', ''), 
      };

      await Supabase.instance.client
          .from('perfiles')
          .update(datosPerfilActualizar)
          .eq('id', idUsuario);
      await Supabase.instance.client
          .from('conductores')
          .update(datosVehiculoActualizar)
          .eq('conductor_id', idUsuario);

      if (mounted) {
        await _mostrarDialogoExito(
          titulo: '¡Éxito!',
          mensaje: 'Tu perfil ha sido actualizado correctamente.',
        );
        await _cargarDatos();
        perfilActualizadoNotifier.value = !perfilActualizadoNotifier.value;
      }
    } catch (error) {
      if (mounted) {
        await _mostrarDialogoError(
          titulo: 'Error al Guardar',
          mensaje: _traducirError(error, "guardar perfil"),
        );
      }
    } finally {
      if (mounted) setState(() => _estaGuardando = false);
    }
  }
  // Permite al usuario elegir una nueva imagen desde la galería para su perfil
  Future<void> _seleccionarFotoParaPreview() async {
    final XFile? imagen = await _seleccionadorImagen.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    setState(() {
      _fotoSeleccionadaParaPreview = imagen;
      _fotoBytesPreview = bytes;
      _urlFoto = null;
    });
  }
  // Convierte los errores técnicos en mensajes amigables para el usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cargar perfil") {
      return 'No se pudo cargar tu perfil. Intenta refrescar.';
    }
    if (contexto == "guardar perfil") {
      return 'No se pudo guardar tu perfil. Verifica tus datos e intenta de nuevo.';
    }
    return 'Ocurrió un error inesperado.';
  }
  // Despliega una alerta visual estilizada para informar sobre fallos en el proceso
  Future<void> _mostrarDialogoError({ required String titulo, required String mensaje}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text(titulo,
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
  // Muestra una confirmación visual de éxito tras completar
  Future<void> _mostrarDialogoExito({ required String titulo, required String mensaje}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Lottie.asset('assets/animations/bool/correct.json', height: 100, repeat: false),
          title: Text(titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text(mensaje, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.azulFuerte,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Aceptar', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
  // Construye la estructura visual de la pantalla con las tarjetas de información y controles
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppTheme.acentoBlanco,
          ),
        ),
        backgroundColor: AppTheme.negroPrincipal,
        elevation: 0,
      ),
      body: _estaCargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.acentoBlanco))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: AppTheme.acentoBlanco,
              backgroundColor: AppTheme.azulFuerte,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: [
                    _buildTarjetaPerfilHeader(),
                    const SizedBox(height: 20),
                    _construirTarjetaInfoPersonal(),
                    const SizedBox(height: 20),
                    _construirTarjetaInfoVehiculo(),
                    const SizedBox(height: 20),
                    _construirTarjetaSeguridad(),
                    const SizedBox(height: 30),
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
                        icon: _estaGuardando
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppTheme.negroPrincipal,
                                  strokeWidth: 2,
                                ),
                              )
                            : const FaIcon(FontAwesomeIcons.solidFloppyDisk, size: 18),
                        label: Text(
                          _estaGuardando ? 'Guardando...' : 'Guardar Cambios',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: _estaGuardando ? null : _actualizarPerfil,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
  // Muestra la imagen de perfil actual o la seleccionada para previsualización
  Widget _buildTarjetaPerfilHeader() {
    ImageProvider? previewImage;
    if (_fotoBytesPreview != null) {
      previewImage = MemoryImage(_fotoBytesPreview!);
    } else if (_urlFoto != null && _urlFoto!.isNotEmpty) {
      previewImage = NetworkImage(_urlFoto!);
    }

    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.grisClaro.withOpacity(0.5),
                  backgroundImage: previewImage,
                  child: (previewImage == null)
                      ? FaIcon(FontAwesomeIcons.userLarge,
                          size: 50, color: AppTheme.tonoIntermedio)
                      : null,
                ),
                if (!_estaGuardando)
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Material(
                      color: AppTheme.negroPrincipal,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _estaGuardando ? null : _seleccionarFotoParaPreview,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: const FaIcon(FontAwesomeIcons.camera,
                              size: 16, color: AppTheme.fondoClaro),
                        ),
                      ),
                    ),
                  ),
                if (_fotoSeleccionadaParaPreview != null)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Material(
                      color: Colors.redAccent,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          setState(() {
                            _fotoSeleccionadaParaPreview = null;
                            _fotoBytesPreview = null;
                            _urlFoto = _datosPerfil?['foto_url'];
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                if (_estaGuardando)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.negroPrincipal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _construirCampoEditable(
              controller: _controladorNombre,
              label: "Nombre Completo",
              icon: FontAwesomeIcons.solidUser,
              isDark: false,
              validator: (v) => Validadores.validarTexto(v, "Nombre"),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.solidEnvelope,
                    color: AppTheme.tonoIntermedio, size: 14),
                const SizedBox(width: 8),
                Text(
                  _correoUsuario,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.tonoIntermedio,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // Agrupa los campos de contacto personal en una tarjeta visual
  Widget _construirTarjetaInfoPersonal() {
    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información de Contacto',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.negroPrincipal)),
            const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5),
            _construirCampoEditable(
              controller: _controladorTelefono,
              label: 'Teléfono',
              icon: FontAwesomeIcons.phone,
              keyboardType: TextInputType.phone,
              isDark: false,
              validator: Validadores.validarTelefono,
            ),
            const SizedBox(height: 16),
            _construirCampoEditable(
              controller: _controladorDireccion,
              label: 'Dirección',
              icon: FontAwesomeIcons.mapLocationDot,
              isDark: false,
              validator: (v) => Validadores.validarTexto(v, "Dirección"),
            ),
          ],
        ),
      ),
    );
  }
  // Muestra los datos del vehículo asignado para su edición
  Widget _construirTarjetaInfoVehiculo() {
    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehículo Actual',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.negroPrincipal)),
            const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5),
            _construirCampoEditable(
              controller: _controladorPlaca,
              label: 'Placa del Vehículo',
              icon: FontAwesomeIcons.carOn,
              isDark: false,
              validator: Validadores.validarPlaca,
            ),
          ],
        ),
      ),
    );
  }
  // Proporciona el acceso a la función de cambio de contraseña
  Widget _construirTarjetaSeguridad() {
    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const FaIcon(FontAwesomeIcons.lock,
            color: AppTheme.tonoIntermedio, size: 20),
        title: Text(
          'Cambiar Contraseña',
          style: GoogleFonts.montserrat(
              color: AppTheme.negroPrincipal, fontWeight: FontWeight.w500),
        ),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight,
            color: AppTheme.tonoIntermedio, size: 16),
        onTap: () => context.push('/cambio-clave'),
      ),
    );
  }

  // Genera un campo de texto estandarizado con validación y diseño coherente
  Widget _construirCampoEditable({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isDark = true,
    String? Function(String?)? validator, 
  }) {
    Color textColor = isDark ? AppTheme.acentoBlanco : AppTheme.negroPrincipal;
    Color labelColor = isDark ? AppTheme.grisClaro : AppTheme.tonoIntermedio;
    Color iconColor = isDark ? AppTheme.grisClaro : AppTheme.tonoIntermedio;
    Color fillColor =
        isDark ? AppTheme.negroPrincipal.withOpacity(0.5) : AppTheme.grisClaro.withOpacity(0.2);
    Color borderColor =
        isDark ? AppTheme.tonoIntermedio : AppTheme.grisClaro.withOpacity(0.7);
    Color focusedBorderColor = AppTheme.azulFuerte;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.montserrat(color: textColor),
        cursorColor: focusedBorderColor,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: labelColor),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14.0, right: 10.0),
            child: FaIcon(icon, color: iconColor, size: 18),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: focusedBorderColor, width: 2),
          ),
          errorBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder( 
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }
}

// Notificador global de cambias 
final perfilActualizadoNotifier = ValueNotifier<bool>(false);