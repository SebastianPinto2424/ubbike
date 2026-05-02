import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
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
import { obtenerRepositorioUsuarios } from '../usuarios/usuario.repositorio';
import { RolUsuario } from '../usuarios/rol-usuario';

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

const crearTokenSeguro = (): string => crypto.randomBytes(32).toString('hex');
const hashearToken = (token: string): string =>
  crypto.createHash('sha256').update(token).digest('hex');

const crearToken = (usuarioId: string, rol: RolUsuario, versionSesion: number): string => {
  const opcionesFirma: SignOptions = {
    expiresIn: entorno.jwt.expiracion as SignOptions['expiresIn'],
    issuer: entorno.jwt.emisor,
    audience: entorno.jwt.audiencia
  };

  return jwt.sign({ usuarioId, rol, versionSesion }, entorno.jwt.secreto, opcionesFirma);
};

const resolverRolRegistrable = (correo: string): RolUsuario => {
  if (correo.endsWith('@alumnos.ubiobio.cl')) {
    return RolUsuario.ESTUDIANTE;
  }

  if (correo.endsWith('@ubiobio.cl')) {
    return RolUsuario.FUNCIONARIO;
  }

  throw new ErrorHttp(400, 'Debes usar un correo institucional UBB valido');
};

export const registrarUsuario = async (datos: DatosRegistro) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const correoNormalizado = datos.correo.toLowerCase();
  const rolAsignado = resolverRolRegistrable(correoNormalizado);
  const usuarioExistente = await repositorioUsuarios.findOneBy({
    correo: correoNormalizado
  });

  if (usuarioExistente) {
    throw new ErrorHttp(409, 'El correo ya esta registrado');
  }

  if (datos.rut) {
    const rutExistente = await repositorioUsuarios.findOneBy({
      rut: datos.rut
    });

    if (rutExistente) {
      throw new ErrorHttp(409, 'El RUT ya esta registrado');
    }
  }

  const contrasenaHash = await bcrypt.hash(datos.contrasena, 12);
  const tokenVerificacion = crearTokenSeguro();
  const usuario = repositorioUsuarios.create({
    nombre: datos.nombre,
    correo: correoNormalizado,
    rut: datos.rut ?? null,
    rol: rolAsignado,
    contrasenaHash,
    cuentaActiva: true,
    correoVerificado: false,
    tokenVerificacionCorreo: hashearToken(tokenVerificacion)
  });

  const usuarioGuardado = await repositorioUsuarios.save(usuario);
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
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({
    correo: datos.correo.toLowerCase()
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
    token: crearToken(usuario.id, usuario.rol, usuario.versionSesion)
  };
};

export const obtenerUsuarioActual = async (usuarioId: string) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({ id: usuarioId });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  return mapearUsuarioPublico(usuario);
};

export const verificarCorreo = async (token: string) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({
    tokenVerificacionCorreo: hashearToken(token)
  });

  if (!usuario) {
    throw new ErrorHttp(400, 'Token de verificacion invalido');
  }

  usuario.correoVerificado = true;
  usuario.tokenVerificacionCorreo = null;
  const usuarioGuardado = await repositorioUsuarios.save(usuario);

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
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({
    correo: correo.toLowerCase()
  });

  if (!usuario) {
    return {
      message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
    };
  }

  const tokenCambioContrasena = crearTokenSeguro();
  usuario.tokenCambioContrasena = hashearToken(tokenCambioContrasena);
  usuario.tokenCambioContrasenaExpiraEn = new Date(Date.now() + 1000 * 60 * 30);
  await repositorioUsuarios.save(usuario);

  const enlace = `${entorno.app.urlFrontend}/#/cambiar-contrasena?token=${tokenCambioContrasena}`;
  const correoCambio = crearCorreoCambioContrasena(usuario.nombre, enlace);

  await enviarCorreo({
    para: usuario.correo,
    asunto: correoCambio.asunto,
    texto: correoCambio.texto,
    html: correoCambio.html
  });

  await crearNotificacion({
    usuarioId: usuario.id,
    titulo: 'Solicitud de cambio de contrasena',
    mensaje: 'Se envio un enlace seguro a tu correo institucional.',
    tipo: TipoNotificacion.CUENTA
  });

  await registrarAuditoria({
    actorUsuarioId: usuario.id,
    accion: 'CAMBIO_CONTRASENA_SOLICITADO',
    entidad: 'usuarios',
    entidadId: usuario.id
  });

  return {
    message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
  };
};

export const cambiarContrasena = async (token: string, contrasena: string) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({
    tokenCambioContrasena: hashearToken(token)
  });

  if (!usuario || !usuario.tokenCambioContrasenaExpiraEn) {
    throw new ErrorHttp(400, 'Token de cambio de contrasena invalido');
  }

  if (usuario.tokenCambioContrasenaExpiraEn.getTime() < Date.now()) {
    throw new ErrorHttp(400, 'Token de cambio de contrasena expirado');
  }

  usuario.contrasenaHash = await bcrypt.hash(contrasena, 12);
  usuario.tokenCambioContrasena = null;
  usuario.tokenCambioContrasenaExpiraEn = null;
  usuario.versionSesion += 1;
  await repositorioUsuarios.save(usuario);

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
