export const migracion001EsquemaInicial = {
  id: '001_esquema_inicial',
  descripcion: 'Crea el esquema base de UBBike para despliegues con sincronizacion desactivada.',
  sql: [
    'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";',
    `
    DO $$
    BEGIN
      CREATE TYPE usuarios_rol_enum AS ENUM (
        'ESTUDIANTE',
        'FUNCIONARIO',
        'GUARDIA',
        'ADMIN_CENTRAL',
        'ADMINISTRADOR'
      );
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE movimientos_tipo_enum AS ENUM ('INGRESO', 'SALIDA');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE movimientos_estado_enum AS ENUM ('CONFIRMADO', 'DENEGADO');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE solicitudes_guardia_tipo_enum AS ENUM ('GUARDIA_AUSENTE', 'REQUIERE_SERVICIO');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE solicitudes_guardia_estado_enum AS ENUM (
        'PENDIENTE',
        'NOTIFICADA',
        'VISTA',
        'EN_CAMINO',
        'RESUELTA',
        'CANCELADA'
      );
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE incidencias_estado_enum AS ENUM ('PENDIENTE', 'EN_REVISION', 'RESUELTA', 'DESCARTADA');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE notificaciones_tipo_enum AS ENUM (
        'SISTEMA',
        'CUENTA',
        'SEGURIDAD',
        'SOLICITUD_GUARDIA',
        'MOVIMIENTO'
      );
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    DO $$
    BEGIN
      CREATE TYPE codigos_qr_temporales_tipo_enum AS ENUM ('INGRESO', 'SALIDA');
    EXCEPTION WHEN duplicate_object THEN NULL;
    END $$;
    `,
    `
    CREATE TABLE IF NOT EXISTS usuarios (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      nombre varchar(120) NOT NULL,
      correo varchar(160) NOT NULL UNIQUE,
      rut varchar(20) UNIQUE,
      rol usuarios_rol_enum NOT NULL DEFAULT 'ESTUDIANTE',
      contrasena_hash varchar(255) NOT NULL,
      correo_verificado boolean NOT NULL DEFAULT false,
      cuenta_activa boolean NOT NULL DEFAULT true,
      version_sesion integer NOT NULL DEFAULT 0,
      token_verificacion_correo varchar(120),
      token_cambio_contrasena varchar(120),
      token_cambio_contrasena_expira_en timestamp with time zone,
      creado_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizado_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS bicicleteros (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      nombre varchar(120) NOT NULL UNIQUE,
      ubicacion varchar(255) NOT NULL,
      capacidad integer NOT NULL DEFAULT 80,
      activo boolean NOT NULL DEFAULT true,
      creado_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizado_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS bicicletas (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      descripcion varchar(255) NOT NULL,
      marca varchar(80),
      modelo varchar(80),
      color varchar(60),
      aro varchar(30),
      numero_serie varchar(120),
      foto_url text,
      activa boolean NOT NULL DEFAULT false,
      dentro_bicicletero boolean NOT NULL DEFAULT false,
      bicicletero_actual_id uuid REFERENCES bicicleteros(id),
      creado_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizado_en timestamp with time zone NOT NULL DEFAULT now(),
      eliminado_en timestamp with time zone
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS asignaciones_guardias (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      guardia_id uuid NOT NULL REFERENCES usuarios(id),
      bicicletero_id uuid NOT NULL REFERENCES bicicleteros(id),
      inicia_en timestamp with time zone NOT NULL,
      termina_en timestamp with time zone,
      activa boolean NOT NULL DEFAULT true,
      creada_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizada_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS solicitudes_guardia (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      solicitada_por_usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      bicicletero_id uuid NOT NULL REFERENCES bicicleteros(id),
      guardia_asignado_id uuid REFERENCES usuarios(id),
      tipo solicitudes_guardia_tipo_enum NOT NULL,
      estado solicitudes_guardia_estado_enum NOT NULL DEFAULT 'PENDIENTE',
      mensaje text,
      notificada_guardia_en timestamp with time zone,
      acuse_recibo_en timestamp with time zone,
      resuelta_en timestamp with time zone,
      creada_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizada_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS movimientos (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      bicicleta_id uuid NOT NULL REFERENCES bicicletas(id) ON DELETE CASCADE,
      usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      bicicletero_id uuid NOT NULL REFERENCES bicicleteros(id),
      validado_por_guardia_id uuid NOT NULL REFERENCES usuarios(id),
      tipo movimientos_tipo_enum NOT NULL,
      estado movimientos_estado_enum NOT NULL DEFAULT 'CONFIRMADO',
      motivo_denegacion text,
      origen varchar(30) NOT NULL DEFAULT 'QR',
      creado_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS incidencias (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      bicicletero_id uuid NOT NULL REFERENCES bicicleteros(id),
      bicicleta_id uuid REFERENCES bicicletas(id),
      descripcion text NOT NULL,
      estado incidencias_estado_enum NOT NULL DEFAULT 'PENDIENTE',
      creada_en timestamp with time zone NOT NULL DEFAULT now(),
      actualizada_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS notificaciones (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      titulo varchar(120) NOT NULL,
      mensaje text NOT NULL,
      tipo notificaciones_tipo_enum NOT NULL DEFAULT 'SISTEMA',
      leida boolean NOT NULL DEFAULT false,
      datos jsonb,
      creada_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS codigos_qr_temporales (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      token varchar(160) NOT NULL UNIQUE,
      usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
      bicicleta_id uuid NOT NULL REFERENCES bicicletas(id) ON DELETE CASCADE,
      bicicletero_id uuid REFERENCES bicicleteros(id),
      tipo codigos_qr_temporales_tipo_enum NOT NULL,
      expira_en timestamp with time zone NOT NULL,
      usado boolean NOT NULL DEFAULT false,
      creado_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    `
    CREATE TABLE IF NOT EXISTS auditoria_eventos (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
      actor_usuario_id uuid REFERENCES usuarios(id) ON DELETE SET NULL,
      accion varchar(120) NOT NULL,
      entidad varchar(120) NOT NULL,
      entidad_id varchar(120),
      ip varchar(80),
      user_agent text,
      datos jsonb,
      creado_en timestamp with time zone NOT NULL DEFAULT now()
    );
    `,
    'CREATE INDEX IF NOT EXISTS idx_bicicletas_usuario ON bicicletas(usuario_id);',
    'CREATE INDEX IF NOT EXISTS idx_bicicletas_bicicletero_actual ON bicicletas(bicicletero_actual_id);',
    'CREATE INDEX IF NOT EXISTS idx_asignaciones_guardia_activa ON asignaciones_guardias(guardia_id, bicicletero_id, activa);',
    'CREATE INDEX IF NOT EXISTS idx_solicitudes_guardia_estado ON solicitudes_guardia(estado, creada_en);',
    'CREATE INDEX IF NOT EXISTS idx_solicitudes_guardia_guardia ON solicitudes_guardia(guardia_asignado_id);',
    'CREATE INDEX IF NOT EXISTS idx_movimientos_usuario_creado ON movimientos(usuario_id, creado_en);',
    'CREATE INDEX IF NOT EXISTS idx_movimientos_guardia_creado ON movimientos(validado_por_guardia_id, creado_en);',
    'CREATE INDEX IF NOT EXISTS idx_movimientos_bicicletero_creado ON movimientos(bicicletero_id, creado_en);',
    'CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(usuario_id, leida, creada_en);',
    'CREATE INDEX IF NOT EXISTS idx_qr_token ON codigos_qr_temporales(token);',
    'CREATE INDEX IF NOT EXISTS idx_auditoria_actor_creado ON auditoria_eventos(actor_usuario_id, creado_en);',
    'CREATE INDEX IF NOT EXISTS idx_auditoria_entidad_creado ON auditoria_eventos(entidad, entidad_id, creado_en);'
  ]
};
