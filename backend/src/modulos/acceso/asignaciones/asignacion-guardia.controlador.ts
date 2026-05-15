import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../../comun/middlewares/autenticacion.middleware';
import {
  obtenerAsignacionActivaGuardia,
  seleccionarBicicleteroGuardia
} from './asignacion-guardia.servicio';

export const obtenerMiBicicletero = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const asignacion = await obtenerAsignacionActivaGuardia(req.usuario!.usuarioId);
    return res.status(200).json({
      asignacion,
      bicicletero: asignacion?.bicicletero ?? null
    });
  } catch (error) {
    return next(error);
  }
};

export const seleccionarMiBicicletero = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const asignacion = await seleccionarBicicleteroGuardia(
      req.usuario!.usuarioId,
      req.body.bicicleteroId
    );

    return res.status(200).json({
      asignacion,
      bicicletero: asignacion.bicicletero
    });
  } catch (error) {
    return next(error);
  }
};
