# Sistema de Gestión de Transporte Escolar - EMAÚS Apliación Móvil

Aplicación móvil desarrollada en Flutter para la gestión, monitoreo y seguridad del transporte escolar de la "Unidad Educativa Particular EMAÚS". Permite el seguimiento en tiempo real de las unidades y la comunicación fluida entre conductores, padres y administradores.


---

## 🛠️ Tecnologías Usadas
* **Frontend:** Flutter (Dart)
* **Backend:** Supabase (Base de datos en tiempo real, Autenticación, Storage)
* **Mapas:** Google Maps API & Geolocator
* **Notificaciones:** Firebase Cloud Messaging (FCM)
* **Gestión de Estado:** Riverpod

## 👥 Roles y Funcionalidades

### 👮 Administrador
* Gestión total de la flota (vehículos y conductores).
* Monitoreo en tiempo real de todas las unidades.
* Creación y asignación de rutas inteligentes.
* Gestión de perfiles y roles de usuario.

### 🚌 Conductor
* Visualización de ruta asignada y lista de estudiantes.
* Envío de alertas automáticas (Inicio de recorrido, Retrasos, Llegada).
* Registro de asistencia de estudiantes al subir/bajar.
* Botón de pánico y notificaciones de emergencia.

### 👨‍👩‍👧 Representante
* Rastreo en vivo del bus escolar de su representado.
* Recepción de notificaciones push (Bus cerca, Estudiante a bordo).
* Visualización del historial de alertas.


## 🚀 Cómo ejecutar el código 

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/Francis230/TESIS_APP_FA.git)
    ```
2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Configuración:**
    * Asegúrate de tener el archivo `android/local.properties` con tu API Key de Google Maps.
    * Verifica que `google-services.json` esté en `android/app/`.
4.  **Ejecutar:**
    ```bash
    flutter run
    ```

## 🎓 Autor
* **Francis Aconda**
* **Carrera:** Tecnología en Desarrollo de Software
* **Institución:** Escuela Politécnica Nacional - ESFOT
