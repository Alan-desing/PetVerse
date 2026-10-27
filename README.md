# PetVerse

PetVerse es una red social web para compartir la vida de las mascotas. Cada persona puede crear su cuenta, completar su perfil, registrar a sus mascotas, publicar contenido, interactuar con otras publicaciones y ponerse en contacto con usuarios que ofrecen mascotas en adopción.

La aplicación está desarrollada con Flutter Web y utiliza Firebase Authentication para las cuentas y Cloud Firestore para guardar y sincronizar la información.

## Funcionalidades

### Cuentas y perfiles

- Registro e inicio de sesión con correo electrónico y contraseña.
- Inicio de sesión con Google y recuperación de contraseña por correo.
- Perfil editable con nombre, biografía y enlace a una imagen.
- Alta, edición y eliminación de mascotas. Cada ficha permite guardar nombre, tipo, raza, edad, peso, descripción, localidad y enlaces a fotos.
- Una mascota puede marcarse como disponible para adopción.

### Publicaciones e interacción

- Feed de publicaciones ordenado desde las más recientes.
- Publicaciones con texto y enlace opcional a una imagen o video.
- Reproducción de videos cuando el enlace es directo y compatible con el navegador.
- Me gusta con contador actualizado en tiempo real y animación al interactuar.
- Comentarios en tiempo real. Cada persona puede eliminar sus propios comentarios.

### Adopciones y mensajes

- Catálogo de mascotas disponibles para adopción.
- Filtros por tipo de mascota, edad y localidad.
- Formulario para enviar una solicitud de contacto al dueño.
- Las solicitudes recibidas pueden consultarse desde la aplicación.
- El contacto inicia una conversación privada entre quien consulta y el dueño. Los mensajes y el historial se actualizan en tiempo real.

### Avisos y logros

- Avisos privados cuando otra persona marca Me gusta, comenta o envía un mensaje.
- Avisos dentro de PetVerse en tiempo real y notificaciones del navegador si se otorga permiso mientras la aplicación está abierta.
- Sistema de puntos: 10 por publicar, 2 por dar Me gusta a una publicación de otra persona y 3 por comentar. Los puntos por Me gusta se acreditan una sola vez por publicación.
- Pantalla de logros con el total de puntos y cinco insignias.

### Aplicación web progresiva

- Diseño adaptable a celulares, tabletas y computadoras.
- Manifest, íconos propios, acceso de instalación y service worker.
- El service worker conserva recursos web y permite volver a abrir la aplicación sin conexión después de una visita. Las funciones que consultan Firebase requieren Internet.

## Tecnologías

- **Flutter y Dart:** interfaz y lógica de la aplicación web.
- **Firebase Authentication:** creación de cuentas, inicio de sesión y recuperación de contraseña.
- **Cloud Firestore:** perfiles, mascotas, publicaciones, comentarios, Me gusta, solicitudes, conversaciones, avisos y eventos de puntos.
- **Provider:** estado compartido del formulario de acceso.
- **intl:** formato de fechas y valores localizados.
- **video_player:** reproducción de videos compatibles dentro de las publicaciones.
- **PWA:** manifest, íconos, instalación y service worker.

## Organización del código

```text
lib/
├── main.dart                  # Inicialización de Firebase y aplicación
├── auth_gate.dart             # Decide si se muestra acceso o la aplicación
├── models/                    # Modelos de perfiles, mascotas y actividad
├── providers/                 # Estado compartido de la interfaz
├── screens/                   # Pantallas y formularios
├── services/                  # Acceso a Authentication y Firestore
├── theme/                     # Colores y estilos
└── widgets/                   # Componentes reutilizables

web/
├── index.html                 # Documento web y registro del service worker
├── manifest.json              # Datos para instalar la PWA
├── petverse-sw.js             # Caché y apertura sin conexión
└── icons/                     # Íconos de la aplicación
```

Los servicios separan las operaciones con Firebase de las pantallas. Los streams de Firestore permiten reflejar cambios en publicaciones, comentarios, conversaciones, avisos y logros sin recargar la aplicación.

## Datos en Firestore

- `users/{userId}`: perfil de la persona.
- `users/{userId}/pets/{petId}`: mascotas y datos de adopción.
- `users/{userId}/activityEvents/{eventId}`: eventos usados para calcular puntos.
- `users/{userId}/notifications/{notificationId}`: avisos privados.
- `posts/{postId}`: publicaciones; sus subcolecciones `likes` y `comments` guardan las interacciones.
- `adoptionRequests/{requestId}`: solicitudes de contacto.
- `chats/{chatId}` y `chats/{chatId}/messages/{messageId}`: conversaciones y mensajes.

Las reglas de acceso se encuentran en `firestore.rules`. El proyecto debe tener estas reglas publicadas en la base de datos de Firebase para que las operaciones de la aplicación estén autorizadas.

## Configuración de Firebase

La configuración web de FlutterFire está guardada en `lib/firebase_options.dart` y apunta al proyecto `petverse-alan-2026`.

En Firebase Console se deben encontrar habilitados los proveedores de correo y contraseña y Google en **Authentication**, y creada la base de datos en **Firestore Database**. Para otro proyecto de Firebase, hay que ejecutar `flutterfire configure` y reemplazar la configuración web generada.

## Imágenes, videos y servicios que no se utilizan

Las imágenes de perfil, mascotas y publicaciones se indican mediante enlaces web públicos. PetVerse no sube archivos desde el dispositivo y no utiliza Firebase Storage; por eso no necesita vincular una cuenta de facturación para el almacenamiento de archivos. Los enlaces deben ser accesibles desde el navegador.

Los avisos se guardan y muestran en Firestore. Esta versión no envía notificaciones push de Firebase cuando el navegador está cerrado: eso requiere un servicio de backend que envíe mensajes. Las dependencias de Messaging y Cloud Functions presentes en el proyecto no se utilizan para enviar avisos desde un servidor.

## Ejecutar en desarrollo

Se necesita Flutter con soporte web y un navegador compatible, como Chrome.

Desde la carpeta del proyecto, ejecutar:

```powershell
flutter pub get
flutter run -d chrome
```

En el primer acceso a Firebase, iniciar sesión con una cuenta creada en el proyecto y verificar que estén publicadas las reglas de `firestore.rules`.

## Generar la versión web

```powershell
flutter build web --release
```

Flutter genera la versión de producción en `build/web`. Para Vercel, el comando de compilación es `flutter build web --release` y el directorio de salida es `build/web`. El sitio debe servirse mediante HTTPS para poder instalar la PWA y utilizar las funciones del navegador que requieren un contexto seguro. Si el inicio de sesión no funciona en el dominio publicado, hay que agregar ese dominio a **Authentication → Configuración → Dominios autorizados** en Firebase Console.

## Dependencias principales

Las dependencias del proyecto están declaradas en `pubspec.yaml`. Para instalar o actualizar las dependencias antes de ejecutar la aplicación, usar `flutter pub get`.
