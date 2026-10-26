# PetVerse

Red social para compartir la vida con tus mascotas. El proyecto se desarrolla por grupos de requisitos para que cada avance pueda guardarse en un commit separado.

## Grupo 1: PV1, PV2, PV3 y PV8 — acceso, perfiles, mascotas y archivos

- Registro e inicio de sesión con correo y contraseña.
- Acceso con Google y recuperación de contraseña por correo.
- Perfil de usuario editable: nombre, descripción y foto.
- Alta, edición y eliminación de perfiles de mascotas: nombre, tipo, raza, edad, peso, descripción y fotos.
- Selección de fotos y videos desde el dispositivo, subida a Firebase Storage y barra de progreso.
- Reglas de acceso para Firestore y Storage en `firestore.rules` y `storage.rules`.

Las fotos no se agregan manualmente a una carpeta del proyecto: cada usuario las elige desde la aplicación.

## Configuración pendiente en Firebase

La aplicación usa el proyecto `petverse-alan-2026`. Antes de probar el acceso con Google y las cargas, revisa estos ajustes en Firebase Console:

1. **Activar Google:** abre **Authentication → Sign-in method**, selecciona **Google**, actívalo y guarda.
2. **Publicar Firestore:** abre **Firestore Database → Reglas**, reemplaza el contenido por `firestore.rules` y presiona **Publicar**.
3. **Habilitar Storage:** abre **Storage** y crea/activa el bucket. Firebase requiere el plan Blaze para usar Cloud Storage en proyectos nuevos; esto puede generar cargos si se supera el uso sin costo.
4. **Publicar Storage:** en **Storage → Reglas**, reemplaza el contenido por `storage.rules` y presiona **Publicar**.

El archivo `firebase.json` ya apunta a las dos reglas. No se cambia el plan ni se publica nada automáticamente desde este proyecto.

## Ejecutar en desarrollo

Abre esta carpeta en VS Code y ejecuta desde su terminal:

```powershell
flutter pub get
flutter run -d chrome
```

La configuración web de FlutterFire está en `lib/firebase_options.dart`. Si se agrega otra plataforma, vuelve a ejecutar `flutterfire configure` desde la carpeta del proyecto y selecciona las plataformas necesarias.

## Dependencias

El proyecto incluye Firebase Core, Authentication, Firestore, Storage, Messaging y Cloud Functions, además de Provider, selección de imágenes, internacionalización y notificaciones locales. Algunos paquetes se usarán en los grupos siguientes.
