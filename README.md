# PetVerse

Red social para compartir la vida con tus mascotas. El proyecto se construye por bloques para que cada entrega tenga un cambio claro y pueda guardarse en un commit separado.

## Bloque 1: identidad y acceso adaptable

- Pantalla de acceso y registro con validaciones de formulario.
- Presentación adaptable para teléfono y escritorio.
- Tema visual y marca básica de PetVerse.
- Nombre, descripción y colores de la aplicación web instalable (PWA).
- Provider para el estado visual del formulario.

## Bloque 2: autenticación y perfil

- Firebase se inicializa con la configuración web de `petverse-alan-2026`.
- Registro, inicio de sesión y recuperación de contraseña con correo.
- Cierre de sesión y cambio automático entre acceso y perfil.
- Perfil básico con nombre y descripción guardados en Firestore.
- Reglas de Firestore en `firestore.rules`; cada usuario puede leer y modificar únicamente su propio perfil.

El acceso con Google queda pendiente de habilitar el proveedor Google en Firebase Console.

### Publicar las reglas de Firestore

La base se creó en modo de producción, por lo que las lecturas y escrituras quedan bloqueadas hasta publicar reglas. En Firebase Console, abre **Firestore Database → Reglas**, reemplaza el contenido por el de `firestore.rules` y presiona **Publicar**.

## Ejecutar en desarrollo

Abre esta carpeta en VS Code y ejecuta desde su terminal:

```powershell
flutter pub get
flutter run -d chrome
```

El SDK y las herramientas instaladas para este equipo están disponibles desde la configuración local de VS Code del proyecto.

## Dependencias previstas

El proyecto ya incluye los paquetes para Firebase Core, Authentication, Firestore, Storage, Messaging y Cloud Functions, además de Provider, selección de imágenes, internacionalización y notificaciones locales. Se irán usando a medida que se incorporen los bloques funcionales.

## Configuración Firebase

La configuración web generada por FlutterFire está en `lib/firebase_options.dart`. Si se agrega otra plataforma en el futuro, vuelve a ejecutar `flutterfire configure` desde la carpeta del proyecto y selecciona las plataformas necesarias.
