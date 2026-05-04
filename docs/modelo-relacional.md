# Modelo Relacional UBBike

Este documento resume el MR del sistema. La fuente tecnica esta en las
entidades TypeORM del backend:

- `backend/src/modulos/usuarios/usuario.entidad.ts`
- `backend/src/modulos/bicicletas/bicicleta.entidad.ts`
- `backend/src/modulos/bicicleteros/bicicletero.entidad.ts`
- `backend/src/modulos/historial/movimiento.entidad.ts`
- `backend/src/modulos/qr/codigo-qr-temporal.entidad.ts`
- `backend/src/modulos/acceso/asignacion-guardia.entidad.ts`
- `backend/src/modulos/acceso/solicitud-guardia.entidad.ts`
- `backend/src/modulos/notificaciones/notificacion.entidad.ts`
- `backend/src/modulos/incidencias/incidencia.entidad.ts`
- `backend/src/modulos/auditoria/auditoria.entidad.ts`

## Diagrama ER

```mermaid
erDiagram
  USUARIOS ||--o{ BICICLETAS : registra
  USUARIOS ||--o{ MOVIMIENTOS : realiza
  USUARIOS ||--o{ MOVIMIENTOS : valida_como_guardia
  USUARIOS ||--o{ ASIGNACIONES_GUARDIAS : tiene
  USUARIOS ||--o{ SOLICITUDES_GUARDIA : solicita
  USUARIOS ||--o{ SOLICITUDES_GUARDIA : atiende
  USUARIOS ||--o{ NOTIFICACIONES : recibe
  USUARIOS ||--o{ INCIDENCIAS : reporta
  USUARIOS ||--o{ AUDITORIA_EVENTOS : ejecuta

  BICICLETAS ||--o{ MOVIMIENTOS : genera
  BICICLETAS ||--o{ CODIGOS_QR_TEMPORALES : usa
  BICICLETAS ||--o{ INCIDENCIAS : asociada

  BICICLETEROS ||--o{ MOVIMIENTOS : registra
  BICICLETEROS ||--o{ CODIGOS_QR_TEMPORALES : destino
  BICICLETEROS ||--o{ ASIGNACIONES_GUARDIAS : asigna
  BICICLETEROS ||--o{ SOLICITUDES_GUARDIA : recibe
  BICICLETEROS ||--o{ INCIDENCIAS : contiene

  USUARIOS {
    uuid id PK
    varchar nombre
    varchar correo UK
    varchar rut UK
    enum rol
    varchar contrasena_hash
    boolean correo_verificado
    boolean cuenta_activa
    integer version_sesion
    varchar token_verificacion_correo
    timestamptz token_verificacion_correo_expira_en
    varchar token_cambio_contrasena
    timestamptz token_cambio_contrasena_expira_en
  }

  BICICLETAS {
    uuid id PK
    uuid usuario_id FK
    uuid bicicletero_actual_id FK
    varchar descripcion
    varchar marca
    varchar modelo
    varchar color
    varchar aro
    varchar numero_serie
    text foto_url
    boolean activa
    boolean dentro_bicicletero
  }

  BICICLETEROS {
    uuid id PK
    varchar nombre UK
    varchar ubicacion
    integer capacidad
    boolean activo
  }

  MOVIMIENTOS {
    uuid id PK
    uuid bicicleta_id FK
    uuid usuario_id FK
    uuid bicicletero_id FK
    uuid validado_por_guardia_id FK
    enum tipo
    enum estado
    text motivo_denegacion
    varchar origen
    timestamptz creado_en
  }

  CODIGOS_QR_TEMPORALES {
    uuid id PK
    varchar token UK
    uuid usuario_id FK
    uuid bicicleta_id FK
    uuid bicicletero_id FK
    enum tipo
    timestamptz expira_en
    boolean usado
  }

  ASIGNACIONES_GUARDIAS {
    uuid id PK
    uuid guardia_id FK
    uuid bicicletero_id FK
    timestamptz inicia_en
    timestamptz termina_en
    boolean activa
  }

  SOLICITUDES_GUARDIA {
    uuid id PK
    uuid solicitada_por_usuario_id FK
    uuid bicicletero_id FK
    uuid guardia_asignado_id FK
    enum tipo
    enum estado
    text mensaje
    timestamptz notificada_guardia_en
    timestamptz acuse_recibo_en
    timestamptz resuelta_en
  }

  NOTIFICACIONES {
    uuid id PK
    uuid usuario_id FK
    varchar titulo
    text mensaje
    enum tipo
    boolean leida
    jsonb datos
  }

  INCIDENCIAS {
    uuid id PK
    uuid usuario_id FK
    uuid bicicletero_id FK
    uuid bicicleta_id FK
    text descripcion
    enum estado
  }

  AUDITORIA_EVENTOS {
    uuid id PK
    uuid actor_usuario_id FK
    varchar accion
    varchar entidad
    varchar entidad_id
    varchar ip
    text user_agent
    jsonb datos
    timestamptz creado_en
  }
```

## Reglas principales

- Un usuario puede tener muchas bicicletas, pero solo una deberia estar activa.
- Cada QR temporal pertenece a un usuario, una bicicleta y opcionalmente a un
  bicicletero.
- Cada movimiento guarda usuario, bicicleta, bicicletero y guardia que valida.
- El estado real de una bicicleta se guarda en `dentro_bicicletero` y
  `bicicletero_actual_id`.
- Las solicitudes de guardia registran quien pidio ayuda, en que bicicletero,
  que guardia fue asignado y el estado de atencion.
- Los eventos criticos quedan registrados en `auditoria_eventos` para trazabilidad
  operativa y revision posterior.
