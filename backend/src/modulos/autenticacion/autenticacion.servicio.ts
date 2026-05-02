import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { ErrorHttp } from '../../comun/errors/error-http';
import { entorno } from '../../configuracion/entorno';
import {
  crearCorreoCambioContrasena,
  crearCorreoVerificacion,
  enviarCorreo
} from '../correos/correo.servicio';
import { crearNotificacion, notificarUsuariosPorRol } from '../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../notificaciones/tipo-notificacion';
import { mapearUsuarioPublico } from '../usuarios/usuario.mapeador';
import { obtenerRepositorioUsuarios } from '../usuarios/usuario.repositorio';
import { RolUsuario } from '../usuarios/rol-usuario';

type DatosRegistro = {
  nombre: string;
  rut?: string;
  correo: string;
  contrasena: string;
  rol: RolUsuario;
};

type DatosLogin = {
  correo: string;
  contrasena: string;
};

const crearTokenSeguro = (): string => crypto.randomBytes(32).toString('hex');

const crearToken = (usuarioId: string, rol: RolUsuario): string => {
  const opcionesFirma: SignOptions = {
    expiresIn: entorno.jwt.expiracion as SignOptions['expiresIn']
  };

  return jwt.sign({ usuarioId, rol }, entorno.jwt.secreto, opcionesFirma);
};

export const registrarUsuario = async (datos: DatosRegistro) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const correoNormalizado = datos.correo.toLowerCase();
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
    rol: datos.rol,
    contrasenaHash,
    cuentaActiva: true,
    correoVerificado: false,
    tokenVerificacionCorreo: tokenVerificacion
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
    throw new ErrorHttp(401, 'Credenciales invalidas');
  }

  if (!usuario.cuentaActiva) {
    throw new ErrorHttp(403, 'La cuenta esta desactivada');
  }

  if (!usuario.correoVerificado) {
    throw new ErrorHttp(403, 'Debes verificar tu correo antes de iniciar sesion');
  }

  const contrasenaCoincide = await bcrypt.compare(datos.contrasena, usuario.contrasenaHash);

  if (!contrasenaCoincide) {
    throw new ErrorHttp(401, 'Credenciales invalidas');
  }

  return {
    usuario: mapearUsuarioPublico(usuario),
    token: crearToken(usuario.id, usuario.rol)
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
    tokenVerificacionCorreo: token
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

  usuario.tokenCambioContrasena = crearTokenSeguro();
  usuario.tokenCambioContrasenaExpiraEn = new Date(Date.now() + 1000 * 60 * 30);
  await repositorioUsuarios.save(usuario);

  const enlace = `${entorno.app.urlFrontend}/#/cambiar-contrasena?token=${usuario.tokenCambioContrasena}`;
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

  return {
    message: 'Si el correo existe, enviaremos instrucciones de recuperacion.'
  };
};

export const cambiarContrasena = async (token: string, contrasena: string) => {
  const repositorioUsuarios = obtenerRepositorioUsuarios();
  const usuario = await repositorioUsuarios.findOneBy({
    tokenCambioContrasena: token
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
  await repositorioUsuarios.save(usuario);

  await crearNotificacion({
    usuarioId: usuario.id,
    titulo: 'Contrasena actualizada',
    mensaje: 'Tu contrasena fue cambiada correctamente.',
    tipo: TipoNotificacion.CUENTA
  });

  return {
    message: 'Contrasena actualizada correctamente'
  };
};
