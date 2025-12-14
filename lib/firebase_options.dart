// Archivo - lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
// Centraliza las credenciales de configuración requeridas para inicializar los servicios de Firebase
class DefaultFirebaseOptions {
  // Detecta automáticamente el sistema operativo en ejecución para suministrar las credenciales correctas
  static FirebaseOptions get currentPlatform {
    // Prioriza la detección del entorno web antes de verificar sistemas operativos móviles
    if (kIsWeb) {
      return web;
    }
    // Evalúa el sistema operativo nativo y selecciona la configuración correspondiente
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform no está soportado en iOS.',
        );
      case TargetPlatform.macOS:
         throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform no está soportado en macOS.',
        );
      case TargetPlatform.windows:
         throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform no está soportado en Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform no está soportado en Linux.',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada por DefaultFirebaseOptions.',
        );
    }
  }

  // Define el conjunto de claves e identificadores específicos para el entorno web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCY6zUdj6vg9clo6y7UWGydU9Vc82Vh_kQ',
    appId: '1:462202276137:web:64f50fd7edb1673a370f38',
    messagingSenderId: '462202276137',
    projectId: 'tesisemaus',
    authDomain: 'tesisemaus.firebaseapp.com',
    storageBucket: 'tesisemaus.firebasestorage.app',
  );
  // Contiene las credenciales nativas necesarias para la conexión en dispositivos Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAippsL_FS1gcHvTcKSyH2rCPe9bKQtGE4', 
    appId: '1:462202276137:android:3b5aad45ebfb6268370f38',
    messagingSenderId: '462202276137',
    projectId: 'tesisemaus',
    storageBucket: 'tesisemaus.firebasestorage.app',
  );

}