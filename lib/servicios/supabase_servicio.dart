// Archivo - lib/servicio/supabase_servicio.dart
// Servicio que inicializa la conexión con Supabase y provee un cliente global
import 'package:supabase_flutter/supabase_flutter.dart';
class SupabaseServicio {
  // Inicializa la instancia de las credenciales de Supabase
  static Future<void> inicializar() async {
    await Supabase.initialize(
      url: 'https://helpdjfhqnnszqgjcyuu.supabase.co',       
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhlbHBkamZocW5uc3pxZ2pjeXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyOTc0NjQsImV4cCI6MjA2Mzg3MzQ2NH0.3uCIEkgCnMvdEY1Ul8wUnnvFdXot-2Q8_1EhLHbhtEg', // <-- reemplazar por tu ANON KEY
    );
  }
  // Devuelve el cliente global de Supabase
  static SupabaseClient cliente() => Supabase.instance.client;
}
