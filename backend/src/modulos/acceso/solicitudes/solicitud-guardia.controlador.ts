import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../../comun/middlewares/autenticacion.middleware';
import {
  actualizarEstadoSolicitudGuardia,
  crearSolicitudGuardia,
  listarSolicitudesGuardia
} from './solicitud-guardia.servicio';

export const crear = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const solicitud = await crearSolicitudGuardia({
      usuarioId: req.usuario!.usuarioId,
      bicicleteroId: req.body.bicicleteroId,
      tipo: req.body.tipo,
      mensaje: req.body.mensaje
    });

    return res.status(201).json({ solicitud });
  } catch (error) {
    return next(error);
  }
};

export const listar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const solicitudes = await listarSolicitudesGuardia({
      usuarioId: req.usuario!.usuarioId,
      rol: req.usuario!.rol
    });

    return res.status(200).json({ solicitudes });
  } catch (error) {
    return next(error);
  }
};

export const actualizarEstado = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const solicitud = await actualizarEstadoSolicitudGuardia(
      req.usuario!.usuarioId,
      req.usuario!.rol,
      req.params.id,
      req.body.estado
    );

    return res.status(200).json({ solicitud });
  } catch (error) {
    return next(error);
  }
};
