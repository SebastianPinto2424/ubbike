# UBBike

Aplicación web/mobile y API REST para gestionar el registro de bicicletas, el ingreso y retiro desde bicicleteros, y la trazabilidad operativa de los accesos en la Universidad del Bío-Bío.

## Estructura del proyecto

- `backend/`: API REST con Node.js, Express, Prisma, PostgreSQL y Redis.
- `mobile/`: aplicación Flutter Web/Mobile con vistas por rol.
- `docs/`: documentación técnica, modelo relacional y notas de producción.

## Requisitos

- Instale Docker Desktop y manténgalo abierto durante la ejecución local.
- Git.
- Navegador web para probar la aplicación local.
- Flutter y Node.js solo si se desea ejecutar sin Docker.

## Entrega Docker Compose

Esta sección contiene el procedimiento específico para la entrega de integración con Docker Compose. El archivo `docker-compose.yml` se encuentra en la raíz del repositorio y levanta todos los servicios necesarios del proyecto.

### Requisitos para ejecutar

- Docker Desktop o Docker Engine con Docker Compose disponible.
- Git.
- Navegador web para acceder a la aplicación.
- No es obligatorio crear archivos `.env`; el `docker-compose.yml` incluye valores por defecto para evaluación local.

### Procedimiento desde cero

Clonar el repositorio, entrar a la raíz del proyecto y levantar los servicios:

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

### Verificación de ejecución

Cuando los contenedores terminen de iniciar, verificar los siguientes accesos:

- Aplicación web: [http://localhost:8081](http://localhost:8081)
- Health check backend: [http://localhost:3000/health](http://localhost:3000/health)
- Correos de prueba Mailpit: [http://localhost:8025](http://localhost:8025)
- PostgreSQL local: `127.0.0.1:5432`

Para consultar el estado de los contenedores:

```bash
docker compose ps
```

Para detener la ejecución:

```bash
docker compose down
```

### Servicios definidos en Docker Compose

| Contenedor | Servicio | Función |
| --- | --- | --- |
| `ubbike_db` | PostgreSQL | Almacena usuarios, bicicletas, bicicleteros, movimientos, solicitudes y notificaciones. |
| `ubbike_redis` | Redis | Mantiene contadores temporales para limitar intentos de acceso y proteger acciones sensibles. |
| `ubbike_mailpit` | Mailpit | Recibe correos de prueba para registro, verificación y cambio de contraseña en local. |
| `ubbike_backend` | Backend API | Expone la API REST, aplica reglas de negocio, seguridad, validaciones y migraciones. |
| `ubbike_frontend` | Frontend Flutter Web | Sirve la aplicación web de UBBike mediante Nginx. |

## Configuración opcional

Si desea personalizar puertos, contraseñas o secretos para Docker, cree el archivo de entorno local:

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Luego reemplace, como mínimo:

- `.env`: `POSTGRES_PASSWORD` por una clave segura.
- `.env`: `JWT_SECRET` por un secreto largo de 32 o más caracteres.

El archivo `.env` está ignorado por Git y no debe subirse al repositorio. El archivo `backend/.env` solo es necesario si ejecuta el backend sin Docker.

## Despliegue local con Docker

Desde la carpeta principal del proyecto, si desea reconstruir y dejar los servicios en segundo plano, ejecute:

```bash
docker compose up -d --build
```

## Comandos útiles

Ejecutar o aplicar cambios:

```bash
docker compose up -d --build
```

Reconstrucción limpia sin caché:

```bash
docker compose build --no-cache
docker compose up -d
```

Detener conservando datos:

```bash
docker compose down
```

Reiniciar desde cero eliminando volúmenes:

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

### Base de datos existente y Prisma

Si se migra una base ya creada antes de Prisma, no elimine el volumen para "arreglar" el error `P3005`.
Primero aplique el SQL idempotente y luego registre la migracion inicial como aplicada:

```powershell
docker compose stop backend
Get-Content -Raw backend\prisma\migrations\20260515123000_init\migration.sql | docker compose exec -T db psql -v ON_ERROR_STOP=1 -U ubbike -d ubbike
docker compose run --rm --no-deps backend npx prisma migrate resolve --applied 20260515123000_init
docker compose up -d
```

Use `docker compose down -v` solo cuando quiera borrar completamente los datos locales.

## Seguridad local

El proyecto queda preparado con una configuracion segura base:

- Backend en `NODE_ENV=production`.
- Migraciones versionadas con Prisma Migrate.
- Backend ejecutado como usuario no root.
- Contenedores con `read_only`, `tmpfs`, `cap_drop` y `no-new-privileges`.
- Puertos publicados solo en `127.0.0.1` en entorno local.
- Redis para rate limiting distribuido.
- Nginx con headers de seguridad y CSP para Flutter Web.
- Validación estricta de correo institucional y contraseñas.
- Tokens de verificación de correo con expiración.
- QR temporal de corta duración.
- Validación de QR restringida al bicicletero activo del guardia.

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

En producción, `SEED_DEMO_DATA=false`.

## Documentación adicional

La documentación técnica adicional se encuentra en:

- `docs/desarrollo-y-api.md`: flujo funcional, endpoints principales, arranque sin Docker y validaciones.
- `docs/modelo-relacional.md`: modelo relacional del proyecto.
