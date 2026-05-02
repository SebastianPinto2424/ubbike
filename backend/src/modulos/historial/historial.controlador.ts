import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { listarMovimientos, resumenHistorial } from './historial.servicio';

export const listar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const movimientos = await listarMovimientos({
      usuarioId: req.usuario!.usuarioId,
      rol: req.usuario!.rol,
      q: req.query.q?.toString(),
      periodo: req.query.periodo as 'DIA' | 'SEMANA' | 'MES' | undefined
    });

    return res.status(200).json({ movimientos });
  } catch (error) {
    return next(error);
  }
};

export const resumen = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const datos = await resumenHistorial(req.usuario!.usuarioId, req.usuario!.rol);
    return res.status(200).json({ resumen: datos });
  } catch (error) {
    return next(error);
  }
};
