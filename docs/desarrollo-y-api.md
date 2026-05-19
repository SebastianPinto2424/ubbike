# Desarrollo y API

## Flujo funcional del MVP

1. El usuario solicita registro con correo institucional.
2. El sistema asigna rol automáticamente según dominio de correo:
   - `@alumnos.ubiobio.cl`: estudiante.
   - `@ubiobio.cl`: funcionario.
3. El usuario verifica su correo mediante enlace seguro.
4. El usuario inicia sesión y registra una o más bicicletas.
5. El usuario selecciona una bicicleta activa.
6. Para ingreso, selecciona bicicletero y genera QR temporal.
7. Para retiro, genera QR asociado al bicicletero donde la bicicleta se encuentra registrada.
8. El guardia selecciona en su perfil el bicicletero que gestiona durante su turno.
9. El guardia valida QR solo si corresponde a su bicicletero activo.
10. El guardia confirma o deniega ingreso/retiro.
11. Si el QR no puede usarse, el guardia registra acceso manual con correo institucional o RUT.
12. Usuarios pueden solicitar apoyo si no ven al guardia o requieren servicio.
13. Guardia y central reciben alertas y notificaciones dentro de la aplicación.
14. Central y administrador revisan historial, dashboard, solicitudes y operaciones por guardia.
15. Administrador puede gestionar usuarios, roles, estado de cuenta y verificación de correo.

## Endpoints principales

Autenticación:

```text
POST /autenticacion/registro
POST /autenticacion/login
GET  /autenticacion/perfil
GET  /autenticacion/verificar-correo
POST /autenticacion/verificar-correo
POST /autenticacion/solicitar-cambio-contrasena
POST /autenticacion/cambiar-contrasena
```

Bicicletas y bicicleteros:

```text
GET    /bicicleteros
GET    /bicicletas
GET    /bicicletas/activa
POST   /bicicletas
PATCH  /bicicletas/:id
DELETE /bicicletas/:id
PATCH  /bicicletas/:id/activar
```

QR y accesos:

```text
POST /qr/generar
POST /qr/validar
POST /accesos/qr/confirmar
POST /accesos/qr/denegar
POST /accesos/manual
```

Guardias y solicitudes:

```text
GET   /guardias/me/bicicletero
PATCH /guardias/me/bicicletero
GET   /solicitudes-guardia
POST  /solicitudes-guardia
PATCH /solicitudes-guardia/:id/estado
```

Historial, usuarios y notificaciones:

```text
GET   /historial
GET   /historial/resumen
GET   /notificaciones
PATCH /notificaciones/leidas
GET   /usuarios
PATCH /usuarios/:id
```

Alias mantenidos por compatibilidad:

```text
GET  /health
POST /auth/register
POST /auth/login
GET  /auth/me
```

## Arranque sin Docker completo

Primero levante los servicios base:

```bash
docker compose up -d db redis mailpit
```

Backend:

```bash
cd backend
npm install
npm run migrate
npm run dev
```

Si la base ya tenia tablas antes de Prisma y aparece `P3005`, aplique el baseline sin borrar datos:

```powershell
docker compose stop backend
Get-Content -Raw backend\prisma\migrations\20260515123000_init\migration.sql | docker compose exec -T db psql -v ON_ERROR_STOP=1 -U ubbike -d ubbike
docker compose run --rm --no-deps backend npx prisma migrate resolve --applied 20260515123000_init
docker compose up -d
```

Flutter:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Build web local:

```bash
cd mobile
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:3000
```

## Validaciones recomendadas

Backend:

```bash
cd backend
npm run generate
npx prisma validate
npm run typecheck
npm run build
```

Frontend:

```bash
cd mobile
flutter analyze
flutter test
```

Docker Compose:

```bash
docker compose config --quiet
```

## Modelo relacional

El modelo relacional se documenta en `docs/modelo-relacional.md`.

El backend considera:

- Usuarios con roles `ESTUDIANTE`, `FUNCIONARIO`, `GUARDIA`, `ADMIN_CENTRAL` y `ADMINISTRADOR`.
- Bicicleteros activos con capacidad y ocupación.
- Bicicletas asociadas a usuarios.
- QR temporales asociados a usuario, bicicleta, tipo de movimiento y bicicletero.
- Asignaciones activas de guardia a bicicletero.
- Movimientos de ingreso/retiro con estado confirmado o denegado.
- Solicitudes de guardia.
- Notificaciones por usuario.
- Auditoría de acciones relevantes.

Los nombres de modelos, módulos y funciones del backend se mantienen en español cuando no chocan con convenciones propias de Node, Express o Prisma.
