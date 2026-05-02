import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import { crearNotificacion } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { mapearUsuarioPublico } from './usuario.mapeador';
import { RolUsuario } from './rol-usuario';
import { Usuario } from './usuario.entidad';

type DatosActualizarPermisos = {
  nombre?: string;
  correo?: string;
  rut?: string | null;
  rol?: RolUsuario;
  cuentaActiva?: boolean;
  correoVerificado?: boolean;
};

const repositorioUsuarios = () => fuenteDatos.getRepository(Usuario);

export const listarUsuarios = async () => {
  const usuarios = await repositorioUsuarios().find({
    order: {
      creadoEn: 'DESC'
    }
  });

  return usuarios.map(mapearUsuarioPublico);
};

export const actualizarPermisosUsuario = async (
  usuarioId: string,
  datos: DatosActualizarPermisos,
  actorUsuarioId?: string
) => {
  const repositorio = repositorioUsuarios();
  const usuario = await repositorio.findOneBy({ id: usuarioId });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  let invalidarSesiones = false;

  if (datos.rol !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.rol !== datos.rol;
    usuario.rol = datos.rol;
  }

  if (datos.nombre !== undefined) {
    usuario.nombre = datos.nombre;
  }

  if (datos.correo !== undefined) {
    const correoNormalizado = datos.correo.toLowerCase();
    invalidarSesiones = invalidarSesiones || usuario.correo !== correoNormalizado;
    usuario.correo = correoNormalizado;
  }

  if (datos.rut !== undefined) {
    usuario.rut = datos.rut || null;
  }

  if (datos.cuentaActiva !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.cuentaActiva !== datos.cuentaActiva;
    usuario.cuentaActiva = datos.cuentaActiva;
  }

  if (datos.correoVerificado !== undefined) {
    invalidarSesiones = invalidarSesiones || usuario.correoVerificado !== datos.correoVerificado;
    usuario.correoVerificado = datos.correoVerificado;
    if (datos.correoVerificado) {
      usuario.tokenVerificacionCorreo = null;
    }
  }

  if (invalidarSesiones) {
    usuario.versionSesion += 1;
  }

  const usuarioGuardado = await repositorio.save(usuario);

  await crearNotificacion({
    usuarioId: usuarioGuardado.id,
    titulo: 'Permisos actualizados',
    mensaje: `Tu cuenta fue actualizada por administracion. Rol actual: ${usuarioGuardado.rol}.`,
    tipo: TipoNotificacion.CUENTA,
    datos: {
      rol: usuarioGuardado.rol,
      cuentaActiva: usuarioGuardado.cuentaActiva,
      correoVerificado: usuarioGuardado.correoVerificado
    }
  });

  await registrarAuditoria({
    actorUsuarioId: actorUsuarioId ?? null,
    accion: 'USUARIO_ACTUALIZADO_ADMIN',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: {
      campos: Object.keys(datos),
      rol: usuarioGuardado.rol,
      cuentaActiva: usuarioGuardado.cuentaActiva,
      correoVerificado: usuarioGuardado.correoVerificado,
      sesionesInvalidadas: invalidarSesiones
    }
  });

  return mapearUsuarioPublico(usuarioGuardado);
};
