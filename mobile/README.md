# UBBike Mobile

Aplicación móvil Flutter para el prototipo MVP de UBBike.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Preparar prueba en iOS

El proyecto ya incluye el target nativo `ios/` con permisos de cámara, fotos y red local para pruebas. Para probarlo en simulador o iPhone físico se debe abrir desde macOS con Xcode instalado:

```bash
cd mobile
flutter pub get
flutter doctor
flutter run -d ios
```

Para un iPhone físico, abra `ios/Runner.xcworkspace` en Xcode y configure `Signing & Capabilities` con su Apple Team. Si la API corre en otra máquina de la red, ejecute Flutter indicando la URL real del backend:

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://IP_DE_TU_BACKEND:3000
```

## Verificar

```bash
flutter analyze
flutter test
```

El prototipo incluye vistas para usuario, guardia y central de seguridad.
