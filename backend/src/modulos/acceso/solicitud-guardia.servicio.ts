import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
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

const segundosEsperaRecordatorio = 90;

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

const calcularSegundosParaRecordatorio = (solicitud: SolicitudGuardia) => {
  if (
    solicitud.acuseReciboEn ||
    [EstadoSolicitudGuardia.VISTA, EstadoSolicitudGuardia.EN_CAMINO].includes(solicitud.estado) ||
    [EstadoSolicitudGuardia.RESUELTA, EstadoSolicitudGuardia.CANCELADA].includes(solicitud.estado)
  ) {
    return null;
  }

  const base = solicitud.notificadaGuardiaEn ?? solicitud.creadaEn;
  const transcurridos = Math.floor((Date.now() - base.getTime()) / 1000);
  return Math.max(segundosEsperaRecordatorio - transcurridos, 0);
};

const mapearSolicitudGuardia = (solicitud: SolicitudGuardia) => {
  const segundosParaNotificarGuardia = calcularSegundosParaRecordatorio(solicitud);

  return {
    id: solicitud.id,
    tipo: solicitud.tipo,
    estado: solicitud.estado,
    mensaje: solicitud.mensaje,
    creadaEn: solicitud.creadaEn,
    notificadaGuardiaEn: solicitud.notificadaGuardiaEn,
    acuseReciboEn: solicitud.acuseReciboEn,
    resueltaEn: solicitud.resueltaEn,
    puedeNotificarGuardia: Boolean(solicitud.guardiaAsignado) && segundosParaNotificarGuardia === 0,
    segundosParaNotificarGuardia,
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
  };
};

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

const validarRecordatorioCentral = (solicitud: SolicitudGuardia, rol: string) => {
  if (![RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(rol as RolUsuario)) {
    throw new ErrorHttp(403, 'Solo central puede reenviar la notificacion al guardia');
  }

  if (!solicitud.guardiaAsignado) {
    throw new ErrorHttp(409, 'No hay guardia asignado para este bicicletero');
  }

  if (
    solicitud.acuseReciboEn ||
    [EstadoSolicitudGuardia.VISTA, EstadoSolicitudGuardia.EN_CAMINO].includes(solicitud.estado)
  ) {
    throw new ErrorHttp(409, 'El guardia ya acuso recibo de la solicitud');
  }

  if (
    [EstadoSolicitudGuardia.RESUELTA, EstadoSolicitudGuardia.CANCELADA].includes(solicitud.estado)
  ) {
    throw new ErrorHttp(409, 'La solicitud ya esta cerrada');
  }

  const segundosRestantes = calcularSegundosParaRecordatorio(solicitud);

  if (segundosRestantes !== null && segundosRestantes > 0) {
    throw new ErrorHttp(409, `Central podra notificar nuevamente en ${segundosRestantes} segundos`);
  }
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
    mensaje: datos.mensaje || null,
    notificadaGuardiaEn: asignacion?.guardia ? new Date() : null
  });

  const solicitudGuardada = await repoSolicitudes().save(solicitud);

  await crearNotificacion({
    usuarioId: datos.usuarioId,
    titulo: 'Solicitud enviada',
    mensaje: asignacion?.guardia
      ? `${asignacion.guardia.nombre} fue notificado y central recibio copia para ${bicicletero.nombre}.`
      : `Central recibio tu solicitud para ${bicicletero.nombre}.`,
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

  await registrarAuditoria({
    actorUsuarioId: datos.usuarioId,
    accion: 'SOLICITUD_GUARDIA_CREADA',
    entidad: 'solicitudes_guardia',
    entidadId: solicitudGuardada.id,
    datos: {
      bicicleteroId: bicicletero.id,
      guardiaAsignadoId: asignacion?.guardia.id ?? null,
      tipo: datos.tipo
    }
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

  if (estado === EstadoSolicitudGuardia.NOTIFICADA) {
    validarRecordatorioCentral(solicitud, rol);
  }

  const guardiaAcusaRecibo =
    rol === RolUsuario.GUARDIA &&
    [EstadoSolicitudGuardia.VISTA, EstadoSolicitudGuardia.EN_CAMINO].includes(estado);

  solicitud.estado = estado;
  solicitud.notificadaGuardiaEn =
    estado === EstadoSolicitudGuardia.NOTIFICADA ? new Date() : solicitud.notificadaGuardiaEn;
  solicitud.acuseReciboEn =
    guardiaAcusaRecibo && !solicitud.acuseReciboEn ? new Date() : solicitud.acuseReciboEn;
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
    [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(rol as RolUsuario)
  ) {
    await crearNotificacion({
      usuarioId: solicitud.guardiaAsignado!.id,
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

  if (guardiaAcusaRecibo) {
    await notificarUsuariosPorRol({
      roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
      titulo: 'Guardia acuso recibo',
      mensaje: `${solicitud.guardiaAsignado!.nombre} acuso recibo para ${solicitud.bicicletero.nombre}.`,
      tipo: TipoNotificacion.SOLICITUD_GUARDIA,
      datos: {
        solicitudId: solicitud.id,
        bicicleteroId: solicitud.bicicletero.id,
        estado
      }
    });
  }

  await registrarAuditoria({
    actorUsuarioId: usuarioId,
    accion: 'SOLICITUD_GUARDIA_ESTADO_ACTUALIZADO',
    entidad: 'solicitudes_guardia',
    entidadId: solicitud.id,
    datos: {
      estado,
      rolActor: rol,
      bicicleteroId: solicitud.bicicletero.id,
      guardiaAsignadoId: solicitud.guardiaAsignado?.id ?? null
    }
  });

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
