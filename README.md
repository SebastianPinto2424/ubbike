# UBBike

Aplicacion movil y backend para gestionar el ingreso y retiro de bicicletas en los bicicleteros de la Universidad del Bio-Bio.

## Estructura

- `backend/`: API REST con Node.js, Express, TypeORM y PostgreSQL.
- `mobile/`: aplicacion Flutter Web/Mobile con vistas por rol.
- `docs/`: documentacion del proyecto y decisiones tecnicas.

## Despliegue con Docker (Paso a paso)

Para levantar el proyecto completo (Base de datos, Backend, Frontend y Correos) sin necesidad de instalar herramientas externas, sigue estos pasos:

1. Instala y asegúrate de tener abierto **Docker Desktop**.
2. Abre una terminal en la carpeta principal `ubbike`.
3. Ejecuta el siguiente comando para construir y levantar todo en segundo plano:

```bash
docker compose up -d --build
```

### Comandos útiles de Git y Docker

- **Aplicar nuevos cambios en el código:**
  ```bash
  docker compose up -d --build
  ```
- **Reconstrucción limpia (SIN CACHÉ):** Si cambiaste dependencias pesadas y no se reflejan, fuerza la reconstrucción:
  ```bash
  docker compose build --no-cache
  docker compose up -d
  ```
- **Detener el proyecto (conserva datos):**
  ```bash
  docker compose down
  ```
- **Reset total (Borra datos):** Elimina contenedores y reinicia la base de datos a cero.
  ```bash
  docker compose down -v
  ```

### Modo seguro local

El proyecto queda configurado con una postura segura incluso en local:

- El backend corre con `NODE_ENV=production`.
- `DB_SYNCHRONIZE=false` evita cambios automaticos destructivos de esquema.
- El backend ejecuta migraciones versionadas al arrancar.
- `SEED_DEMO_DATA=false` evita recrear cuentas demo automaticamente.
- Docker publica puertos solo en `127.0.0.1`.
- El frontend Nginx corre sin privilegios y con headers de seguridad.
- El backend corre como usuario no root y con filesystem de solo lectura.
- `JWT_SECRET` y `POSTGRES_PASSWORD` deben venir desde archivos `.env` locales.

Si borras el volumen de base de datos con `docker compose down -v`, el backend
vuelve a crear el esquema mediante migraciones. No uses `DB_SYNCHRONIZE=true`
para publicar.

### Produccion y publicacion

Para publicar en un servidor usa el compose endurecido:

```bash
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
```

Antes de publicar, reemplaza los valores de `.env.example` y
`backend/.env.example`, configura SMTP real, HTTPS y backups. La guia completa
esta en `docs/produccion.md`.

### Enlaces de acceso local

Una vez ejecutado el despliegue, podrás acceder a los siguientes servicios desde tu navegador:

- **Aplicación Web (Frontend):** [http://localhost:8081](http://localhost:8081)
- **Correos de prueba (Mailpit):** [http://localhost:8025](http://localhost:8025)
- **Backend (API Base):** [http://localhost:3000](http://localhost:3000)
- **Base de datos (PorsgreSQL):** `localhost:5432`

Docker levanta automáticamente:
- `db`: PostgreSQL con volumen `postgres_data`.
- `backend`: API REST UBBike.
- `mobile`: Build Flutter Web servido por Nginx.
- `mailpit`: Servidor SMTP local para recibir correos de registro y cambio de contraseñas.

## Credenciales de prueba

Todas usan la contrasena:

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

El rol se determina desde el backend al iniciar sesion.

## Arranque local sin Docker

Primero levanta PostgreSQL y Mailpit, o usa Docker solo para servicios:

```bash
docker compose up db mailpit
```

Luego backend:

```bash
cd backend
npm install
npm run dev
```

Endpoint inicial:

```text
GET http://localhost:3000/salud
```

Endpoints de autenticacion:

```text
POST http://localhost:3000/autenticacion/registro
POST http://localhost:3000/autenticacion/login
GET  http://localhost:3000/autenticacion/perfil
GET  http://localhost:3000/notificaciones
GET  http://localhost:3000/bicicleteros
GET  http://localhost:3000/solicitudes-guardia
POST http://localhost:3000/solicitudes-guardia
PATCH http://localhost:3000/solicitudes-guardia/:id/estado
GET  http://localhost:3000/bicicletas
POST http://localhost:3000/bicicletas
PATCH http://localhost:3000/bicicletas/:id
DELETE http://localhost:3000/bicicletas/:id
PATCH http://localhost:3000/bicicletas/:id/activar
POST http://localhost:3000/qr/generar
POST http://localhost:3000/qr/validar
POST http://localhost:3000/accesos/qr/confirmar
POST http://localhost:3000/accesos/qr/denegar
POST http://localhost:3000/accesos/manual
GET  http://localhost:3000/historial
GET  http://localhost:3000/historial/resumen
GET  http://localhost:3000/usuarios
PATCH http://localhost:3000/usuarios/:id
```

Tambien se mantienen alias temporales en ingles para no romper pruebas previas: `/health`, `/auth/register`, `/auth/login` y `/auth/me`.

## Flujo MVP validado

1. El usuario se registra utilizando estrictamente su correo institucional. El sistema asigna automáticamente el rol (`ESTUDIANTE` para `@alumnos.ubiobio.cl` o `FUNCIONARIO` para `@ubiobio.cl`).
2. El formulario valida matemáticamente RUTs chilenos y medidas de seguridad mínimas antes de enviar la petición.
3. El usuario inicia sesion y registra una o mas bicicletas.
2. Si tiene varias bicicletas, marca una como activa.
3. Genera un QR temporal de ingreso o retiro. Dura 15 segundos.
4. El guardia valida el QR y confirma o deniega la operacion.
5. Si el QR no puede usarse, el guardia registra ingreso o retiro manual con correo institucional o RUT.
6. Central y administrador revisan historial, dashboard y operaciones por guardia.
7. El administrador puede gestionar roles, permisos, estado de cuenta y verificacion de correo.

## Modelo relacional base

El MR completo esta documentado en `docs/modelo-relacional.md`. El modelo real
que crea las tablas vive en las entidades TypeORM de `backend/src/modulos`.

El backend ya considera:

- Usuarios con roles `ESTUDIANTE`, `FUNCIONARIO`, `GUARDIA`, `ADMIN_CENTRAL` y `ADMINISTRADOR`.
- El rol se determina al iniciar sesion segun la cuenta registrada.
- `ADMIN_CENTRAL` corresponde al equipo operativo de central.
- `ADMINISTRADOR` puede ver usuarios, cambiar roles, activar cuentas, denegar accesos y marcar correos como verificados.
- Registro y cambio de contrasena consideran validacion por correo.
- Bicicleteros como entidad propia. La UBB tiene actualmente dos bicicleteros.
- Bicicletas registradas por usuario con opcion de agregar, editar, eliminar y activar una bicicleta en uso.
- QR temporal de 15 segundos asociado a la bicicleta activa; si vence, debe regenerarse.
- Asignaciones de guardias a bicicleteros.
- Solicitudes de guardia hacia central cuando el usuario no ve al guardia o requiere su servicio.
- Movimientos asociados a bicicleta, usuario, bicicletero y guardia validador.
- Notificaciones por usuario y perfil.
- Envio de correos por SMTP local usando Mailpit.

Los archivos, clases y funciones del backend estan nombrados en espanol siempre que no choque con convenciones propias de Node, Express o TypeORM.

## App mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Para generar web local:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:3000
```
