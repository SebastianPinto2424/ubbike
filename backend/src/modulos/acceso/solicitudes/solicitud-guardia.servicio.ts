import { ErrorHttp } from '../../../comun/errors/error-http';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';
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

type DatosNotificarGuardia = {
  usuarioId: string;
  rol: string;
  solicitudId: string;
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
const estadosCerrados: EstadoSolicitudGuardia[] = [
  EstadoSolicitudGuardia.RESUELTA,
  EstadoSolicitudGuardia.CANCELADA
];

const etiquetaEstadoSolicitud = (estado: EstadoSolicitudGuardia) => {
  switch (estado) {
    case EstadoSolicitudGuardia.PENDIENTE:
      return 'pendiente';
    case EstadoSolicitudGuardia.NOTIFICADA:
      return 'guardia notificado';
    case EstadoSolicitudGuardia.EN_CAMINO:
      return 'guardia en camino';
    case EstadoSolicitudGuardia.RESUELTA:
      return 'resuelta';
    case EstadoSolicitudGuardia.CANCELADA:
      return 'cancelada';
    default:
      return estado;
  }
};

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
    solicitud.respondidaPorGuardiaEn ||
    solicitud.estado === EstadoSolicitudGuardia.EN_CAMINO ||
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
    ultimaNotificacionUsuarioEn: solicitud.ultimaNotificacionUsuarioEn,
    notificacionesGuardia: solicitud.notificacionesGuardia,
    respondidaPorGuardiaEn: solicitud.respondidaPorGuardiaEn,
    enCaminoEn: solicitud.enCaminoEn,
    resueltaEn: solicitud.resueltaEn,
    puedeNotificarGuardia: Boolean(solicitud.guardiaAsignado) && segundosParaNotificarGuardia === 0,
    puedeNotificarGuardiaUsuario:
      Boolean(solicitud.guardiaAsignado) && !estadosCerrados.includes(solicitud.estado),
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

  if (
    solicitud.respondidaPorGuardiaEn ||
    solicitud.estado === EstadoSolicitudGuardia.EN_CAMINO
  ) {
    throw new ErrorHttp(409, 'El guardia ya respondio esta solicitud');
  }

  if (estadosCerrados.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'La solicitud ya esta cerrada');
  }

  const segundosRestantes = calcularSegundosParaRecordatorio(solicitud);

  if (segundosRestantes !== null && segundosRestantes > 0) {
    throw new ErrorHttp(409, `Central podra notificar nuevamente en ${segundosRestantes} segundos`);
  }
};

const notificarGuardiaAsignado = async (
  solicitud: SolicitudCompleta,
  db: ClientePrisma,
  titulo = 'Solicitud de apoyo reiterada'
) => {
  if (!solicitud.guardiaAsignado) {
    return;
  }

  await crearNotificacion(
    {
      usuarioId: solicitud.guardiaAsignado.id,
      titulo,
      mensaje: `${solicitud.solicitadaPorUsuario.nombre} solicita apoyo en ${solicitud.bicicletero.nombre}.`,
      tipo: TipoNotificacion.SOLICITUD_GUARDIA,
      datos: {
        solicitudId: solicitud.id,
        bicicleteroId: solicitud.bicicletero.id,
        solicitanteId: solicitud.solicitadaPorUsuario.id
      }
    },
    db
  );
};

const reiterarSolicitudAbierta = async (
  solicitud: SolicitudCompleta,
  usuarioId: string,
  rol: string,
  mensaje: string | null | undefined,
  db: ClientePrisma
) => {
  const esCentral = rolesCentral.includes(rol);
  const esSolicitante = solicitud.solicitadaPorUsuario.id === usuarioId;

  if (!esCentral && !esSolicitante) {
    throw new ErrorHttp(403, 'Solo el solicitante o central pueden notificar nuevamente');
  }

  if (estadosCerrados.includes(solicitud.estado)) {
    throw new ErrorHttp(409, 'La solicitud ya esta cerrada');
  }

  const mensajeLimpio = mensaje?.trim();
  const ahora = new Date();

  if (!solicitud.guardiaAsignado) {
    const solicitudActualizada = await db.solicitudGuardia.update({
      where: { id: solicitud.id },
      data: {
        mensaje: mensajeLimpio || solicitud.mensaje
      },
      include: includeSolicitudCompleta
    });

    await notificarUsuariosPorRol(
      {
        roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
        titulo: 'Solicitud reiterada sin guardia asignado',
        mensaje: `${solicitud.bicicletero.nombre}: el usuario solicito apoyo nuevamente.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: {
          solicitudId: solicitud.id,
          bicicleteroId: solicitud.bicicletero.id,
          solicitanteId: solicitud.solicitadaPorUsuario.id
        }
      },
      db
    );

    await registrarAuditoria(
      {
        actorUsuarioId: usuarioId,
        accion: 'SOLICITUD_GUARDIA_REITERADA_SIN_GUARDIA',
        entidad: 'solicitudes_guardia',
        entidadId: solicitud.id,
        datos: {
          rolActor: rol,
          bicicleteroId: solicitud.bicicletero.id
        }
      },
      db
    );

    return solicitudActualizada;
  }

  const solicitudActualizada = await db.solicitudGuardia.update({
    where: { id: solicitud.id },
    data: {
      estado:
        solicitud.estado === EstadoSolicitudGuardia.PENDIENTE
          ? EstadoSolicitudGuardia.NOTIFICADA
          : solicitud.estado,
      mensaje: mensajeLimpio || solicitud.mensaje,
      notificadaGuardiaEn: ahora,
      ultimaNotificacionUsuarioEn: esSolicitante ? ahora : solicitud.ultimaNotificacionUsuarioEn,
      notificacionesGuardia: {
        increment: 1
      }
    },
    include: includeSolicitudCompleta
  });

  await notificarGuardiaAsignado(solicitudActualizada, db);

  await registrarAuditoria(
    {
      actorUsuarioId: usuarioId,
      accion: 'SOLICITUD_GUARDIA_RENOTIFICADA',
      entidad: 'solicitudes_guardia',
      entidadId: solicitud.id,
      datos: {
        rolActor: rol,
        bicicleteroId: solicitud.bicicletero.id,
        guardiaAsignadoId: solicitud.guardiaAsignado.id,
        notificacionesGuardia: solicitudActualizada.notificacionesGuardia
      }
    },
    db
  );

  return solicitudActualizada;
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

    const solicitudAbierta = await db.solicitudGuardia.findFirst({
      where: {
        solicitadaPorUsuarioId: datos.usuarioId,
        bicicleteroId: bicicletero.id,
        tipo: datos.tipo,
        estado: {
          notIn: estadosCerrados
        }
      },
      include: includeSolicitudCompleta,
      orderBy: {
        creadaEn: 'desc'
      }
    });

    if (solicitudAbierta) {
      const solicitudReiterada = await reiterarSolicitudAbierta(
        solicitudAbierta,
        datos.usuarioId,
        solicitudAbierta.solicitadaPorUsuario.rol,
        datos.mensaje,
        db
      );

      await crearNotificacion(
        {
          usuarioId: datos.usuarioId,
          titulo: 'Recordatorio enviado',
          mensaje: solicitudReiterada.guardiaAsignado
            ? `${solicitudReiterada.guardiaAsignado.nombre} recibio un nuevo aviso para ${bicicletero.nombre}.`
            : `Central recibio nuevamente tu solicitud para ${bicicletero.nombre}.`,
          tipo: TipoNotificacion.SOLICITUD_GUARDIA,
          datos: { solicitudId: solicitudReiterada.id }
        },
        db
      );

      return mapearSolicitudGuardia(solicitudReiterada);
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
        estado: asignacion?.guardia
          ? EstadoSolicitudGuardia.NOTIFICADA
          : EstadoSolicitudGuardia.PENDIENTE,
        mensaje: datos.mensaje || null,
        notificadaGuardiaEn: asignacion?.guardia ? new Date() : null,
        ultimaNotificacionUsuarioEn: asignacion?.guardia ? new Date() : null,
        notificacionesGuardia: asignacion?.guardia ? 1 : 0
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

export const notificarGuardiaSolicitud = async (datos: DatosNotificarGuardia) => {
  return prisma.$transaction(async (db) => {
    const solicitud = await db.solicitudGuardia.findUnique({
      where: { id: datos.solicitudId },
      include: includeSolicitudCompleta
    });

    if (!solicitud) {
      throw new ErrorHttp(404, 'Solicitud no encontrada');
    }

    const solicitudActualizada = await reiterarSolicitudAbierta(
      solicitud,
      datos.usuarioId,
      datos.rol,
      datos.mensaje,
      db
    );

    await crearNotificacion(
      {
        usuarioId: solicitud.solicitadaPorUsuario.id,
        titulo: solicitudActualizada.guardiaAsignado
          ? 'Recordatorio enviado'
          : 'Central notificada nuevamente',
        mensaje: solicitudActualizada.guardiaAsignado
          ? `${solicitudActualizada.guardiaAsignado.nombre} recibio un nuevo aviso para ${solicitud.bicicletero.nombre}.`
          : `Central recibio nuevamente tu solicitud para ${solicitud.bicicletero.nombre}.`,
        tipo: TipoNotificacion.SOLICITUD_GUARDIA,
        datos: { solicitudId: solicitud.id }
      },
      db
    );

    return mapearSolicitudGuardia(solicitudActualizada);
  });
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

    const guardiaResponde = rol === RolUsuario.GUARDIA && estado === EstadoSolicitudGuardia.EN_CAMINO;
    const ahora = new Date();

    const solicitudActualizada = await db.solicitudGuardia.update({
      where: { id: solicitud.id },
      data: {
        estado,
        notificadaGuardiaEn:
          estado === EstadoSolicitudGuardia.NOTIFICADA ? ahora : solicitud.notificadaGuardiaEn,
        notificacionesGuardia:
          estado === EstadoSolicitudGuardia.NOTIFICADA
            ? {
                increment: 1
              }
            : undefined,
        respondidaPorGuardiaEn:
          guardiaResponde && !solicitud.respondidaPorGuardiaEn
            ? ahora
            : solicitud.respondidaPorGuardiaEn,
        enCaminoEn:
          estado === EstadoSolicitudGuardia.EN_CAMINO
            ? (solicitud.enCaminoEn ?? ahora)
            : solicitud.enCaminoEn,
        resueltaEn:
          estado === EstadoSolicitudGuardia.RESUELTA || estado === EstadoSolicitudGuardia.CANCELADA
            ? ahora
            : null
      },
      include: includeSolicitudCompleta
    });

    await crearNotificacion(
      {
        usuarioId: solicitud.solicitadaPorUsuario.id,
        titulo:
          estado === EstadoSolicitudGuardia.EN_CAMINO
            ? 'Guardia en camino'
            : estado === EstadoSolicitudGuardia.RESUELTA
              ? 'Solicitud resuelta'
              : 'Solicitud actualizada',
        mensaje: `${solicitud.bicicletero.nombre}: ${etiquetaEstadoSolicitud(estado)}.`,
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

    if (guardiaResponde) {
      await notificarUsuariosPorRol(
        {
          roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
          titulo: 'Guardia en camino',
          mensaje: `${solicitud.guardiaAsignado!.nombre} va en camino a ${solicitud.bicicletero.nombre}.`,
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
