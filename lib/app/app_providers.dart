// Archivo - lib/app/app_providers.dart
// Proveedores globales que inicializan servicios centrales.

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../servicios/supabase_servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider que devuelve la instancia de SupabaseClient.
// Se define para centralizar la dependencia y facilitar pruebas unitarias.
final supabaseClientProvider = riverpod.Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider para almacenar la sesión actual.
// El estudiante usa un StateProvider simple para leer/escribir la sesión.
final sesionProvider = riverpod.StateProvider<AuthResponse?>((ref) {
  // Se deja null por defecto, luego el flujo de autenticación actualizará esto.
  return null;
});

// Provider para almacenar el perfil del usuario autenticado.
// Se usa Map<String, dynamic> para facilidad de mapeo con Supabase.
final perfilProvider = riverpod.StateProvider<Map<String, dynamic>?>((ref) => null);

// Provider que controla si el conductor está compartiendo ubicación.
// Se usa para activar/desactivar el envío de lat/lng al backend.
final conductorCompartiendoUbicacionProvider = riverpod.StateProvider<bool>((ref) => false);
