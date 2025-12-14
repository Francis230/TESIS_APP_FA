
// Archivo - lib/providers/representante_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tesis_appmovilfaj/features/representante/data/representante_repository.dart';

// Gestion de las dependencias y UI
// Inyecta la instancia del repositorio para centralizar el acceso a datos
final representanteRepositoryProvider = Provider<RepresentanteRepository>((ref) {
  return RepresentanteRepository();
});

// Gestiona el estado de la pestaña seleccionada en la navegación inferior
final representanteTabProvider = StateProvider<int>((ref) => 0);

// Datos del conductor - dependencias
// Obtiene el identificador del conductor asignado para iniciar la cadena de datos
final idConductorProvider = FutureProvider.autoDispose<String?>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  return repo.obtenerIdConductorAsignado();
});

// Recupera la información del perfil del conductor si existe una asignación válida
final datosConductorProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  final idConductorAsync = ref.watch(idConductorProvider);
  return idConductorAsync.when(
    data: (id) {
      if (id == null) return null; 
      return repo.obtenerDatosConductor(id);
    },
    loading: () => null, 
    error: (e, s) => throw e, 
  );
});

// Activa la escucha en tiempo real de la posición del autobús asignado
final ubicacionStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final repo = ref.watch(representanteRepositoryProvider);
  // Escucha el resultado del provider de ID
  final idConductorAsync = ref.watch(idConductorProvider);
  // Devuelve un stream vacío si no hay ID, o el stream real si lo hay
  return idConductorAsync.when(
    data: (id) {
      if (id == null) return Stream.value(null); 
      return repo.escucharUbicacionBus(id);
    },
    loading: () => Stream.value(null), 
    error: (e, s) => Stream.error(e), 
  );
});

// Datos del ususario en este caso representante 
// Carga el historial completo de notificaciones recibidas por el usuario
final notificacionesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  return repo.obtenerNotificaciones();
});
// Obtiene los datos personales y de contacto de la sesión actual
final miPerfilProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  return repo.getMiPerfil();
});
// Lista los estudiantes vinculados legalmente al representante logueado
final misEstudiantesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  return repo.obtenerEstudiantes();
});
// Ejecuta la eliminación de una notificación específica y refresca la lista
final eliminarNotificacionProvider =
    FutureProvider.family<void, String>((ref, notificacionId) async {
  final repo = ref.watch(representanteRepositoryProvider);
  await repo.eliminarNotificacion(notificacionId);
  // Refrescamos la lista de notificaciones después de eliminar
  ref.refresh(notificacionesProvider);
});
// Elimina todo el historial de alertas del usuario y actualiza la vista
final eliminarTodasNotificacionesProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(representanteRepositoryProvider);
  await repo.eliminarTodasMisNotificaciones();
  ref.refresh(notificacionesProvider);
});

// Calcula dinámicamente la cantidad de alertas pendientes de lectura
final nuevasAlertasProvider = Provider<int>((ref) {
  final notificaciones = ref.watch(notificacionesProvider).value ?? [];
  final noLeidas = notificaciones.where((n) => (n['leida'] == false || n['leida'] == null)).length;
  return noLeidas;
});
