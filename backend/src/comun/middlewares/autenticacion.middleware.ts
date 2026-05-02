import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { entorno } from '../../configuracion/entorno';
import { obtenerRepositorioUsuarios } from '../../modulos/usuarios/usuario.repositorio';

export type CargaToken = {
  usuarioId: string;
  rol: string;
  versionSesion: number;
};

declare module 'express-serve-static-core' {
  interface Request {
    usuario?: CargaToken;
  }
}

export type SolicitudAutenticada = Request & {
  usuario?: CargaToken;
};

export const middlewareAutenticacion = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
): Promise<Response | void> => {
  const autorizacion = req.headers.authorization;

  if (!autorizacion?.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Token de autenticacion requerido'
    });
  }

  const token = autorizacion.replace('Bearer ', '');

  try {
    const carga = jwt.verify(token, entorno.jwt.secreto, {
      algorithms: ['HS256'],
      audience: entorno.jwt.audiencia,
      issuer: entorno.jwt.emisor
    }) as CargaToken;

    const usuario = await obtenerRepositorioUsuarios().findOneBy({
      id: carga.usuarioId
    });

    if (!usuario || !usuario.cuentaActiva || !usuario.correoVerificado) {
      return res.status(401).json({
        message: 'Token de autenticacion invalido o expirado'
      });
    }

    if (usuario.versionSesion !== carga.versionSesion) {
      return res.status(401).json({
        message: 'La sesion fue invalidada. Inicia sesion nuevamente.'
      });
    }

    req.usuario = {
      usuarioId: usuario.id,
      rol: usuario.rol,
      versionSesion: usuario.versionSesion
    };
    return next();
  } catch {
    return res.status(401).json({
      message: 'Token de autenticacion invalido o expirado'
    });
  }
};
