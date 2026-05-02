import { Repository } from 'typeorm';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Usuario } from './usuario.entidad';

export const obtenerRepositorioUsuarios = (): Repository<Usuario> => {
  return fuenteDatos.getRepository(Usuario);
};
