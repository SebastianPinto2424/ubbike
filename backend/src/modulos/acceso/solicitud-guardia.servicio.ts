import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import {
  crearNotificacion,
  notificarUsuariosPorRol
} from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { Usuario } from '../usuarios/usuario.entidad';
import { RolUsuario } from '../usuarios/rol-usuario';
import { AsignacionGuardia } from './asignacion-guardia.entidad';
import { EstadoSolicitudGuardia } from './estado-solicitud-guardia';
import { SolicitudGuardia } from './solicitud-guardia.entidad';
import { TipoSolicitudGuardia } from './tipo-solicitud-guardia';

type DatosCrearSolicitud = {
  usuarioId: string;
  bicicleteroId: string;
  tipo: TipoSolicitudGuardia;
  mensaje?: string | null;
};

type DatosListarSolicitudes = {
  usuarioId: string;
  rol: string;
};

const repoSolicitudes = () => fuenteDatos.getRepository(SolicitudGuardia);
const repoBicicleteros = () => fuenteDatos.getRepository(Bicicletero);
const repoAsignaciones = () => fuenteDatos.getRepository(AsignacionGuardia);

const mapearUsuarioSolicitud = (usuario: Usuario | null) => {
  if (!usuario) {
    return null;
  }

  return {
    id: usuario.id,
    nombre: usuario.nombre,
    correo: usuario.correo,
    rut: usuario.rut,
    rol: usuario.rol
  };
};

const mapearSolicitudGuardia = (solicitud: SolicitudGuardia) => ({
  id: solicitud.id,
  tipo: solicitud.tipo,
  estado: solicitud.estado,
  mensaje: solicitud.mensaje,
  creadaEn: solicitud.creadaEn,
  resueltaEn: solicitud.resueltaEn,
  bicicletero: {
    id: solicitud.bicicletero.id,
    nombre: solicitud.bicicletero.nombre,
    ubicacion: solicitud.bicicletero.ubicacion
  },
  solicitante: mapearUsuarioSolicitud(solicitud.solicitadaPorUsuario),
  guardiaAsignado: mapearUsuarioSolicitud(solicitud.guardiaAsignado),
  guardiasAsignados: solicitud.guardiaAsignado
    ? [mapearUsuarioSolicitud(solicitud.guardiaAsignado)]
    : []
});

const buscarAsignacionActiva = async (bicicleteroId: string) => {
  return repoAsignaciones().findOne({
    where: {
      bicicletero: {
        id: bicicleteroId
      },
      activa: true
    },
    relations: {
      guardia: true,
      bicicletero: true
    },
    order: {
      iniciaEn: 'DESC'
    }
  });
};

export const crearSolicitudGuardia = async (datos: DatosCrearSolicitud) => {
  const bicicletero = await repoBicicleteros().findOneBy({
    id: datos.bicicleteroId
  });

  if (!bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado');
  }

  const asignacion = await buscarAsignacionActiva(datos.bicicleteroId);
  const solicitud = repoSolicitudes().create({
    solicitadaPorUsuario: { id: datos.usuarioId } as Usuario,
    bicicletero,
    guardiaAsignado: asignacion?.guardia ?? null,
    tipo: datos.tipo,
    mensaje: datos.mensaje || null
  });

  const solicitudGuardada = await repoSolicitudes().save(solicitud);

  await crearNotificacion({
    usuarioId: datos.usuarioId,
    titulo: 'Solicitud enviada',
    mensaje: `Central recibio tu solicitud para ${bicicletero.nombre}.`,
    tipo: TipoNotificacion.SOLICITUD_GUARDIA,
    datos: { solicitudId: solicitudGuardada.id }
  });

  if (asignacion?.guardia) {
    await crearNotificacion({
      usuarioId: asignacion.guardia.id,
      titulo: 'Se requiere tu presencia',
      mensaje: `Un usuario solicito apoyo en ${bicicletero.nombre}.`,
      tipo: TipoNotificacion.SOLICITUD_GUARDIA,
      datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
    });
  }

  await notificarUsuariosPorRol({
    roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
    titulo: 'Nueva solicitud de guardia',
    mensaje: `${bicicletero.nombre}: ${datos.tipo.replace('_', ' ').toLowerCase()}.`,
    tipo: TipoNotificacion.SOLICITUD_GUARDIA,
    datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
  });

  const solicitudCompleta = await repoSolicitudes().findOneOrFail({
    where: { id: solicitudGuardada.id },
    relations: {
      solicitadaPorUsuario: true,
      bicicletero: true,
      guardiaAsignado: true
    }
  });

  return mapearSolicitudGuardia(solicitudCompleta);
};

export const listarSolicitudesGuardia = async (datos: DatosListarSolicitudes) => {
  const consulta = repoSolicitudes()
    .createQueryBuilder('solicitud')
    .leftJoinAndSelect('solicitud.solicitadaPorUsuario', 'usuario')
    .leftJoinAndSelect('solicitud.bicicletero', 'bicicletero')
    .leftJoinAndSelect('solicitud.guardiaAsignado', 'guardia')
    .orderBy('solicitud.creadaEn', 'DESC');

  if (datos.rol === RolUsuario.GUARDIA) {
    consulta.where('guardia.id = :usuarioId', { usuarioId: datos.usuarioId });
  } else if (
    ![RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(datos.rol as RolUsuario)
  ) {
    consulta.where('usuario.id = :usuarioId', { usuarioId: datos.usuarioId });
  }

  const solicitudes = await consulta.getMany();
  return solicitudes.map(mapearSolicitudGuardia);
};

export const actualizarEstadoSolicitudGuardia = async (
  usuarioId: string,
  rol: string,
  solicitudId: string,
  estado: EstadoSolicitudGuardia
) => {
  if (
    ![RolUsuario.GUARDIA, RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(
      rol as RolUsuario
    )
  ) {
    throw new ErrorHttp(403, 'No tienes permisos para actualizar solicitudes');
  }

  const solicitud = await repoSolicitudes().findOne({
    where: { id: solicitudId },
    relations: {
      solicitadaPorUsuario: true,
      bicicletero: true,
      guardiaAsignado: true
    }
  });

  if (!solicitud) {
    throw new ErrorHttp(404, 'Solicitud no encontrada');
  }

  if (rol === RolUsuario.GUARDIA && solicitud.guardiaAsignado?.id !== usuarioId) {
    throw new ErrorHttp(403, 'La solicitud no esta asignada a este guardia');
  }

  solicitud.estado = estado;
  solicitud.resueltaEn =
    estado === EstadoSolicitudGuardia.RESUELTA || estado === EstadoSolicitudGuardia.CANCELADA
      ? new Date()
      : null;

  const solicitudActualizada = await repoSolicitudes().save(solicitud);

  await crearNotificacion({
    usuarioId: solicitud.solicitadaPorUsuario.id,
    titulo: 'Solicitud actualizada',
    mensaje: `${solicitud.bicicletero.nombre}: estado ${estado.toLowerCase()}.`,
    tipo: TipoNotificacion.SOLICITUD_GUARDIA,
    datos: { solicitudId: solicitud.id, estado }
  });

  if (
    estado === EstadoSolicitudGuardia.NOTIFICADA &&
    solicitud.guardiaAsignado &&
    [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(rol as RolUsuario)
  ) {
    await crearNotificacion({
      usuarioId: solicitud.guardiaAsignado.id,
      titulo: 'Recordatorio de central',
      mensaje: `Central solicito atender ${solicitud.bicicletero.nombre}.`,
      tipo: TipoNotificacion.SOLICITUD_GUARDIA,
      datos: {
        solicitudId: solicitud.id,
        bicicleteroId: solicitud.bicicletero.id,
        estado
      }
    });
  }

  const solicitudCompleta = await repoSolicitudes().findOneOrFail({
    where: { id: solicitudActualizada.id },
    relations: {
      solicitadaPorUsuario: true,
      bicicletero: true,
      guardiaAsignado: true
    }
  });

  return mapearSolicitudGuardia(solicitudCompleta);
};
