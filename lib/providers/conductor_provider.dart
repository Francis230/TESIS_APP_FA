// Archivo - lib/providers/conductor_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/conductor/data/conductor_repository.dart';

// Provider para manejar el estado de los conductores.
// Permite escuchar ubicación y lista de estudiantes asignados.
final conductorRepositoryProvider = Provider<ConductorRepository>((ref) {
  return ConductorRepository();
});

// Provider del estado de "compartiendo ubicación".
final compartiendoUbicacionProvider = StateProvider<bool>((ref) => false);

// Provider que obtiene los estudiantes asignados a un conductor.
final estudiantesConductorProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, conductorId) async {
  final repo = ref.read(conductorRepositoryProvider);
  return repo.obtenerEstudiantes();
});

// Provider que obtiene el historial de alertas enviadas por el conductor.
final historialEnvioProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(conductorRepositoryProvider);
  return repo.obtenerNotificacionesEnviadas();
});

// Provider para eliminar una notificación enviada por ID.
final eliminarNotificacionEnviadaProvider =
    FutureProvider.family<void, String>((ref, notificacionId) async {
  final repo = ref.watch(conductorRepositoryProvider);
  await repo.eliminarNotificacionEnviada(notificacionId);
  ref.invalidate(historialEnvioProvider);
});

// Provider para eliminar todas las notificaciones enviadas.
final eliminarTodasNotificacionesEnviadasProvider =
    FutureProvider<void>((ref) async {
  final repo = ref.watch(conductorRepositoryProvider);
  await repo.eliminarTodasNotificacionesEnviadas();
  ref.invalidate(historialEnvioProvider);
});