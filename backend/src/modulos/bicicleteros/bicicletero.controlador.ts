import { NextFunction, Request, Response } from 'express';
import { listarBicicleteros } from './bicicletero.servicio';

export const listar = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const bicicleteros = await listarBicicleteros();
    return res.status(200).json({ bicicleteros });
  } catch (error) {
    return next(error);
  }
};
