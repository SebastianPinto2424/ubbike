import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Usuario } from '../usuarios/usuario.entidad';
import { Bicicleta } from './bicicleta.entidad';

type DatosCrearBicicleta = {
  usuarioId: string;
  descripcion: string;
  marca?: string | null;
  modelo?: string | null;
  color?: string | null;
  aro?: string | null;
  numeroSerie?: string | null;
  fotoUrl?: string | null;
  activar?: boolean;
};

type DatosActualizarBicicleta = {
  descripcion?: string;
  marca?: string | null;
  modelo?: string | null;
  color?: string | null;
  aro?: string | null;
  numeroSerie?: string | null;
  fotoUrl?: string | null;
};

const repositorioBicicletas = () => fuenteDatos.getRepository(Bicicleta);

const mapearBicicleta = (bicicleta: Bicicleta) => ({
  id: bicicleta.id,
  descripcion: bicicleta.descripcion,
  marca: bicicleta.marca,
  modelo: bicicleta.modelo,
  color: bicicleta.color,
  aro: bicicleta.aro,
  numeroSerie: bicicleta.numeroSerie,
  fotoUrl: bicicleta.fotoUrl,
  activa: bicicleta.activa,
  dentroBicicletero: bicicleta.dentroBicicletero,
  bicicleteroActual: bicicleta.bicicleteroActual
    ? {
        id: bicicleta.bicicleteroActual.id,
        nombre: bicicleta.bicicleteroActual.nombre
      }
    : null,
  creadoEn: bicicleta.creadoEn,
  actualizadoEn: bicicleta.actualizadoEn
});

const buscarBicicletaUsuario = async (usuarioId: string, bicicletaId: string) => {
  const bicicleta = await repositorioBicicletas().findOne({
    where: {
      id: bicicletaId,
      usuario: {
        id: usuarioId
      }
    },
    relations: {
      usuario: true,
      bicicleteroActual: true
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(404, 'Bicicleta no encontrada');
  }

  return bicicleta;
};

const dejarSoloActiva = async (usuarioId: string, bicicletaId: string) => {
  await repositorioBicicletas()
    .createQueryBuilder()
    .update(Bicicleta)
    .set({ activa: false })
    .where('usuario_id = :usuarioId', { usuarioId })
    .execute();

  await repositorioBicicletas().update(
    {
      id: bicicletaId
    },
    {
      activa: true
    }
  );
};

export const listarBicicletasUsuario = async (usuarioId: string) => {
  const bicicletas = await repositorioBicicletas().find({
    where: {
      usuario: {
        id: usuarioId
      }
    },
    relations: {
      bicicleteroActual: true
    },
    order: {
      activa: 'DESC',
      actualizadoEn: 'DESC'
    }
  });

  return bicicletas.map(mapearBicicleta);
};

export const obtenerBicicletaActivaUsuario = async (usuarioId: string) => {
  const bicicleta = await repositorioBicicletas().findOne({
    where: {
      usuario: {
        id: usuarioId
      },
      activa: true
    },
    relations: {
      bicicleteroActual: true
    }
  });

  return bicicleta ? mapearBicicleta(bicicleta) : null;
};

export const crearBicicleta = async (datos: DatosCrearBicicleta) => {
  const totalBicicletas = await repositorioBicicletas().count({
    where: {
      usuario: {
        id: datos.usuarioId
      }
    }
  });

  const bicicleta = repositorioBicicletas().create({
    usuario: { id: datos.usuarioId } as Usuario,
    descripcion: datos.descripcion,
    marca: datos.marca || null,
    modelo: datos.modelo || null,
    color: datos.color || null,
    aro: datos.aro || null,
    numeroSerie: datos.numeroSerie || null,
    fotoUrl: datos.fotoUrl || null,
    activa: totalBicicletas === 0 || datos.activar === true,
    dentroBicicletero: false,
    bicicleteroActual: null
  });

  const guardada = await repositorioBicicletas().save(bicicleta);

  if (guardada.activa) {
    await dejarSoloActiva(datos.usuarioId, guardada.id);
  }

  const actualizada = await buscarBicicletaUsuario(datos.usuarioId, guardada.id);
  return mapearBicicleta(actualizada);
};

export const actualizarBicicleta = async (
  usuarioId: string,
  bicicletaId: string,
  datos: DatosActualizarBicicleta
) => {
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);

  if (datos.descripcion !== undefined) {
    bicicleta.descripcion = datos.descripcion;
  }

  if (datos.marca !== undefined) {
    bicicleta.marca = datos.marca || null;
  }

  if (datos.modelo !== undefined) {
    bicicleta.modelo = datos.modelo || null;
  }

  if (datos.color !== undefined) {
    bicicleta.color = datos.color || null;
  }

  if (datos.aro !== undefined) {
    bicicleta.aro = datos.aro || null;
  }

  if (datos.numeroSerie !== undefined) {
    bicicleta.numeroSerie = datos.numeroSerie || null;
  }

  if (datos.fotoUrl !== undefined) {
    bicicleta.fotoUrl = datos.fotoUrl || null;
  }

  const guardada = await repositorioBicicletas().save(bicicleta);
  return mapearBicicleta(guardada);
};

export const eliminarBicicleta = async (usuarioId: string, bicicletaId: string) => {
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);
  const estabaActiva = bicicleta.activa;

  // Soft delete para mantener historial/auditoria
  await repositorioBicicletas().softRemove(bicicleta);

  if (estabaActiva) {
    const siguiente = await repositorioBicicletas().findOne({
      where: {
        usuario: {
          id: usuarioId
        }
      },
      order: {
        actualizadoEn: 'DESC'
      }
    });

    if (siguiente) {
      await dejarSoloActiva(usuarioId, siguiente.id);
    }
  }

  return {
    message: 'Bicicleta eliminada correctamente'
  };
};

export const activarBicicleta = async (usuarioId: string, bicicletaId: string) => {
  await buscarBicicletaUsuario(usuarioId, bicicletaId);
  await dejarSoloActiva(usuarioId, bicicletaId);
  const bicicleta = await buscarBicicletaUsuario(usuarioId, bicicletaId);
  return mapearBicicleta(bicicleta);
};
