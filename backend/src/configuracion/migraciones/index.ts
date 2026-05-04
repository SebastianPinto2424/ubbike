import { migracion001EsquemaInicial } from './001_esquema_inicial';
import { migracion002ExpiracionVerificacionCorreo } from './002_expiracion_verificacion_correo';

export type MigracionSql = {
  id: string;
  descripcion: string;
  sql: string[];
};

export const migraciones: MigracionSql[] = [
  migracion001EsquemaInicial,
  migracion002ExpiracionVerificacionCorreo
];
