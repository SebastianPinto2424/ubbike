import { fuenteDatos } from '../../configuracion/base-datos';
import { Bicicletero } from './bicicletero.entidad';

export const listarBicicleteros = async () => {
  return fuenteDatos.getRepository(Bicicletero).find({
    where: {
      activo: true
    },
    order: {
      nombre: 'ASC'
    }
  });
};
