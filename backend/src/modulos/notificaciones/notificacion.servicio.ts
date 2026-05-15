import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma, type ClientePrisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { RolUsuario } from '../usuarios/rol-usuario';
import { TipoNotificacion } from './tipo-notificacion';

type DatosCrearNotificacion = {
  usuarioId: string;
  titulo: string;
  mensaje: string;
  tipo?: TipoNotificacion;
  datos?: Record<string, unknown>;
};

type DatosNotificarRoles = {
  roles: RolUsuario[];
  titulo: string;
  mensaje: string;
  tipo?: TipoNotificacion;
  datos?: Record<string, unknown>;
};

export const crearNotificacion = async (
  datos: DatosCrearNotificacion,
  db: ClientePrisma = prisma
) => {
  return db.notificacion.create({
    data: {
      usuarioId: datos.usuarioId,
      titulo: datos.titulo,
      mensaje: datos.mensaje,
      tipo: datos.tipo ?? TipoNotificacion.SISTEMA,
      datos: datos.datos as Prisma.InputJsonValue | undefined
    }
  });
};

export const notificarUsuariosPorRol = async (
  datos: DatosNotificarRoles,
  db: ClientePrisma = prisma
) => {
  const usuarios = await db.usuario.findMany({
    where: {
      rol: {
        in: datos.roles
      }
    },
    select: {
      id: true
    }
  });

  await Promise.all(
    usuarios.map((usuario) =>
      crearNotificacion(
        {
          usuarioId: usuario.id,
          titulo: datos.titulo,
          mensaje: datos.mensaje,
          tipo: datos.tipo,
          datos: datos.datos
        },
        db
      )
    )
  );
};

export const listarNotificacionesUsuario = async (usuarioId: string) => {
  return prisma.notificacion.findMany({
    where: {
      usuarioId
    },
    orderBy: {
      creadaEn: 'desc'
    },
    take: 50
  });
};

export const marcarNotificacionLeida = async (usuarioId: string, notificacionId: string) => {
  const notificacion = await prisma.notificacion.findFirst({
    where: {
      id: notificacionId,
      usuarioId
    }
  });

  if (!notificacion) {
    throw new ErrorHttp(404, 'Notificacion no encontrada');
  }

  return prisma.notificacion.update({
    where: {
      id: notificacion.id
    },
    data: {
      leida: true
    }
  });
};

export const marcarTodasLeidas = async (usuarioId: string) => {
  await prisma.notificacion.updateMany({
    where: {
      usuarioId,
      leida: false
    },
    data: {
      leida: true
    }
  });

  return {
    message: 'Notificaciones marcadas como leidas'
  };
};
