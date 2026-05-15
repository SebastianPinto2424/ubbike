import bcrypt from 'bcryptjs';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import { prisma } from '../../configuracion/prisma';
import { registrarAuditoria } from '../auditoria/auditoria.servicio';
import {
  crearCorreoCambioContrasena,
  crearCorreoVerificacion,
  enviarCorreo
} from '../correos/correo.servicio';
import {
  crearNotificacion,
  notificarUsuariosPorRol
} from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { mapearUsuarioPublico } from '../usuarios/usuario.mapeador';
import { RolUsuario } from '../usuarios/rol-usuario';
import {
  crearTokenSeguro,
  crearTokenSesion,
  hashearToken,
  horasExpiracionVerificacionCorreo,
  resolverRolRegistrable
} from './autenticacion.tokens';

type DatosRegistro = {
  nombre: string;
  rut?: string;
  correo: string;
  contrasena: string;
};

type DatosLogin = {
  correo: string;
  contrasena: string;
};

export const registrarUsuario = async (datos: DatosRegistro) => {
  const correoNormalizado = datos.correo.toLowerCase();
  const rolAsignado = resolverRolRegistrable(correoNormalizado);
  const usuarioExistente = await prisma.usuario.findUnique({
    where: {
      correo: correoNormalizado
    }
  });

  if (usuarioExistente) {
    throw new ErrorHttp(409, 'El correo ya esta registrado');
  }

  if (datos.rut) {
    const rutExistente = await prisma.usuario.findUnique({
      where: {
        rut: datos.rut
      }
    });

    if (rutExistente) {
      throw new ErrorHttp(409, 'El RUT ya esta registrado');
    }
  }

  const contrasenaHash = await bcrypt.hash(datos.contrasena, 12);
  const tokenVerificacion = crearTokenSeguro();
  const usuarioGuardado = await prisma.usuario.create({
    data: {
      nombre: datos.nombre,
      correo: correoNormalizado,
      rut: datos.rut ?? null,
      rol: rolAsignado,
      contrasenaHash,
      cuentaActiva: true,
      correoVerificado: false,
      tokenVerificacionCorreo: hashearToken(tokenVerificacion),
      tokenVerificacionCorreoExpiraEn: new Date(
        Date.now() + 1000 * 60 * 60 * horasExpiracionVerificacionCorreo
      )
    }
  });
  const enlace = `${entorno.app.urlFrontend}/#/verificar-correo?token=${tokenVerificacion}`;
  const correo = crearCorreoVerificacion(usuarioGuardado.nombre, enlace);

  await enviarCorreo({
    para: usuarioGuardado.correo,
    asunto: correo.asunto,
    texto: correo.texto,
    html: correo.html
  });

  await notificarUsuariosPorRol({
    roles: [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR],
    titulo: 'Nueva solicitud de registro',
    mensaje: `${usuarioGuardado.nombre} solicito una cuenta ${usuarioGuardado.rol}.`,
    tipo: TipoNotificacion.CUENTA,
    datos: { usuarioId: usuarioGuardado.id, rol: usuarioGuardado.rol }
  });

  await registrarAuditoria({
    actorUsuarioId: usuarioGuardado.id,
    accion: 'CUENTA_REGISTRADA',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id,
    datos: {
      correo: usuarioGuardado.correo,
      rol: usuarioGuardado.rol
    }
  });

  return {
    message: 'Registro recibido. Revisa tu correo para activar la cuenta.',
    usuario: mapearUsuarioPublico(usuarioGuardado)
  };
};

export const iniciarSesion = async (datos: DatosLogin) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      correo: datos.correo.toLowerCase()
    }
  });

  if (!usuario) {
    await registrarAuditoria({
      accion: 'LOGIN_FALLIDO',
      entidad: 'usuarios',
      datos: {
        correo: datos.correo.toLowerCase(),
        motivo: 'usuario_no_encontrado'
      }
    });
    throw new ErrorHttp(401, 'Credenciales invalidas');
  }

  if (!usuario.cuentaActiva) {
    await registrarAuditoria({
      actorUsuarioId: usuario.id,
      accion: 'LOGIN_BLOQUEADO',
      entidad: 'usuarios',
      entidadId: usuario.id,
      datos: { motivo: 'cuenta_desactivada' }
    });
    throw new ErrorHttp(403, 'La cuenta esta desactivada');
  }

  if (!usuario.correoVerificado) {
    await registrarAuditoria({
      actorUsuarioId: usuario.id,
      accion: 'LOGIN_BLOQUEADO',
      entidad: 'usuarios',
      entidadId: usuario.id,
      datos: { motivo: 'correo_no_verificado' }
    });
    throw new ErrorHttp(403, 'Debes verificar tu correo antes de iniciar sesion');
  }

  const contrasenaCoincide = await bcrypt.compare(datos.contrasena, usuario.contrasenaHash);

  if (!contrasenaCoincide) {
    await registrarAuditoria({
      actorUsuarioId: usuario.id,
      accion: 'LOGIN_FALLIDO',
      entidad: 'usuarios',
      entidadId: usuario.id,
      datos: { motivo: 'contrasena_incorrecta' }
    });
    throw new ErrorHttp(401, 'Credenciales invalidas');
  }

  await registrarAuditoria({
    actorUsuarioId: usuario.id,
    accion: 'LOGIN_EXITOSO',
    entidad: 'usuarios',
    entidadId: usuario.id
  });

  return {
    usuario: mapearUsuarioPublico(usuario),
    token: crearTokenSesion(usuario.id, usuario.rol, usuario.versionSesion)
  };
};

export const obtenerUsuarioActual = async (usuarioId: string) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      id: usuarioId
    }
  });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  return mapearUsuarioPublico(usuario);
};

export const verificarCorreo = async (token: string) => {
  const usuario = await prisma.usuario.findFirst({
    where: {
      tokenVerificacionCorreo: hashearToken(token)
    }
  });

  if (!usuario) {
    throw new ErrorHttp(400, 'Token de verificacion invalido');
  }

  if (
    !usuario.tokenVerificacionCorreoExpiraEn ||
    usuario.tokenVerificacionCorreoExpiraEn.getTime() < Date.now()
  ) {
    await prisma.usuario.update({
      where: {
        id: usuario.id
      },
      data: {
        tokenVerificacionCorreo: null,
        tokenVerificacionCorreoExpiraEn: null
      }
    });
    throw new ErrorHttp(400, 'Token de verificacion expirado. Solicita un nuevo registro.');
  }

  const usuarioGuardado = await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      correoVerificado: true,
      tokenVerificacionCorreo: null,
      tokenVerificacionCorreoExpiraEn: null
    }
  });

  await crearNotificacion({
    usuarioId: usuarioGuardado.id,
    titulo: 'Cuenta verificada',
    mensaje: 'Tu cuenta UBBike fue activada correctamente.',
    tipo: TipoNotificacion.CUENTA
  });

  await registrarAuditoria({
    actorUsuarioId: usuarioGuardado.id,
    accion: 'CORREO_VERIFICADO',
    entidad: 'usuarios',
    entidadId: usuarioGuardado.id
  });

  return {
    message: 'Correo verificado correctamente',
    usuario: mapearUsuarioPublico(usuarioGuardado)
  };
};

export const solicitarCambioContrasena = async (correo: string) => {
  const usuario = await prisma.usuario.findUnique({
    where: {
      correo: correo.toLowerCase()
    }
  });

  if (!usuario) {
    return {
      message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
    };
  }

  const tokenCambioContrasena = crearTokenSeguro();
  const usuarioActualizado = await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      tokenCambioContrasena: hashearToken(tokenCambioContrasena),
      tokenCambioContrasenaExpiraEn: new Date(Date.now() + 1000 * 60 * 30)
    }
  });

  const enlace = `${entorno.app.urlFrontend}/#/cambiar-contrasena?token=${tokenCambioContrasena}`;
  const correoCambio = crearCorreoCambioContrasena(usuarioActualizado.nombre, enlace);

  await enviarCorreo({
    para: usuarioActualizado.correo,
    asunto: correoCambio.asunto,
    texto: correoCambio.texto,
    html: correoCambio.html
  });

  await crearNotificacion({
    usuarioId: usuarioActualizado.id,
    titulo: 'Solicitud de cambio de contrasena',
    mensaje: 'Se envio un enlace seguro a tu correo institucional.',
    tipo: TipoNotificacion.CUENTA
  });

  await registrarAuditoria({
    actorUsuarioId: usuarioActualizado.id,
    accion: 'CAMBIO_CONTRASENA_SOLICITADO',
    entidad: 'usuarios',
    entidadId: usuarioActualizado.id
  });

  return {
    message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
  };
};

export const cambiarContrasena = async (token: string, contrasena: string) => {
  const usuario = await prisma.usuario.findFirst({
    where: {
      tokenCambioContrasena: hashearToken(token)
    }
  });

  if (!usuario || !usuario.tokenCambioContrasenaExpiraEn) {
    throw new ErrorHttp(400, 'Token de cambio de contrasena invalido');
  }

  if (usuario.tokenCambioContrasenaExpiraEn.getTime() < Date.now()) {
    throw new ErrorHttp(400, 'Token de cambio de contrasena expirado');
  }

  await prisma.usuario.update({
    where: {
      id: usuario.id
    },
    data: {
      contrasenaHash: await bcrypt.hash(contrasena, 12),
      tokenCambioContrasena: null,
      tokenCambioContrasenaExpiraEn: null,
      versionSesion: {
        increment: 1
      }
    }
  });

  await crearNotificacion({
    usuarioId: usuario.id,
    titulo: 'Contrasena actualizada',
    mensaje: 'Tu contrasena fue cambiada correctamente.',
    tipo: TipoNotificacion.CUENTA
  });

  await registrarAuditoria({
    actorUsuarioId: usuario.id,
    accion: 'CONTRASENA_CAMBIADA',
    entidad: 'usuarios',
    entidadId: usuario.id
  });

  return {
    message: 'Contrasena actualizada correctamente'
  };
};
