# Produccion y publicacion

Esta guia deja el repositorio listo para un despliegue serio. Aun asi, para publicar en Internet debes completar recursos externos: dominio, TLS, SMTP real, servidor/VPS y backups programados.

## Requisitos previos

- Docker y Docker Compose instalados en el servidor.
- Un dominio o subdominio para frontend y API.
- HTTPS con un proxy reverso como Nginx, Caddy, Traefik o Cloudflare Tunnel.
- SMTP real para correos de verificacion y cambio de contrasena.
- Un plan de backup para PostgreSQL.
- Redis interno para rate limiting distribuido.

## Variables necesarias

Copia los ejemplos y reemplaza todos los valores:

```powershell
Copy-Item .env.example .env
Copy-Item backend/.env.example backend/.env
```

Valores minimos:

- `.env`
  - `POSTGRES_PASSWORD`: secreto unico de 32 o mas caracteres.
  - `PUBLIC_API_BASE_URL`: origen publico HTTPS de la API, por ejemplo `https://api.tu-dominio.cl`.
- `backend/.env`
  - `JWT_SECRET`: secreto unico de 32 o mas caracteres.
  - `FRONTEND_URL`: URL publica HTTPS del frontend.
  - `CORS_ORIGINS`: origen exacto del frontend.
  - `TRUST_PROXY`: `loopback` si el proxy reverso publica desde la misma maquina.
  - `REDIS_URL`: URL interna de Redis; en Docker Compose queda `redis://redis:6379`.
  - `REQUIRE_REDIS_RATE_LIMIT=true`.
  - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `MAIL_FROM`: credenciales reales de correo. Se recomienda Brevo SMTP:
    `SMTP_HOST=smtp-relay.brevo.com`, `SMTP_PORT=587`, `SMTP_SECURE=false`.
  - `DB_SYNCHRONIZE=false`.
  - `SEED_DEMO_DATA=false`.

## Arranque de produccion

```powershell
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

El backend ejecuta migraciones versionadas al arrancar. No usa sincronizacion automatica de TypeORM en produccion.

## Publicacion con proxy reverso

El compose de produccion publica backend y frontend solo en `127.0.0.1`, por seguridad. El proxy reverso del servidor debe exponerlos por HTTPS:

- Frontend: `http://127.0.0.1:8081`
- API: `http://127.0.0.1:3000`

No publiques PostgreSQL directamente a Internet.

## Backups

Backup manual:

```powershell
docker exec ubbike_db pg_dump -U ubbike -d ubbike -Fc -f /tmp/ubbike.dump
docker cp ubbike_db:/tmp/ubbike.dump .\backups\ubbike.dump
```

Restauracion en una base limpia:

```powershell
docker cp .\backups\ubbike.dump ubbike_db:/tmp/ubbike.dump
docker exec ubbike_db pg_restore -U ubbike -d ubbike --clean --if-exists /tmp/ubbike.dump
```

Programa backups diarios fuera del contenedor y guarda copias fuera del servidor.

## Checklist antes de publicar

- `JWT_SECRET` y `POSTGRES_PASSWORD` son secretos largos y no estan en Git.
- `DB_SYNCHRONIZE=false` y `SEED_DEMO_DATA=false`.
- `CORS_ORIGINS` contiene solo dominios reales del frontend.
- SMTP real probado con registro y cambio de contrasena.
- HTTPS activo en frontend y API.
- PostgreSQL no esta expuesto publicamente.
- Redis no esta expuesto publicamente y `REQUIRE_REDIS_RATE_LIMIT=true`.
- Backups probados con restauracion.
- Logs revisados con `docker compose -f docker-compose.prod.yml logs backend`.
- Usuarios demo eliminados o deshabilitados si existian en una base antigua.
