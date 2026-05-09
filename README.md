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

## Docker Compose

Esta seccion contiene el procedimiento especifico para la entrega de la tarea de Docker Compose. El archivo `docker-compose.yml` se encuentra en la raiz del repositorio y levanta todos los servicios necesarios del proyecto.

### Requisitos para ejecutar

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

### Verificacion de ejecucion

Cuando los contenedores terminen de iniciar, verificar los siguientes accesos:

- Frontend / Aplicacion web: [http://localhost:8081](http://localhost:8081)
- Health check backend: [http://localhost:3000/health](http://localhost:3000/health)
- Correos de prueba Mailpit: [http://localhost:8025](http://localhost:8025)

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
- `.env`: `JWT_SECRET` por una clave secreta de largo de 32 o mas caracteres.

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

## Documentacion adicional

La documentacion tecnica adicional se encuentra en:

- `docs/desarrollo-y-api.md`: flujo funcional, endpoints principales, arranque sin Docker y validaciones.
- `docs/modelo-relacional.md`: modelo relacional del proyecto.
