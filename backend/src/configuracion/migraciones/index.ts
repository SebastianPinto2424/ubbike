import { migracion001EsquemaInicial } from './001_esquema_inicial';

export type MigracionSql = {
  id: string;
  descripcion: string;
  sql: string[];
};

export const migraciones: MigracionSql[] = [migracion001EsquemaInicial];
