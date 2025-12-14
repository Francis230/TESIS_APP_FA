// Archivo - lib/providers/auth_provider.dart
// Provider de autenticación
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../servicios/supabase_servicio.dart';

// Provider del cliente de Supabase
final supabaseProvider = rp.Provider<SupabaseClient>((ref) {
  return SupabaseServicio.cliente();
});

// Provider del estado de la sesión actual
final sesionProvider = rp.StreamProvider<AuthState>((ref) {
  final supabase = ref.read(supabaseProvider);
  return supabase.auth.onAuthStateChange;
});

// Provider del usuario autenticado
final usuarioProvider = rp.Provider<User?>((ref) {
  final sesion = ref.watch(sesionProvider).asData?.value.session;
  return sesion?.user;
});
