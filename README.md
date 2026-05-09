# UBBike

Aplicacion web/mobile y API REST para gestionar el registro de bicicletas, el ingreso y retiro desde bicicleteros, y la trazabilidad operativa de los accesos en la Universidad del Bio-Bio.

## Estructura del proyecto

- `backend/`: API REST con Node.js, Express, TypeORM, PostgreSQL y Redis.
- `mobile/`: aplicacion Flutter Web/Mobile con vistas por rol.
- `docs/`: documentacion tecnica, modelo relacional y notas de produccion.

## Requisitos

- Instale Docker Desktop y mantengalo abierto durante la ejecucion local.
- Git.
- Navegador web para probar la aplicacion local.
- Flutter y Node.js solo si se desea ejecutar sin Docker.

## Entrega Docker Compose

Esta seccion contiene el procedimiento especifico para la entrega de integracion con Docker Compose. El archivo `docker-compose.yml` se encuentra en la raiz del repositorio y levanta todos los servicios necesarios del proyecto.

### Requisitos para ejecutar la entrega

- Docker Desktop o Docker Engine con Docker Compose disponible.
- Git.
- Navegador web para acceder a la aplicacion.
- No es obligatorio crear archivos `.env`; el `docker-compose.yml` incluye valores por defecto para evaluacion local.

### Procedimiento desde cero

Clonar el repositorio, entrar a la raiz del proyecto y levantar los servicios:

```bash
git clone https://github.com/SebastianPinto2424/ubbike.git
cd ubbike
docker compose up
```

Si el repositorio ya fue clonado previamente, entrar a la carpeta del proyecto, actualizar la rama principal y levantar los servicios:

```bash
git switch main
git pull
docker compose up
```

### Verificacion de ejecucion

Cuando los contenedores terminen de iniciar, verificar los siguientes accesos:

- Aplicacion web: [http://localhost:8081](http://localhost:8081)
- Backend API: [http://localhost:3000](http://localhost:3000)
- Health check backend: [http://localhost:3000/health](http://localhost:3000/health)
- Correos de prueba Mailpit: [http://localhost:8025](http://localhost:8025)
- PostgreSQL local: `127.0.0.1:5432`
- Redis local: `127.0.0.1:6379`

Para consultar el estado de los contenedores:

```bash
docker compose ps
```

Para detener la ejecucion:

```bash
docker compose down
```

### Servicios definidos en Docker Compose

| Contenedor | Servicio | Funcion |
| --- | --- | --- |
| `ubbike_db` | PostgreSQL | Almacena usuarios, bicicletas, bicicleteros, movimientos, solicitudes y notificaciones. |
| `ubbike_redis` | Redis | Mantiene contadores temporales para limitar intentos de acceso y proteger acciones sensibles. |
| `ubbike_mailpit` | Mailpit | Recibe correos de prueba para registro, verificacion y cambio de contrasena en local. |
| `ubbike_backend` | Backend API | Expone la API REST, aplica reglas de negocio, seguridad, validaciones y migraciones. |
| `ubbike_frontend` | Frontend Flutter Web | Sirve la aplicacion web de UBBike mediante Nginx. |

## Configuracion opcional

Si desea personalizar puertos, contrasenas o secretos para Docker, cree el archivo de entorno local:

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Luego reemplace, como minimo:

- `.env`: `POSTGRES_PASSWORD` por una clave segura.
- `.env`: `JWT_SECRET` por un secreto largo de 32 o mas caracteres.

El archivo `.env` esta ignorado por Git y no debe subirse al repositorio. El archivo `backend/.env` solo es necesario si ejecuta el backend sin Docker.

## Despliegue local con Docker

Desde la carpeta principal del proyecto, si desea reconstruir y dejar los servicios en segundo plano, ejecute:

```bash
docker compose up -d --build
```

## Comandos utiles

Ejecutar o aplicar cambios:

```bash
docker compose up -d --build
```

Reconstruccion limpia sin cache:

```bash
docker compose build --no-cache
docker compose up -d
```

Detener conservando datos:

```bash
docker compose down
```

Reiniciar desde cero eliminando volumenes:

```bash
docker compose down -v
docker compose up -d --build
```

Consultar estado:

```bash
docker compose ps
```

Consultar logs:

```bash
docker compose logs -f backend
docker compose logs -f frontend
```

## Seguridad local

El proyecto queda preparado con una configuracion segura base:

- Backend en `NODE_ENV=production`.
- Migraciones versionadas al iniciar.
- `DB_SYNCHRONIZE=false`.
- Backend ejecutado como usuario no root.
- Contenedores con `read_only`, `tmpfs`, `cap_drop` y `no-new-privileges`.
- Puertos publicados solo en `127.0.0.1` en entorno local.
- Redis para rate limiting distribuido.
- Nginx con headers de seguridad y CSP para Flutter Web.
- Validacion estricta de correo institucional y contrasenas.
- Tokens de verificacion de correo con expiracion.
- QR temporal de corta duracion.
- Validacion de QR restringida al bicicletero activo del guardia.

## Credenciales demo

En local, `SEED_DEMO_DATA=true` crea usuarios de prueba. Todas las cuentas utilizan:

```text
UBBike2026*
```

| Rol | Correo |
| --- | --- |
| Estudiante | `estudiante@alumnos.ubiobio.cl` |
| Funcionario | `funcionario@ubiobio.cl` |
| Guardia | `guardia@ubiobio.cl` |
| Admin central | `admin.central@ubiobio.cl` |
| Administrador | `administrador@ubiobio.cl` |

En produccion, `SEED_DEMO_DATA=false`.

## Flujo funcional del MVP

1. El usuario solicita registro con correo institucional.
2. El sistema asigna rol automaticamente segun dominio de correo:
   - `@alumnos.ubiobio.cl`: estudiante.
   - `@ubiobio.cl`: funcionario.
3. El usuario verifica su correo mediante enlace seguro.
4. El usuario inicia sesion y registra una o mas bicicletas.
5. El usuario selecciona una bicicleta activa.
6. Para ingreso, selecciona bicicletero y genera QR temporal.
7. Para retiro, genera QR asociado al bicicletero donde la bicicleta se encuentra registrada.
8. El guardia selecciona en su perfil el bicicletero que gestiona durante su turno.
9. El guardia valida QR solo si corresponde a su bicicletero activo.
10. El guardia confirma o deniega ingreso/retiro.
11. Si el QR no puede usarse, el guardia registra acceso manual con correo institucional o RUT.
12. Usuarios pueden solicitar apoyo si no ven al guardia o requieren servicio.
13. Guardia y central reciben alertas y notificaciones dentro de la aplicacion.
14. Central y administrador revisan historial, dashboard, solicitudes y operaciones por guardia.
15. Administrador puede gestionar usuarios, roles, estado de cuenta y verificacion de correo.

## Endpoints principales

Autenticacion:

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

## Arranque sin Docker

Primero levante los servicios base:

```bash
docker compose up -d db redis mailpit
```

Backend:

```bash
cd backend
npm install
npm run dev
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
- Bicicleteros activos con capacidad y ocupacion.
- Bicicletas asociadas a usuarios.
- QR temporales asociados a usuario, bicicleta, tipo de movimiento y bicicletero.
- Asignaciones activas de guardia a bicicletero.
- Movimientos de ingreso/retiro con estado confirmado o denegado.
- Solicitudes de guardia.
- Notificaciones por usuario.
- Auditoria de acciones relevantes.

Los nombres de clases, modulos y funciones del backend se mantienen en espanol cuando no chocan con convenciones propias de Node, Express o TypeORM.
