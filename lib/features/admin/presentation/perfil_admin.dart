// ARchivo - lib/features/admin/presentation/perfil_admin.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:tesis_appmovilfaj/core/utils/validadores.dart';
import '../../../app/app_theme.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../data/admin_repository.dart';

// Gestiona la visualización y edición de la información personal y configuración del administrador
class PerfilAdminPage extends StatefulWidget {
  final VoidCallback onProfileUpdated; 
  const PerfilAdminPage({
    super.key, 
    required this.onProfileUpdated,
  });

  @override
  State<PerfilAdminPage> createState() => _PerfilAdminPageState();
}

class _PerfilAdminPageState extends State<PerfilAdminPage> {
  final AuthRepository _authRepo = AuthRepository();
  final AdminRepository _adminRepo = AdminRepository();

  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;
  bool _guardando = false;
  //Estado para saber si ya es conductor
  bool _esConductorActivo = false; 
  // Administra el contenido de los campos de texto del formulario
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  XFile? _fotoSeleccionada;
  String? _fotoUrlActual;
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Inicia la carga de datos del perfil al abrir la pantalla
    _loadPerfil();
  }
  // Recupera la información del usuario y verifica si tiene permisos de conductor activos
  Future<void> _loadPerfil() async {
    setState(() => _cargando = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      _userId = user.id;
      
      // Cargar datos del perfil
      final perfil = await _authRepo.obtenerPerfilPorId(user.id);
      
      // Verificar si también es conductor
      final esConductor = await _adminRepo.verificarSiEsConductor(user.id);

      if (perfil != null && mounted) {
        setState(() {
          _nombreCtrl.text = perfil['nombre_completo'] ?? '';
          _correoCtrl.text = perfil['correo'] ?? '';
          _telefonoCtrl.text = perfil['telefono'] ?? '';
          _direccionCtrl.text = perfil['direccion'] ?? '';
          _fotoUrlActual = perfil['foto_url'] as String?;
          _esConductorActivo = esConductor; 
        });
      }
    } catch (e) {
      if (mounted) _mostrarDialogoError(_traducirError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Despliega el formulario para registrar un vehículo y habilitar el perfil de conductor
  Future<void> _activarModoConductor() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoRegistroVehiculo(
        userId: _userId!,
        adminRepo: _adminRepo,
        onSuccess: () {
          Navigator.pop(ctx); 
          _loadPerfil(); 
          _mostrarDialogoExito("¡Perfil de Conductor Activado! Ahora puedes iniciar sesión como conductor.");
        },
      ),
    );
  }
  // Valida y almacena los cambios realizados en la información personal en la base de datos
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      await _adminRepo.actualizarConductor(
        conductorId: _userId!,
        nombreCompleto: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        fotoFile: _fotoSeleccionada,
      );

      if (mounted) {
        await _mostrarDialogoExito("Perfil actualizado correctamente");
      }
      
      widget.onProfileUpdated(); 
      await _loadPerfil(); 
      
    } catch (e) {
      if (mounted) _mostrarDialogoError(_traducirError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
  // Permite al usuario elegir una nueva imagen de perfil desde la galería del dispositivo
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _fotoSeleccionada = picked);
  }

  @override
  void dispose() {
    // Libera la memoria utilizada por los controladores de texto al cerrar la pantalla
    _nombreCtrl.dispose(); _correoCtrl.dispose(); _telefonoCtrl.dispose(); _direccionCtrl.dispose();
    super.dispose();
  }
  // Traduce los códigos de error técnicos a mensajes amigables para el usuario
  String _traducirError(Object e) => e.toString().contains('network') ? 'Revisa tu conexión a internet.' : 'Ocurrió un error inesperado.';
  // Muestra una alerta visual en caso de que ocurra un error durante el proceso
  Future<void> _mostrarDialogoError(String mensaje) async {
    if (!mounted) return;
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      icon: Lottie.asset('assets/animations/bool/error.json', height: 80, repeat: false),
      title: Text("Error", style: GoogleFonts.montserrat(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
      content: Text(mensaje, textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.black87)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar', style: TextStyle(color: Colors.black)))],
    ));
  }
  // Muestra una notificación visual de éxito tras completar una acción correctamente
  Future<void> _mostrarDialogoExito(String mensaje) async {
    if (!mounted) return;
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Lottie.asset('assets/animations/bool/correct.json', height: 80, repeat: false),
      title: Text('¡Éxito!', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.black)),
      content: Text(mensaje, textAlign: TextAlign.center),
      actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.azulFuerte, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar'))],
    ));
  }
  // Widgets de diseño
  // Crea un encabezado visual para separar las secciones del formulario
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.negroPrincipal, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  // Construye un campo de entrada de texto con estilo y validación estandarizada
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    );
  }
  // Define el estilo visual base para las tarjetas contenedoras oscuras
  BoxDecoration _buildDarkCardDecoration() {
    return BoxDecoration(
      color: AppTheme.secundario,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white24, width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5)),
      ],
    );
  }
  // Construye la estructura visual completa de la pantalla de perfil
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 211),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0))),
        backgroundColor: const Color.fromARGB(255, 211, 211, 211),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _seleccionarFoto,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: AppTheme.secundario,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        image: (_fotoSeleccionada != null)
                          ? DecorationImage(image: kIsWeb ? NetworkImage(_fotoSeleccionada!.path) : FileImage(File(_fotoSeleccionada!.path)) as ImageProvider, fit: BoxFit.cover)
                          : (_fotoUrlActual != null)
                            ? DecorationImage(image: NetworkImage(_fotoUrlActual!), fit: BoxFit.cover)
                            : null
                      ),
                      child: (_fotoSeleccionada == null && _fotoUrlActual == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.white24)
                        : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _seleccionarFoto, 
                    icon: const Icon(Icons.camera_alt, color: Color.fromARGB(179, 0, 0, 0), size: 16),
                    label: const Text('Cambiar Foto', style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)))
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Información Personal', FontAwesomeIcons.addressCard),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    decoration: _buildDarkCardDecoration(),
                    child: Column(
                      children: [
                        _buildTextField(controller: _nombreCtrl, label: 'Nombre Completo', icon: FontAwesomeIcons.user, validator: (v)=>Validadores.validarTexto(v,'Nombre')),
                        _buildTextField(controller: _telefonoCtrl, label: 'Teléfono', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone, validator: Validadores.validarTelefono),
                        _buildTextField(controller: _direccionCtrl, label: 'Dirección', icon: FontAwesomeIcons.locationDot, validator: (v)=>Validadores.validarTexto(v,'Dirección')),
                        _buildTextField(controller: _correoCtrl, label: 'Correo', icon: FontAwesomeIcons.envelope, enabled: false), 
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionHeader('Rol de Conductor', FontAwesomeIcons.carSide),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: _buildDarkCardDecoration().copyWith(
                      // Si ya es conductor, borde verde sutil, si no, normal
                      border: Border.all(color: _esConductorActivo ? Colors.green.withOpacity(0.5) : Colors.white24)
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _esConductorActivo ? Icons.check_circle : Icons.info_outline,
                              color: _esConductorActivo ? Colors.greenAccent : Colors.orangeAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _esConductorActivo 
                                  ? "Tu cuenta está habilitada para conducir." 
                                  : "No tienes perfil de conductor activo.",
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        if (!_esConductorActivo) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _activarModoConductor,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.azulFuerte,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text("Activar Modo Conductor"),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botones de acción
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () => GoRouter.of(context).push('/cambio-clave'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                        side: const BorderSide(color: Colors.white, width: 1.5), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      icon: const Icon(Icons.lock_outline, size: 20),
                      label: const Text('Actualizar Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 4, 14, 30), 
                        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: _guardando 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.save, size: 22),
                      label: Text(_guardando ? 'Guardando...' : 'Guardar Cambios', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }
}

// Ventana emergente que captura los datos del vehículo para activar el rol de conductor
class _DialogoRegistroVehiculo extends StatefulWidget {
  final String userId;
  final AdminRepository adminRepo;
  final VoidCallback onSuccess;

  const _DialogoRegistroVehiculo({required this.userId, required this.adminRepo, required this.onSuccess});

  @override
  State<_DialogoRegistroVehiculo> createState() => _DialogoRegistroVehiculoState();
}

class _DialogoRegistroVehiculoState extends State<_DialogoRegistroVehiculo> {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _licenciaCtrl = TextEditingController();
  bool _guardando = false;
  // Registra la información del vehículo y activa los permisos de conducción en el sistema
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await widget.adminRepo.activarModoConductor(
        userId: widget.userId,
        licencia: _licenciaCtrl.text.trim(),
        placa: _placaCtrl.text.trim().toUpperCase().replaceAll('-', ''),
        marca: _marcaCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
      );
      widget.onSuccess();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      setState(() => _guardando = false);
    }
  }
  // Construye el formulario de entrada de datos dentro de la ventana modal
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Activar Modo Conductor", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ingresa los datos de tu vehículo para habilitar tu perfil de conductor.", style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 15),
              _input("Placa", _placaCtrl, Validadores.validarPlaca, hint: "Ej: ABC-1234"),
              _input("Marca", _marcaCtrl, (v)=>Validadores.validarTexto(v, "Marca"), hint: "Ej: Chevrolet"),
              _input("Modelo", _modeloCtrl, (v)=>Validadores.validarTexto(v, "Modelo"), hint: "Ej: Aveo"),
              _input("Color", _colorCtrl, (v)=>Validadores.validarTexto(v, "Color"), hint: "Ej: Rojo"),
              _input("Licencia", _licenciaCtrl, Validadores.validarLicencia, type: TextInputType.number, hint: "Ej: 1712345678"),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)))),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.azulFuerte, foregroundColor: Colors.white),
          child: _guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Activar"),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, String? Function(String?) validator, {TextInputType type = TextInputType.text, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        validator: validator,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          hintText: hint, 
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: const Color(0xFFF5F5F5), 
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.azulFuerte, width: 1.5),
          ),
          
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
