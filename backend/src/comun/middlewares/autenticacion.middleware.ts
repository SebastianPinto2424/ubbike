import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { entorno } from '../../configuracion/entorno';

export type CargaToken = {
  usuarioId: string;
  rol: string;
};

export type SolicitudAutenticada = Request & {
  usuario?: CargaToken;
};

export const middlewareAutenticacion = (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  const autorizacion = req.headers.authorization;

  if (!autorizacion?.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Token de autenticacion requerido'
    });
  }

  const token = autorizacion.replace('Bearer ', '');

  try {
    req.usuario = jwt.verify(token, entorno.jwt.secreto) as CargaToken;
    return next();
  } catch (_error) {
    return res.status(401).json({
      message: 'Token de autenticacion invalido o expirado'
    });
  }
};
