# PetVerse

Red social para compartir la vida con tus mascotas. El proyecto avanza por grupos de requisitos para que cada parte pueda guardarse en un commit separado.

## Sin vincular facturación

Este proyecto no usa Firebase Storage ni necesita vincular una cuenta de facturación. Las imágenes y los videos se agregan mediante enlaces públicos directos; la aplicación guarda solo el enlace y los demás datos en Firestore. No se suben archivos desde el dispositivo.

Las fotos de perfil y de mascotas también se cargan con un enlace web. Si en el futuro se quiere subir archivos desde el dispositivo a la nube, habrá que elegir un servicio de almacenamiento y revisar sus condiciones por separado.

## Grupo 1: PV1, PV2, PV3 y PV8

- Registro e inicio de sesión con correo y contraseña.
- Acceso con Google y recuperación de contraseña por correo.
- Perfil editable: nombre, descripción y enlace a una foto.
- Alta, edición y eliminación de mascotas: nombre, tipo, raza, edad, peso, descripción y enlaces de fotos.
- El requisito PV8 de subir archivos desde el dispositivo a Firebase Storage queda pendiente porque el proyecto no utilizará Storage.

## Grupo 2: PV4, PV5 y PV6

- Feed de publicaciones en orden cronológico, con autor, texto y enlace opcional de imagen o video.
- Videos reproducibles en la publicación cuando el enlace apunta directamente a un formato compatible con el navegador.
- Me gusta con botón o doble clic en la imagen, animación, usuario marcado y contador actualizado en tiempo real.
- Comentarios en tiempo real; cada usuario puede eliminar sus propios comentarios.

## Firebase

El proyecto usa `petverse-alan-2026`. En Authentication, activa Google si aún no lo hiciste. En **Firestore Database → Reglas**, publica el contenido actualizado de `firestore.rules` después de copiarlo a Firebase Console. No es necesario configurar Storage.

## Ejecutar en desarrollo

Abre esta carpeta en VS Code y ejecuta desde su terminal:

```powershell
flutter pub get
flutter run -d chrome
```

La configuración web de FlutterFire está en `lib/firebase_options.dart`.

## Dependencias

El proyecto usa Firebase Core, Authentication y Firestore, Provider, internacionalización y reproducción de video. No declara el paquete Firebase Storage.
