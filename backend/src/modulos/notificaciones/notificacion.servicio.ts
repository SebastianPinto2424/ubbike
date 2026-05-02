import { In } from 'typeorm';
import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Usuario } from '../usuarios/usuario.entidad';
import { RolUsuario } from '../usuarios/rol-usuario';
import { Notificacion } from './notificacion.entidad';
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

const repositorioNotificaciones = () => fuenteDatos.getRepository(Notificacion);
const repositorioUsuarios = () => fuenteDatos.getRepository(Usuario);

export const crearNotificacion = async (datos: DatosCrearNotificacion) => {
  const repositorio = repositorioNotificaciones();
  const notificacion = repositorio.create({
    usuario: { id: datos.usuarioId },
    titulo: datos.titulo,
    mensaje: datos.mensaje,
    tipo: datos.tipo ?? TipoNotificacion.SISTEMA,
    datos: datos.datos ?? null
  });

  return repositorio.save(notificacion);
};

export const notificarUsuariosPorRol = async (datos: DatosNotificarRoles) => {
  const usuarios = await repositorioUsuarios().find({
    where: {
      rol: In(datos.roles)
    },
    select: {
      id: true
    }
  });

  await Promise.all(
    usuarios.map((usuario) =>
      crearNotificacion({
        usuarioId: usuario.id,
        titulo: datos.titulo,
        mensaje: datos.mensaje,
        tipo: datos.tipo,
        datos: datos.datos
      })
    )
  );
};

export const listarNotificacionesUsuario = async (usuarioId: string) => {
  return repositorioNotificaciones().find({
    where: {
      usuario: {
        id: usuarioId
      }
    },
    order: {
      creadaEn: 'DESC'
    },
    take: 50
  });
};

export const marcarNotificacionLeida = async (usuarioId: string, notificacionId: string) => {
  const repositorio = repositorioNotificaciones();
  const notificacion = await repositorio.findOne({
    where: {
      id: notificacionId,
      usuario: {
        id: usuarioId
      }
    }
  });

  if (!notificacion) {
    throw new ErrorHttp(404, 'Notificacion no encontrada');
  }

  notificacion.leida = true;
  return repositorio.save(notificacion);
};

export const marcarTodasLeidas = async (usuarioId: string) => {
  await repositorioNotificaciones().update(
    {
      usuario: {
        id: usuarioId
      },
      leida: false
    },
    {
      leida: true
    }
  );

  return {
    message: 'Notificaciones marcadas como leidas'
  };
};
