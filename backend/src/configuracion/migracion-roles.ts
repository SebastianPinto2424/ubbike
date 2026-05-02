import { Client } from 'pg';
import { entorno } from './entorno';

const ejecutarSiExisteEnumRoles = async (cliente: Client, sql: string) => {
  try {
    await cliente.query(sql);
  } catch (error) {
    const codigo = (error as { code?: string }).code;
    if (codigo !== '42704' && codigo !== '42P01') {
      throw error;
    }
  }
};

export const prepararCompatibilidadRoles = async (): Promise<void> => {
  const cliente = new Client({
    host: entorno.baseDatos.host,
    port: entorno.baseDatos.puerto,
    user: entorno.baseDatos.usuario,
    password: entorno.baseDatos.contrasena,
    database: entorno.baseDatos.nombre
  });

  await cliente.connect();

  try {
    await ejecutarSiExisteEnumRoles(
      cliente,
      "ALTER TYPE usuarios_rol_enum ADD VALUE IF NOT EXISTS 'ADMIN_CENTRAL'"
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      "ALTER TYPE usuarios_rol_enum ADD VALUE IF NOT EXISTS 'ADMINISTRADOR'"
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      "UPDATE usuarios SET rol = 'ADMIN_CENTRAL' WHERE rol::text = 'CENTRAL'"
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS usuarios ADD COLUMN IF NOT EXISTS version_sesion integer NOT NULL DEFAULT 0'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicleteros ADD COLUMN IF NOT EXISTS capacidad integer NOT NULL DEFAULT 80'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ADD COLUMN IF NOT EXISTS marca varchar(80)'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ADD COLUMN IF NOT EXISTS modelo varchar(80)'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ADD COLUMN IF NOT EXISTS color varchar(60)'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ADD COLUMN IF NOT EXISTS aro varchar(30)'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ADD COLUMN IF NOT EXISTS numero_serie varchar(120)'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS bicicletas ALTER COLUMN foto_url TYPE text'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS solicitudes_guardia ADD COLUMN IF NOT EXISTS notificada_guardia_en timestamp with time zone'
    );
    await ejecutarSiExisteEnumRoles(
      cliente,
      'ALTER TABLE IF EXISTS solicitudes_guardia ADD COLUMN IF NOT EXISTS acuse_recibo_en timestamp with time zone'
    );
  } finally {
    await cliente.end();
  }
};
