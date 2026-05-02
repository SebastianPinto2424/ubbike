import { DataSource } from 'typeorm';
import { entorno } from './entorno';

export const fuenteDatos = new DataSource({
  type: 'postgres',
  host: entorno.baseDatos.host,
  port: entorno.baseDatos.puerto,
  username: entorno.baseDatos.usuario,
  password: entorno.baseDatos.contrasena,
  database: entorno.baseDatos.nombre,
  synchronize: entorno.baseDatos.sincronizar,
  logging: entorno.ambiente === 'development' ? ['error', 'warn'] : ['error'],
  // Los modulos agregaran sus entidades con el patron *.entidad.ts/*.entidad.js.
  entities: [`${__dirname}/../modulos/**/*.entidad{.ts,.js}`]
});
