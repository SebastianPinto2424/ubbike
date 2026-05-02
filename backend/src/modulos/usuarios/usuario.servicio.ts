import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
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
  datos: DatosActualizarPermisos
) => {
  const repositorio = repositorioUsuarios();
  const usuario = await repositorio.findOneBy({ id: usuarioId });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  if (datos.rol !== undefined) {
    usuario.rol = datos.rol;
  }

  if (datos.nombre !== undefined) {
    usuario.nombre = datos.nombre;
  }

  if (datos.correo !== undefined) {
    usuario.correo = datos.correo.toLowerCase();
  }

  if (datos.rut !== undefined) {
    usuario.rut = datos.rut || null;
  }

  if (datos.cuentaActiva !== undefined) {
    usuario.cuentaActiva = datos.cuentaActiva;
  }

  if (datos.correoVerificado !== undefined) {
    usuario.correoVerificado = datos.correoVerificado;
    if (datos.correoVerificado) {
      usuario.tokenVerificacionCorreo = null;
    }
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

  return mapearUsuarioPublico(usuarioGuardado);
};
