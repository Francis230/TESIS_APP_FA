# Sistema de Gestión de Transporte Escolar - EMAÚS (App Móvil)

Aplicación móvil desarrollada en Flutter para la gestión, monitoreo y seguridad del transporte escolar de la "Unidad Educativa Particular EMAÚS". Permite el seguimiento en tiempo real de las unidades y la comunicación fluida entre conductores, padres y administradores.

## 📱 Descarga la App (APK)
Para probar la aplicación en un dispositivo Android, descarga la última versión aquí:

[**⬇️ Descargar APK (Versión 1.0)**](AQUI_PONES_EL_LINK_DE_GITHUB_RELEASES)

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

## 📸 Capturas de Pantalla
| Login | Monitoreo | Alertas | Perfil |
|:---:|:---:|:---:|:---:|
| ![Login](LINK_IMAGEN_1) | ![Mapa](LINK_IMAGEN_2) | ![Alertas](LINK_IMAGEN_3) | ![Perfil](LINK_IMAGEN_4) |

> *Nota: Las capturas se encuentran en la carpeta `screenshots` del repositorio.*

## 🚀 Cómo ejecutar el código (Para Desarrolladores)

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/TU_USUARIO/TU_REPO.git](https://github.com/TU_USUARIO/TU_REPO.git)
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
* **Institución:** Escuela Politécnica Nacional (EPN)
