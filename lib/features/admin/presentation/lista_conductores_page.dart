// Archivo - lib/features/admin/presentation/lista_conductores_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../data/admin_repository.dart';
import '../../../app/app_theme.dart';
import 'editar_conductor.dart';
// Presenta el directorio de conductores permitiendo su visualización, filtrado y gestión administrativa
class ListaConductoresPage extends StatefulWidget {
  const ListaConductoresPage({super.key});

  @override
  State<ListaConductoresPage> createState() => _ListaConductoresPageState();
}

class _ListaConductoresPageState extends State<ListaConductoresPage> {
  final _repo = AdminRepository();
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _rutas = [];
  List<Map<String, dynamic>> _rutasOrdenadas = [];
  bool _cargando = true;
  String? _rutaSeleccionadaId;

  @override
  void initState() {
    super.initState();
    // Inicia la recuperación de datos al abrir la pantalla
    _cargarDatos();
  }
 // Analiza el nombre de la ruta para permitir un ordenamiento numérico lógico en el filtro
  int _extraerNumeroRuta(String nombreRuta) {
    final match = RegExp(r'\d+').firstMatch(nombreRuta);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '99999') ?? 99999;
    }
    return 99999;
  }
  // Recupera y organiza la información actualizada de personal y rutas desde la base de datos
  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final rutasData = await _repo.listarRutas(); 
      
      List<Map<String, dynamic>> conductoresData;
      
      if (_rutaSeleccionadaId == 'RESERVA') {
        conductoresData = await _repo.getConductoresEnReserva();
      } else {
        conductoresData = await _repo.buscarConductores(rutaId: _rutaSeleccionadaId);
      }

      _conductores = conductoresData;
      _rutas = rutasData;
      _rutasOrdenadas = List<Map<String, dynamic>>.from(_rutas);
      _rutasOrdenadas.sort((a, b) {
        final nombreA = a['numero_ruta']?.toString() ?? '';
        final nombreB = b['numero_ruta']?.toString() ?? '';
        final numA = _extraerNumeroRuta(nombreA);
        final numB = _extraerNumeroRuta(nombreB);
        return numA.compareTo(numB);
      });
      setState(() {});
    } catch (e) {
      if (mounted) {
        await _mostrarError(_traducirError(e, "cargar datos"));
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }
  // Verifica la carga de trabajo del conductor para determinar el protocolo de desactivación adecuado
  Future<void> _iniciarFlujoEliminacion(Map<String, dynamic> conductor) async {
    final conductorId = conductor['conductor_id'];
    final nombreConductor = conductor['perfiles']?['nombre_completo'] ?? 'el conductor';

    setState(() => _cargando = true);
    int studentCount = 0;
    try {
      studentCount = await _repo.getEstudiantesCountForConductor(conductorId); 
    } catch (e) {
      await _mostrarError(_traducirError(e, "verificar estudiantes"));
      setState(() => _cargando = false);
      return;
    }
    setState(() => _cargando = false);
    
    if (studentCount == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Desactivar Conductor', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text('Este conductor no tiene estudiantes asignados. ¿Desea marcarlo como "inactivo"? (No podrá iniciar sesión).', style: GoogleFonts.montserrat(color: Colors.black87)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: GoogleFonts.montserrat(color: AppTheme.grisClaro, fontWeight: FontWeight.w600))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Sí, Desactivar', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600))
            ),
          ],
        ),
      ) ?? false;

      if (confirm) {
        try {
          await _repo.desactivarConductor(conductorId: conductorId); 
          await _mostrarExito('Conductor desactivado con éxito.');
          await _cargarDatos();
        } catch (e) {
          await _mostrarError(_traducirError(e, "desactivar"));
        }
      }
    
    } else {
      await _mostrarDialogoDeReemplazo(conductor, studentCount);
    }
  }
  // Gestiona la transferencia obligatoria de estudiantes a un conductor suplente antes de la eliminación
  Future<void> _mostrarDialogoDeReemplazo(Map<String, dynamic> conductorOriginal, int studentCount) async {
    final String originalId = conductorOriginal['conductor_id'];
    final String nombreOriginal = conductorOriginal['perfiles']?['nombre_completo'] ?? 'Conductor';
    
    setState(() => _cargando = true);
    List<Map<String, dynamic>> reemplazosPotenciales = [];
    try {
      reemplazosPotenciales = await _repo.getConductoresEnReserva(); 
      reemplazosPotenciales.removeWhere((c) => c['conductor_id'] == originalId);
    } catch (e) {
      await _mostrarError(_traducirError(e, "buscar reemplazos"));
      setState(() => _cargando = false);
      return;
    }
    setState(() => _cargando = false);
    
    if (reemplazosPotenciales.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const FaIcon(FontAwesomeIcons.circleExclamation, size: 40, color: Colors.orange),
          title: Text('Sin Reemplazos', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
          content: Text('No puede eliminar a $nombreOriginal porque tiene $studentCount estudiantes.\n\nNo hay conductores "En Reserva" disponibles para transferir la carga.', textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.black87, fontSize: 14)),
          actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Entendido', style: GoogleFonts.montserrat(color: AppTheme.azulFuerte, fontWeight: FontWeight.bold))) ],
        )
      );
      return;
    }

    String? conductorReemplazoId;

    final bool confirmarReemplazo = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
          title: Row(
            children: [
              const FaIcon(FontAwesomeIcons.arrowRightArrowLeft, color: AppTheme.azulFuerte, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Reemplazo Requerido', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal, fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conductor Saliente:', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    Text(nombreOriginal, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.negroPrincipal)),
                    const SizedBox(height: 4),
                    Text('⚠️ Tiene $studentCount estudiantes y ruta asignada.', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.redAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Seleccione al nuevo responsable:', style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              
              // Diseño del filtro
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: 'Conductor Entrante',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.azulFuerte),
                  filled: true,
                  fillColor: Colors.grey.shade100, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppTheme.azulFuerte, width: 2)),
                ),
                dropdownColor: AppTheme.secundario, 
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.azulFuerte),
                
                // 1. Texto seleccionado (Debe ser NEGRO sobre el fondo gris claro)
                selectedItemBuilder: (BuildContext context) {
                  return reemplazosPotenciales.map<Widget>((c) {
                    final perfil = c['perfiles'] ?? {};
                    return Text(
                      perfil['nombre_completo'] ?? 'Sin nombre',
                      style: GoogleFonts.montserrat(color: AppTheme.negroPrincipal, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    );
                  }).toList();
                },

                // 2. Texto en la lista (Debe ser BLANCO sobre el fondo oscuro)
                items: reemplazosPotenciales.map<DropdownMenuItem<String?>>((c) {
                  final perfil = c['perfiles'] ?? {};
                  return DropdownMenuItem<String?>(
                    value: c['conductor_id'] as String?,
                    child: Text(
                      perfil['nombre_completo'] ?? 'Sin nombre',
                      style: GoogleFonts.montserrat(color: Colors.white), 
                    ),
                  );
                }).toList(),
                
                onChanged: (v) => conductorReemplazoId = v,
                validator: (v) => v == null ? 'Seleccione un conductor' : null,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    child: Text('Cancelar', style: GoogleFonts.montserrat(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (conductorReemplazoId != null) Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.azulFuerte,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    child: Text('Transferir', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        );
      },
    ) ?? false;

    if (confirmarReemplazo && conductorReemplazoId != null) {
      setState(() => _cargando = true);
      try {
        await _repo.reemplazarYDesactivarConductor( 
          conductorOriginalId: originalId,
          conductorReemplazoId: conductorReemplazoId!,
        );
        await _mostrarExito('Reemplazo completado. Los estudiantes y la ruta fueron transferidos.');
        await _cargarDatos();
      } catch (e) {
        await _mostrarError(_traducirError(e, "reemplazar conductor"));
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  // Convierte las excepciones técnicas en mensajes claros para la interfaz de usuario
  String _traducirError(Object e, String contexto) {
    final errorStr = e.toString().toLowerCase();
    print("Error original en $contexto: $errorStr");
    if (errorStr.contains('network request failed')) {
      return 'No se pudo conectar al servidor. Revisa tu conexión a internet.';
    }
    if (contexto == "cargar datos") {
      return 'Error al cargar los datos de conductores.';
    }
    if (contexto == "desactivar") {
      return 'Error al intentar desactivar el conductor.';
    }
    if (contexto == "reemplazar conductor") {
      return 'Error al procesar el reemplazo. Intente de nuevo.';
    }
    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
  // Despliega una alerta visual estilizada para informar sobre fallos en el proceso
  Future<void> _mostrarError(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Lottie.asset('assets/animations/bool/error.json', height: 100, repeat: false),
        title: Text("Error",
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
  Future<void> _mostrarExito(String mensaje) async {
    if (!mounted) return;
    await showDialog(
      context: context,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Aceptar'),
            )
          ],
        );
      },
    );
  }
  // Diseña la tarjeta individual que resume los datos clave y acciones del conductor
  Widget _buildItem(Map<String, dynamic> c) {
    final perfil = c['perfiles'] != null ? Map<String, dynamic>.from(c['perfiles']) : <String, dynamic>{};
    final ruta = c['rutas'] != null ? Map<String, dynamic>.from(c['rutas']) : <String, dynamic>{};
    final nombre = perfil['nombre_completo'] ?? 'Sin nombre';
    final telefono = perfil['telefono'] ?? '-';
    final fotoUrl = perfil['foto_url'] as String?;
    final estaEnReserva = c['numero_ruta_asignada'] == null;
    final textoRuta = ruta['numero_ruta'] ?? (estaEnReserva ? 'En Reserva' : 'Sin asignar'); 

    return Card(
      color: AppTheme.secundario,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.azulFuerte,
          backgroundImage: (fotoUrl != null) ? NetworkImage(fotoUrl) : null,
          child: (fotoUrl == null)
              ? const FaIcon(
                  FontAwesomeIcons.user,
                  color: Colors.white,
                  size: 24,
                )
              : null,
        ),
        
        title: Text(nombre,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          'Tel: $telefono\nRuta: $textoRuta',
          style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 13)),
        isThreeLine: true,
        
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: AppTheme.secundario,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (v) async {
            if (v == 'editar') {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => EditarConductorPage(conductorData: c, rutasDisponibles: _rutasOrdenadas)),
              );
              if (updated == true && mounted) {
                await _cargarDatos();
              }
            }
            if (v == 'eliminar') {
              await _iniciarFlujoEliminacion(c);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'editar', child: Text('Editar conductor', style: TextStyle(color: Colors.white))),
            PopupMenuItem(value: 'eliminar', child: Text('Eliminar/Desactivar', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
        
        onTap: () async {
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  EditarConductorPage(conductorData: c, rutasDisponibles: _rutasOrdenadas),
            ),
          );
          if (updated == true && mounted) {
            await _cargarDatos();
          }
        },
      ),
    );
  }
  // Construye la interfaz principal con la barra de navegación y el filtro de rutas
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.negroPrincipal,
      appBar: AppBar(
        title: const Text('Conductores'),
        backgroundColor: AppTheme.negroPrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String?>(
              value: _rutaSeleccionadaId,
              decoration: InputDecoration(
                labelText: 'Filtrar por Ruta',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppTheme.secundario,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas las Rutas', style: TextStyle(color: Colors.white))),
                const DropdownMenuItem(
                  value: 'RESERVA',
                  child: Text('Conductores en Reserva', style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                ),
                // Utilizando las rutas ordenadas
                ..._rutasOrdenadas.map((r) => DropdownMenuItem( 
                  value: r['ruta_id'],
                  child: Text(r['numero_ruta'] ?? 'Sin número', style: const TextStyle(color: Colors.white)),
                )),
              ],
              dropdownColor: AppTheme.secundario,
              onChanged: (v) {
                setState(() {
                  _rutaSeleccionadaId = v;
                });
                _cargarDatos();
              },
            ),
          ),
        ),
      ),
      // Muestra el listado de resultados o un indicador de estado carga o vacio
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _conductores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.userSlash, color: Colors.white24, size: 50),
                      SizedBox(height: 16),
                      Text('No se encontraron conductores',
                          style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDatos,
                  color: AppTheme.azulFuerte,
                  backgroundColor: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conductores.length,
                    itemBuilder: (context, index) =>
                        _buildItem(_conductores[index]),
                  ),
                ),
    );
  }
}




