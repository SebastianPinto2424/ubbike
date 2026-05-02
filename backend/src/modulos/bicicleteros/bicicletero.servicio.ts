import { fuenteDatos } from '../../configuracion/base-datos';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Bicicletero } from './bicicletero.entidad';

export const listarBicicleteros = async () => {
  const bicicleteros = await fuenteDatos.getRepository(Bicicletero).find({
    where: {
      activo: true
    },
    order: {
      nombre: 'ASC'
    }
  });

  const repoBicicletas = fuenteDatos.getRepository(Bicicleta);

  return Promise.all(
    bicicleteros.map(async (bicicletero) => {
      const ocupados = await repoBicicletas.count({
        where: {
          dentroBicicletero: true,
          bicicleteroActual: {
            id: bicicletero.id
          }
        }
      });
      const capacidad = Math.max(bicicletero.capacidad, 1);

      return {
        id: bicicletero.id,
        nombre: bicicletero.nombre,
        ubicacion: bicicletero.ubicacion,
        capacidad,
        ocupados,
        cuposDisponibles: Math.max(capacidad - ocupados, 0),
        porcentajeUso: Math.min(Math.round((ocupados / capacidad) * 100), 100)
      };
    })
  );
};
