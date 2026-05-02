import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { confirmarQr, denegarQr, registrarGestionManual } from './acceso.servicio';

export const confirmarAccesoQr = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const movimiento = await confirmarQr({
      token: req.body.token,
      bicicleteroId: req.body.bicicleteroId,
      guardiaId: req.usuario!.usuarioId,
      rol: req.usuario!.rol
    });

    return res.status(201).json({ movimiento });
  } catch (error) {
    return next(error);
  }
};

export const denegarAccesoQr = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const movimiento = await denegarQr({
      token: req.body.token,
      motivo: req.body.motivo,
      bicicleteroId: req.body.bicicleteroId,
      guardiaId: req.usuario!.usuarioId,
      rol: req.usuario!.rol
    });

    return res.status(201).json({ movimiento });
  } catch (error) {
    return next(error);
  }
};

export const registrarManual = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const movimiento = await registrarGestionManual({
      guardiaId: req.usuario!.usuarioId,
      rol: req.usuario!.rol,
      correo: req.body.correo,
      rut: req.body.rut,
      bicicletaId: req.body.bicicletaId,
      bicicleteroId: req.body.bicicleteroId,
      tipo: req.body.tipo,
      denegar: req.body.denegar,
      motivo: req.body.motivo
    });

    return res.status(201).json({ movimiento });
  } catch (error) {
    return next(error);
  }
};
