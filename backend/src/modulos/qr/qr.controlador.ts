import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { generarQrTemporal, validarQrTemporal } from './qr.servicio';

export const generar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const qr = await generarQrTemporal({
      usuarioId: req.usuario!.usuarioId,
      bicicletaId: req.body.bicicletaId,
      bicicleteroId: req.body.bicicleteroId,
      tipo: req.body.tipo
    });

    return res.status(201).json({ qr });
  } catch (error) {
    return next(error);
  }
};

export const validar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const qr = await validarQrTemporal(req.body.token);
    return res.status(200).json({ qr });
  } catch (error) {
    return next(error);
  }
};
