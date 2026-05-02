import { NextFunction, Request, Response } from 'express';
import { actualizarPermisosUsuario, listarUsuarios } from './usuario.servicio';

export const listar = async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const usuarios = await listarUsuarios();
    return res.status(200).json({ usuarios });
  } catch (error) {
    return next(error);
  }
};

export const actualizarPermisos = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const usuario = await actualizarPermisosUsuario(
      req.params.id,
      req.body,
      req.usuario?.usuarioId
    );
    return res.status(200).json({ usuario });
  } catch (error) {
    return next(error);
  }
};
