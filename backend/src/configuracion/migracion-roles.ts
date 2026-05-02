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
  } finally {
    await cliente.end();
  }
};
