# PetVerse

Red social para compartir la vida con tus mascotas. El proyecto se construye por bloques para que cada entrega tenga un cambio claro y pueda guardarse en un commit separado.

## Bloque 1: identidad y acceso adaptable

- Pantalla de acceso y registro con validaciones de formulario.
- Presentación adaptable para teléfono y escritorio.
- Tema visual y marca básica de PetVerse.
- Nombre, descripción y colores de la aplicación web instalable (PWA).
- Provider para el estado visual del formulario.

La autenticación todavía no está conectada: para habilitarla hace falta crear o elegir un proyecto de Firebase y generar su configuración para Flutter.

## Ejecutar en desarrollo

Abre esta carpeta en VS Code y ejecuta desde su terminal:

```powershell
flutter pub get
flutter run -d chrome
```

El SDK y las herramientas instaladas para este equipo están disponibles desde la configuración local de VS Code del proyecto.

## Dependencias previstas

El proyecto ya incluye los paquetes para Firebase Core, Authentication, Firestore, Storage, Messaging y Cloud Functions, además de Provider, selección de imágenes, internacionalización y notificaciones locales. Se irán usando a medida que se incorporen los bloques funcionales.

## Configurar Firebase más adelante

Cuando exista un proyecto de Firebase, inicia sesión con Firebase CLI y ejecuta `flutterfire configure` desde esta carpeta. Ese paso genera la configuración específica del proyecto; no se incluye ningún identificador ni credencial de ejemplo.
