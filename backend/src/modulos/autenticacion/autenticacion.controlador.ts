import { NextFunction, Request, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import {
  cambiarContrasena as cambiarContrasenaServicio,
  iniciarSesion as iniciarSesionServicio,
  obtenerUsuarioActual,
  registrarUsuario,
  solicitarCambioContrasena as solicitarCambioContrasenaServicio,
  verificarCorreo as verificarCorreoServicio
} from './autenticacion.servicio';

export const registrar = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const resultado = await registrarUsuario(req.body);
    return res.status(201).json(resultado);
  } catch (error) {
    return next(error);
  }
};

export const iniciarSesion = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const resultado = await iniciarSesionServicio(req.body);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};

export const obtenerPerfil = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const usuario = await obtenerUsuarioActual(req.usuario!.usuarioId);
    return res.status(200).json({ usuario });
  } catch (error) {
    return next(error);
  }
};

export const verificarCorreo = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token = String(req.query.token ?? '');
    const resultado = await verificarCorreoServicio(token);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};

export const solicitarCambioContrasena = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const resultado = await solicitarCambioContrasenaServicio(req.body.correo);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};

export const cambiarContrasena = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const resultado = await cambiarContrasenaServicio(req.body.token, req.body.contrasena);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};
