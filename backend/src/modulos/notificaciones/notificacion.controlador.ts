import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import {
  listarNotificacionesUsuario,
  marcarNotificacionLeida,
  marcarTodasLeidas
} from './notificacion.servicio';

export const listarNotificaciones = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const notificaciones = await listarNotificacionesUsuario(req.usuario!.usuarioId);
    return res.status(200).json({ notificaciones });
  } catch (error) {
    return next(error);
  }
};

export const marcarLeida = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const notificacion = await marcarNotificacionLeida(req.usuario!.usuarioId, req.params.id);
    return res.status(200).json({ notificacion });
  } catch (error) {
    return next(error);
  }
};

export const marcarTodas = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const resultado = await marcarTodasLeidas(req.usuario!.usuarioId);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};
