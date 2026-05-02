import { Client } from 'pg';
import { entorno } from './entorno';
import { migraciones } from './migraciones';

const crearCliente = () =>
  new Client({
    host: entorno.baseDatos.host,
    port: entorno.baseDatos.puerto,
    user: entorno.baseDatos.usuario,
    password: entorno.baseDatos.contrasena,
    database: entorno.baseDatos.nombre
  });

export const ejecutarMigraciones = async (): Promise<void> => {
  const cliente = crearCliente();
  await cliente.connect();

  try {
    await cliente.query(`
      CREATE TABLE IF NOT EXISTS migraciones_aplicadas (
        id varchar(160) PRIMARY KEY,
        descripcion text NOT NULL,
        aplicada_en timestamp with time zone NOT NULL DEFAULT now()
      );
    `);

    for (const migracion of migraciones) {
      const aplicada = await cliente.query('SELECT id FROM migraciones_aplicadas WHERE id = $1', [
        migracion.id
      ]);

      if (aplicada.rowCount) {
        continue;
      }

      await cliente.query('BEGIN');
      try {
        for (const sentencia of migracion.sql) {
          await cliente.query(sentencia);
        }

        await cliente.query('INSERT INTO migraciones_aplicadas (id, descripcion) VALUES ($1, $2)', [
          migracion.id,
          migracion.descripcion
        ]);
        await cliente.query('COMMIT');
        console.log(`Migracion aplicada: ${migracion.id}`);
      } catch (error) {
        await cliente.query('ROLLBACK');
        throw error;
      }
    }
  } finally {
    await cliente.end();
  }
};

if (require.main === module) {
  ejecutarMigraciones()
    .then(() => {
      console.log('Migraciones al dia');
    })
    .catch((error) => {
      console.error('No se pudieron ejecutar las migraciones', error);
      process.exit(1);
    });
}
