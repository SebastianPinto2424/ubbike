import { ErrorHttp } from '../../../comun/errors/error-http';
import { prisma } from '../../../configuracion/prisma';
import { Prisma } from '../../../generated/prisma/client';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import {
  crearNotificacion,
  notificarUsuariosPorRol
} from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';
import { RolUsuario } from '../../usuarios/rol-usuario';
import { EstadoSolicitudGuardia } from './estado-solicitud-guardia';
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
const rolesCentral: string[] = [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR];
const rolesGestionSolicitudes: string[] = [
  RolUsuario.GUARDIA,
  RolUsuario.ADMIN_CENTRAL,
  RolUsuario.ADMINISTRADOR
];
const estadosAcuseGuardia: EstadoSolicitudGuardia[] = [
  EstadoSolicitudGuardia.VISTA,
  EstadoSolicitudGuardia.EN_CAMINO
];
const estadosCerrados: EstadoSolicitudGuardia[] = [
  EstadoSolicitudGuardia.RESUELTA,
  EstadoSolicitudGuardia.CANCELADA
];

const includeSolicitudCompleta = {
  solicitadaPorUsuario: true,
  bicicletero: true,
  guardiaAsignado: true
} satisfies Prisma.SolicitudGuardiaInclude;

type SolicitudCompleta = Prisma.SolicitudGuardiaGetPayload<{
  include: typeof includeSolicitudCompleta;
}>;

const mapearUsuarioSolicitud = (
  usuario: SolicitudCompleta['solicitadaPorUsuario'] | SolicitudCompleta['guardiaAsignado']
) => {
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

const calcularSegundosParaRecordatorio = (solicitud: SolicitudCompleta) => {
  if (
    solicitud.acuseReciboEn ||
    estadosAcuseGuardia.includes(solicitud.estado) ||
    estadosCerrados.includes(solicitud.estado)
  ) {
    return null;
  }

  const base = solicitud.notificadaGuardiaEn ?? solicitud.creadaEn;
  const transcurridos = Math.floor((Date.now() - base.getTime()) / 1000);
  return Math.max(segundosEsperaRecordatorio - transcurridos, 0);
};

const mapearSolicitudGuardia = (solicitud: SolicitudCompleta) => {
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

const validarRecordatorioCentral = (solicitud: SolicitudCompleta, rol: string) => {
  if (!rolesCentral.includes(rol)) {
    throw new ErrorHttp(403, 'Solo central puede reenviar la notificacion al guardia');
  }

  if (!solicitud.guardiaAsignado) {
    throw new ErrorHttp(409, 'No hay guardia asignado para este bicicletero');
  }

  if (solicitud.acuseReciboEn || estadosAcuseGuardia.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'El guardia ya acuso recibo de la solicitud');
  }

  if (estadosCerrados.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'La solicitud ya esta cerrada');
  }

  const segundosRestantes = calcularSegundosParaRecordatorio(solicitud);

  if (segundosRestantes !== null && segundosRestantes > 0) {
    throw new ErrorHttp(409, `Central podra notificar nuevamente en ${segundosRestantes} segundos`);
  }
};

export const crearSolicitudGuardia = async (datos: DatosCrearSolicitud) => {
  return prisma.$transaction(async (db) => {
    const bicicletero = await db.bicicletero.findUnique({
      where: {
        id: datos.bicicleteroId
      }
    });

    if (!bicicletero) {
      throw new ErrorHttp(404, 'Bicicletero no encontrado');
    }

    const asignacion = await db.asignacionGuardia.findFirst({
      where: {
        bicicleteroId: datos.bicicleteroId,
        activa: true
      },
      include: {
        guardia: true
      },
      orderBy: {
        iniciaEn: 'desc'
      }
    });

    const solicitudGuardada = await db.solicitudGuardia.create({
      data: {
        solicitadaPorUsuarioId: datos.usuarioId,
        bicicleteroId: bicicletero.id,
        guardiaAsignadoId: asignacion?.guardia.id ?? null,
        tipo: datos.tipo,
        mensaje: datos.mensaje || null,
        notificadaGuardiaEn: asignacion?.guardia ? new Date() : null
      }
    });

    await crearNotificacion(
      {
        usuarioId: datos.usuarioId,
        titulo: 'Solicitud enviada',
        mensaje: asignacion?.guardia
          ? `${asignacion.guardia.nombre} fue notificado y central recibio copia para ${bicicletero.nombre}.`
          : `Central recibio tu solicitud para ${bicicletero.nombre}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitudGuardada.id }
      },
      db
    );

    if (asignacion?.guardia) {
      await crearNotificacion(
        {
          usuarioId: asignacion.guardia.id,
          titulo: 'Se requiere tu presencia',
          mensaje: `Un usuario solicito apoyo en ${bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
        },
        db
      );
    }

    await notificarUsuariosPorRol(
      {
        roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
        titulo: 'Nueva solicitud de guardia',
        mensaje: `${bicicletero.nombre}: ${datos.tipo.replace('_', ' ').toLowerCase()}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitudGuardada.id, bicicleteroId: bicicletero.id }
      },
      db
    );

    await registrarAuditoria(
      {
        actorUsuarioId: datos.usuarioId,
        accion: 'SOLICITUD_GUARDIA_CREADA',
        entidad: 'solicitudes_guardia',
        entidadId: solicitudGuardada.id,
        datos: {
          bicicleteroId: bicicletero.id,
          guardiaAsignadoId: asignacion?.guardia.id ?? null,
          tipo: datos.tipo
        }
      },
      db
    );

    const solicitudCompleta = await db.solicitudGuardia.findUniqueOrThrow({
      where: { id: solicitudGuardada.id },
      include: includeSolicitudCompleta
    });

    return mapearSolicitudGuardia(solicitudCompleta);
  });
};

export const listarSolicitudesGuardia = async (datos: DatosListarSolicitudes) => {
  const solicitudes = await prisma.solicitudGuardia.findMany({
    where:
      datos.rol === RolUsuario.GUARDIA
        ? {
            guardiaAsignadoId: datos.usuarioId
          }
        : rolesCentral.includes(datos.rol)
          ? {}
          : {
              solicitadaPorUsuarioId: datos.usuarioId
            },
    include: includeSolicitudCompleta,
    orderBy: {
      creadaEn: 'desc'
    }
  });

  return solicitudes.map(mapearSolicitudGuardia);
};

export const actualizarEstadoSolicitudGuardia = async (
  usuarioId: string,
  rol: string,
  solicitudId: string,
  estado: EstadoSolicitudGuardia
) => {
  if (!rolesGestionSolicitudes.includes(rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para actualizar solicitudes');
  }

  return prisma.$transaction(async (db) => {
    const solicitud = await db.solicitudGuardia.findUnique({
      where: { id: solicitudId },
      include: includeSolicitudCompleta
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

    const guardiaAcusaRecibo = rol === RolUsuario.GUARDIA && estadosAcuseGuardia.includes(estado);

    const solicitudActualizada = await db.solicitudGuardia.update({
      where: { id: solicitud.id },
      data: {
        estado,
        notificadaGuardiaEn:
          estado === EstadoSolicitudGuardia.NOTIFICADA ? new Date() : solicitud.notificadaGuardiaEn,
        acuseReciboEn:
          guardiaAcusaRecibo && !solicitud.acuseReciboEn ? new Date() : solicitud.acuseReciboEn,
        resueltaEn:
          estado === EstadoSolicitudGuardia.RESUELTA || estado === EstadoSolicitudGuardia.CANCELADA
            ? new Date()
            : null
      },
      include: includeSolicitudCompleta
    });

    await crearNotificacion(
      {
        usuarioId: solicitud.solicitadaPorUsuario.id,
        titulo: 'Solicitud actualizada',
        mensaje: `${solicitud.bicicletero.nombre}: estado ${estado.toLowerCase()}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitud.id, estado }
      },
      db
    );

    if (estado === EstadoSolicitudGuardia.NOTIFICADA && rolesCentral.includes(rol)) {
      await crearNotificacion(
        {
          usuarioId: solicitud.guardiaAsignado!.id,
          titulo: 'Recordatorio de central',
          mensaje: `Central solicito atender ${solicitud.bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: {
            solicitudId: solicitud.id,
            bicicleteroId: solicitud.bicicletero.id,
            estado
          }
        },
        db
      );
    }

    if (guardiaAcusaRecibo) {
      await notificarUsuariosPorRol(
        {
          roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
          titulo: 'Guardia acuso recibo',
          mensaje: `${solicitud.guardiaAsignado!.nombre} acuso recibo para ${solicitud.bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: {
            solicitudId: solicitud.id,
            bicicleteroId: solicitud.bicicletero.id,
            estado
          }
        },
        db
      );
    }

    await registrarAuditoria(
      {
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
      },
      db
    );

    return mapearSolicitudGuardia(solicitudActualizada);
  });
};
