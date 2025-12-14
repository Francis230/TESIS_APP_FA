// Archivo - lib/app/app_router.dart
// Router principal usado por la aplicación (GoRouter).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tesis_appmovilfaj/features/admin/presentation/lista_conductores_page.dart';
import 'package:tesis_appmovilfaj/features/admin/presentation/rutas_page.dart';
import 'package:tesis_appmovilfaj/features/auth/presentation/cambio_clave_perfil.dart';
import 'package:tesis_appmovilfaj/features/auth/presentation/inicio_pantalla.dart';

// Importaciones de pantallas de autenticación
import '../features/auth/presentation/login_pantalla.dart';
import '../features/auth/presentation/registro_pantalla.dart';
import '../features/auth/presentation/cambio_clave_pantalla.dart';
import '../features/auth/presentation/solicitar_recuperacion_pantalla.dart';
import '../features/auth/presentation/aplicar_nueva_clave_pantalla.dart';

// Importaciones de pantallas del administrador
import '../features/admin/presentation/admin_dashboard.dart';
import '../features/admin/presentation/registrar_conductor.dart';
import '../features/admin/presentation/perfil_admin.dart';

// Importaciones de pantallas de conductor
import '../features/conductor/presentation/conductor_home.dart';
import '../features/conductor/presentation/lista_asistencia.dart';
import '../features/conductor/presentation/registrar_editar_estudiante.dart';

// Importaciones de pantallas de representante
import '../features/representante/presentation/representante_home.dart';
import '../features/representante/presentation/mapa_bus.dart';

// Importaciones de pantallas de notificaciones
import '../features/notificaciones/presentation/lista_notificaciones.dart';

final GoRouter appRouter = GoRouter(
 initialLocation: '/inicio',
 routes: <GoRoute>[
  GoRoute(
      path: '/inicio',
      name: 'inicio',
      builder: (context, state) => const InicioPantalla(),
    ),
  GoRoute(
   path: '/login',
   name: 'login',
   builder: (context, state) => const LoginPantalla(),
  ),
  GoRoute(
   path: '/registro',
   name: 'registro',
   builder: (context, state) => const RegistroPantalla(),
  ),
  // Actualizacion de clave para usuarios que ya están dentro logueados.
  GoRoute(
   path: '/cambio-clave',
   name: 'cambioClave',
   builder: (context, state) => const CambioClavePerfil(),
  ),
  GoRoute(
  path: '/clave-temporal-obligatoria',
  name: 'claveTemporalObligatoria',
  builder: (context, state) => const ClaveTemporalObligatoriaPantalla(),
  ),
  // Solicitud de recuperacion de contraseña con el correo
  GoRoute(
   path: '/solicitar-recuperacion',
   name: 'solicitarRecuperacion',
   builder: (context, state) => const SolicitarRecuperacionPantalla(),
  ),
  GoRoute(
    path: '/verificar-codigo',
    name: 'verificarCodigo',
    builder: (context, state) {
      // Extracion del correo de la pantalla anterior
      final email = state.extra as String?;
      if (email == null) {
        // Si por alguna razón no se pasa el email, redirigimos por seguridad
        return const SolicitarRecuperacionPantalla();
      }
      return AplicarNuevaClavePantalla(email: email);
    },
  ),
    // Aplicacion de nueva contraseña antes de iniciar sesin
  GoRoute(
   path: '/aplicar-nueva-clave', 
   name: 'aplicarNuevaClave',
   // La llamada al constructor fue el error, que debe ser la clase del widget.
   builder: (context, state) => AplicarNuevaClavePantalla(email: state.queryParams['email'] ?? ''),
  ),

  // Rutas del administrador
  GoRoute(
   path: '/admin',
   name: 'admin',
   builder: (context, state) => const AdminDashboard(),
   routes: [
    GoRoute(
     path: 'registrar-conductor',
     name: 'registrarConductor',
     builder: (context, state) => const RegistrarConductor(),
    ),
    GoRoute(
     path: 'rutas',
     name: 'rutas',
     builder: (context, state) => const RutasPage(),
    ),
    GoRoute(
     path: 'conductores',
     name: 'listaConductores',
     builder: (context, state) => const ListaConductoresPage(),
    ),
    GoRoute(
     path: 'perfil',
     name: 'perfilAdmin',
     builder: (context, state) => const AdminDashboard(),
    ),
   ],
  ),

  // Rutas del conductor
  GoRoute(
   path: '/conductor',
   name: 'conductor',
   builder: (context, state) => const ConductorHome(),
   routes: [
    GoRoute(
     path: 'asistencia',
     name: 'listaAsistencia',
     builder: (context, state) => const ListaAsistencia(),
    ),
    GoRoute(
      path: 'formulario-estudiante',
      name: 'formularioEstudiante',
      builder: (context, state) {
        // Recibimos el mapa del estudiante si se está editando.
        final estudiante = state.extra as Map<String, dynamic>?;
        return RegistrarEditarEstudiantePage(estudiante: estudiante);
      },
    ),
   ],
  ),

  // Rutas del representante
  GoRoute(
   path: '/representante',
   name: 'representante',
   builder: (context, state) => const RepresentanteHomePage(),
  ),

  // Notificaciones (global)
  GoRoute(
   path: '/notificaciones',
   name: 'notificaciones',
   builder: (context, state) => const ListaNotificaciones(),
  ),
 ],
);