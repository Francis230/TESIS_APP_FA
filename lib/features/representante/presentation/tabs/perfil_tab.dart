// Archivo - lib/features/representante/presentation/tabs/perfil_tab.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:tesis_appmovilfaj/app/app_theme.dart';
import 'package:tesis_appmovilfaj/providers/auth_provider.dart';
import 'package:tesis_appmovilfaj/providers/representante_provider.dart';
import 'package:tesis_appmovilfaj/core/utils/validadores.dart';
// Esta clase define la interfaz de perfil utilizada por el representante del estudiante
class PerfilTabRepresentante extends ConsumerStatefulWidget {
  const PerfilTabRepresentante({super.key});

  @override
  ConsumerState<PerfilTabRepresentante> createState() =>
      _PerfilTabRepresentanteState();
}
// Esta clase gestiona la visualización, edición y validación de los datos del perfil
class _PerfilTabRepresentanteState
    extends ConsumerState<PerfilTabRepresentante> {
  // Controladores y Clave de Formulario 
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _parentescoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _nuevaFotoSeleccionada;
  Uint8List? _nuevaFotoBytes;
  bool _isInitialized = false;
  bool _isSaving = false;

  // Inicializa los datos del perfil al cargar la información desde la base de datos
  void _inicializarControladores(Map<String, dynamic> perfil) {
    if (_isInitialized) return;
    _nombreController.text = perfil['nombre_completo'] ?? '';
    _correoController.text = perfil['correo'] ?? '';
    _telefonoController.text = perfil['telefono'] ?? '';
    _parentescoController.text = perfil['parentesco'] ?? '';
    _cedulaController.text = perfil['documento_identidad'] ?? '';
    _direccionController.text = perfil['direccion'] ?? '';
    _isInitialized = true;
  }

  // Permite al representante seleccionar una imagen desde el dispositivo
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _nuevaFotoSeleccionada = image;
      _nuevaFotoBytes = bytes;
    });
  }
  
  // Traduce errores técnicos en mensajes comprensibles para el usuario.
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");

    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "guardar") {
      return 'Error al guardar tu perfil. Verifica tus datos.';
    }
    if (contexto == "eliminar") {
      return 'Error al eliminar tu perfil. Inténtalo de nuevo.';
    }
    return 'Ocurrió un error inesperado.';
  }
  // Muestra mensajes emergentes cuando ocurre un error
  Future<void> _mostrarDialogoError(String titulo, String mensaje) async {
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
  // Muestra mensajes emergentes cuando la operación finaliza correctamente
  Future<void> _mostrarDialogoExito(String titulo, String mensaje) async {
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
  // Notifica al usuario mediante mensajes temporales en pantalla
  void _mostrarToastOscuro(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.negroPrincipal,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/bool/correct.json',
                height: 30,
                width: 30,
                repeat: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only( 
          bottom: 120,
          left: 24,
          right: 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Valida y guarda los cambios realizados en el perfil del representante
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) { 
      return;
    }
    
    setState(() => _isSaving = true);
    
    final repo = ref.read(representanteRepositoryProvider);
    String? newPhotoUrl;

    try {
      if (_nuevaFotoBytes != null && _nuevaFotoSeleccionada != null) {
        final bytes = _nuevaFotoBytes!;
        String mimeType = _nuevaFotoSeleccionada!.mimeType ?? 'image/png';
        String ext = mimeType.split('/').last;
        if (ext == 'jpeg') ext = 'jpg';
        if (!['jpg', 'png', 'gif', 'webp'].contains(ext)) ext = 'png';
        
        newPhotoUrl = await repo.uploadProfilePhoto(bytes, ext, mimeType);
      }

      final datosPerfil = {
        'nombre_completo': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'documento_identidad': _cedulaController.text.trim(),
        'direccion': _direccionController.text.trim(),
        if (newPhotoUrl != null) 'foto_url': newPhotoUrl,
      };
      
      final datosRepresentante = {
        'parentesco': _parentescoController.text.trim(),
      };

      await repo.actualizarMiPerfil(datosPerfil, datosRepresentante);

      final nuevoPerfil = await ref.refresh(miPerfilProvider.future);

      if (nuevoPerfil != null && mounted) {
        setState(() {
          _isInitialized = false;
          _inicializarControladores(nuevoPerfil);
          _nuevaFotoSeleccionada = null;
          _nuevaFotoBytes = null;
        });
      }

      if (!mounted) return;
      await _mostrarDialogoExito(
        "¡Éxito!", 
        "Tu perfil ha sido actualizado correctamente."
      );

    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogoError(
        "Error al Guardar", 
        _traducirError(e, "guardar")
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
    // Solicita confirmación antes de eliminar el perfil del representante
    void _confirmarEliminarPerfil() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar Perfil',
          style: GoogleFonts.montserrat(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro? Esta acción es permanente y desvinculará a tus estudiantes. No se puede deshacer.',
          style: GoogleFonts.montserrat(color: Colors.black87),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: AppTheme.acentoBlanco,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              
              try {
                await ref.read(representanteRepositoryProvider).eliminarMiPerfil();
                
                if (!mounted) return;
                await _mostrarDialogoExito("Perfil Eliminado", "Tu perfil ha sido eliminado permanentemente.");
                
                if (mounted) {
                   context.go('/login');
                  _mostrarToastOscuro("Cuenta eliminada exitosamente.");
                }

              } catch (e) {
                if (!mounted) return;
                await _mostrarDialogoError("Error", _traducirError(e, "eliminar"));
              } finally {
                  if (mounted) setState(() => _isSaving = false);
              }
            },
            child: Text(
              'Eliminar Permanentemente',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose(); 
    _telefonoController.dispose();
    _parentescoController.dispose();
    _cedulaController.dispose();
    _direccionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Obtiene los datos actuales del perfil del representante
    final perfilAsync = ref.watch(miPerfilProvider);

    return Scaffold(
      // Presenta una interfaz dedicada a la gestión del perfil
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
      backgroundColor: AppTheme.negroPrincipal,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () {
                _isInitialized = false;
                return ref.refresh(miPerfilProvider.future);
            },
            color: AppTheme.acentoBlanco,
            backgroundColor: AppTheme.azulFuerte,
            child: perfilAsync.when(
              data: (perfil) {
                if (perfil == null) {
                  return _buildEstadoError(
                    "Perfil no encontrado",
                    "No pudimos cargar los datos. Intenta de nuevo.",
                    FontAwesomeIcons.userSlash,
                  );
                }
                
                if (!_isInitialized) {
                  _inicializarControladores(perfil);
                }
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTarjetaPerfilHeader(perfil),
                        const SizedBox(height: 20),
                        _buildTarjetaInfoPersonal("Información Personal"),
                        const SizedBox(height: 20),
                        _buildTarjetaSeguridad(context),
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
                              icon: const FaIcon(FontAwesomeIcons.solidFloppyDisk, size: 18),
                              label: Text(
                                'Guardar Cambios',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: _isSaving ? null : _guardarCambios,
                          ),
                        ),
                        const SizedBox(height: 16),
                          SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                elevation: 0,
                              ),
                              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 18),
                              label: Text(
                                'Eliminar Perfil',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: _isSaving ? null : _confirmarEliminarPerfil,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.azulFuerte)),
              error: (err, stack) => _buildEstadoError(
                "Error al cargar perfil",
                _traducirError(err, "cargar"), 
                FontAwesomeIcons.cloud,
              ),
            ),
          ),
          
          if (_isSaving)
            Container(
              color: AppTheme.negroPrincipal.withOpacity(0.7),
              child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.fondoClaro)),
            ),
        ],
      ),
    );
  }

  // Muestra la información principal del perfil del representante
  Widget _buildTarjetaPerfilHeader(Map<String, dynamic> perfil) {
    final fotoUrl = perfil['foto_url'] as String?;
    ImageProvider? previewImage;
    if (_nuevaFotoBytes != null) {
      previewImage = MemoryImage(_nuevaFotoBytes!);
    } else if (fotoUrl != null && fotoUrl.isNotEmpty) {
      previewImage = NetworkImage(fotoUrl);
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
                      ? FaIcon(FontAwesomeIcons.userLarge, size: 50, color: AppTheme.tonoIntermedio)
                      : null,
                ),
                if (!_isSaving)
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Material(
                      color: AppTheme.negroPrincipal,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isSaving ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: const FaIcon(FontAwesomeIcons.camera, size: 16, color: AppTheme.fondoClaro),
                        ),
                      ),
                    ),
                  ),
                if (_nuevaFotoSeleccionada != null)
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
                            _nuevaFotoSeleccionada = null;
                            _nuevaFotoBytes = null;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                if (_isSaving)
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
            
            // Campo de Nombre 
            _buildTextFormField(
              controller: _nombreController,
              label: "Nombre Completo",
              icon: FontAwesomeIcons.solidUser,
              isDark: false,
              hintText: 'Ej: Juan Pérez',
              validator: (v) => Validadores.validarTexto(v, "Nombre"), 
            ),
            const SizedBox(height: 12),
            
            // Correo 
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.solidEnvelope, color: AppTheme.tonoIntermedio, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    _correoController.text,
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
  // El sistema agrupa los datos personales del representante en una sección editable
  Widget _buildTarjetaInfoPersonal(String titulo) {
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
            Text(
              titulo,
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.negroPrincipal),
            ),
            const Divider(color: AppTheme.grisClaro, height: 24, thickness: 0.5),
            _buildTextFormField(
              controller: _telefonoController,
              label: 'Teléfono',
              icon: FontAwesomeIcons.phone,
              keyboardType: TextInputType.phone,
              isDark: false,
              hintText: 'Ej: 0912345678',
              validator: Validadores.validarTelefono,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _parentescoController,
              label: "Parentesco",
              icon: FontAwesomeIcons.peopleRoof,
              isDark: false,
              hintText: 'Ej: Padre, Madre, Tío...',
              validator: (v) => Validadores.validarTexto(v, "Parentesco"),
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _cedulaController,
              label: "Cédula",
              icon: FontAwesomeIcons.solidIdCard,
              keyboardType: TextInputType.number,
              isDark: false,
              hintText: '10 dígitos',
              validator: Validadores.validarIdentificacion,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _direccionController,
              label: "Dirección",
              icon: FontAwesomeIcons.mapLocationDot,
              isDark: false,
              hintText: 'Ej: Av. Amazonas y Colón',
              validator: (v) => Validadores.validarTexto(v, "Dirección"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    bool isDark = true,
    String? hintText, 
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

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(color: textColor),
      cursorColor: focusedBorderColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: labelColor),
        hintText: hintText, 
        hintStyle: GoogleFonts.montserrat(color: labelColor.withOpacity(0.7)), 
        
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14.0, right: 10.0),
          child: FaIcon(icon, color: iconColor, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        
        filled: true,
        fillColor: readOnly ? (isDark ? fillColor.withOpacity(0.5) : AppTheme.grisClaro.withOpacity(0.1)) : fillColor, 
        
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
            borderSide: BorderSide(color: focusedBorderColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: validator,
    );
  }


  // Presenta opciones relacionadas con la seguridad de la cuenta
  Widget _buildTarjetaSeguridad(BuildContext context) {
    return Card(
      color: AppTheme.fondoClaro,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading:
            const FaIcon(FontAwesomeIcons.lock, color: AppTheme.tonoIntermedio, size: 20),
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


  // Muestra un estado visual cuando ocurre un error
  Widget _buildEstadoError(String titulo, String subtitulo, IconData icono) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        decoration: BoxDecoration(
          color: AppTheme.fondoClaro,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.grisClaro.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icono, size: 50, color: AppTheme.azulFuerte),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.negroPrincipal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppTheme.tonoIntermedio,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
