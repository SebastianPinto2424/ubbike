import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { crearNotificacion } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { Usuario } from '../usuarios/usuario.entidad';
import { AsignacionGuardia } from './asignacion-guardia.entidad';

const repoAsignaciones = () => fuenteDatos.getRepository(AsignacionGuardia);
const repoBicicleteros = () => fuenteDatos.getRepository(Bicicletero);
const repoBicicletas = () => fuenteDatos.getRepository(Bicicleta);

const mapearBicicletero = async (bicicletero: Bicicletero) => {
  const ocupados = await repoBicicletas().count({
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
};

const mapearAsignacion = async (asignacion: AsignacionGuardia) => ({
  id: asignacion.id,
  iniciaEn: asignacion.iniciaEn,
  bicicletero: await mapearBicicletero(asignacion.bicicletero)
});

export const obtenerAsignacionActivaGuardia = async (guardiaId: string) => {
  const asignacion = await repoAsignaciones().findOne({
    where: {
      guardia: { id: guardiaId },
      activa: true
    },
    relations: {
      bicicletero: true
    },
    order: {
      iniciaEn: 'DESC'
    }
  });

  return asignacion ? mapearAsignacion(asignacion) : null;
};

export const seleccionarBicicleteroGuardia = async (
  guardiaId: string,
  bicicleteroId: string
) => {
  const bicicletero = await repoBicicleteros().findOne({
    where: {
      id: bicicleteroId,
      activo: true
    }
  });

  if (!bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado o inactivo');
  }

  const ahora = new Date();

  await repoAsignaciones()
    .createQueryBuilder()
    .update(AsignacionGuardia)
    .set({
      activa: false,
      terminaEn: ahora
    })
    .where('guardia_id = :guardiaId', { guardiaId })
    .andWhere('activa = true')
    .execute();

  const asignacion = await repoAsignaciones().save(
    repoAsignaciones().create({
      guardia: { id: guardiaId } as Usuario,
      bicicletero,
      iniciaEn: ahora,
      terminaEn: null,
      activa: true
    })
  );

  await registrarAuditoria({
    actorUsuarioId: guardiaId,
    accion: 'GUARDIA_BICICLETERO_SELECCIONADO',
    entidad: 'asignaciones_guardias',
    entidadId: asignacion.id,
    datos: {
      bicicleteroId: bicicletero.id
    }
  });

  await crearNotificacion({
    usuarioId: guardiaId,
    titulo: 'Bicicletero de turno actualizado',
    mensaje: `Ahora gestionas ${bicicletero.nombre}.`,
    tipo: TipoNotificacion.SISTEMA,
    datos: {
      bicicleteroId: bicicletero.id,
      asignacionId: asignacion.id
    }
  });

  asignacion.bicicletero = bicicletero;
  return mapearAsignacion(asignacion);
};
