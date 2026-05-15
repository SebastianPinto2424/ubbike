import { NextFunction, Response } from 'express';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import {
  activarBicicleta,
  actualizarBicicleta,
  crearBicicleta,
  desactivarBicicleta,
  eliminarBicicleta,
  listarBicicletasUsuario,
  obtenerBicicletaActivaUsuario
} from './bicicleta.servicio';

export const listar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const bicicletas = await listarBicicletasUsuario(req.usuario!.usuarioId);
    return res.status(200).json({ bicicletas });
  } catch (error) {
    return next(error);
  }
};

export const obtenerActiva = async (
  req: SolicitudAutenticada,
  res: Response,
  next: NextFunction
) => {
  try {
    const bicicleta = await obtenerBicicletaActivaUsuario(req.usuario!.usuarioId);
    return res.status(200).json({ bicicleta });
  } catch (error) {
    return next(error);
  }
};

export const crear = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const bicicleta = await crearBicicleta({
      usuarioId: req.usuario!.usuarioId,
      descripcion: req.body.descripcion,
      marca: req.body.marca,
      modelo: req.body.modelo,
      color: req.body.color,
      aro: req.body.aro,
      numeroSerie: req.body.numeroSerie,
      fotoUrl: req.body.fotoUrl,
      activar: req.body.activar
    });

    return res.status(201).json({ bicicleta });
  } catch (error) {
    return next(error);
  }
};

export const actualizar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const bicicleta = await actualizarBicicleta(req.usuario!.usuarioId, req.params.id, req.body);
    return res.status(200).json({ bicicleta });
  } catch (error) {
    return next(error);
  }
};

export const eliminar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const resultado = await eliminarBicicleta(req.usuario!.usuarioId, req.params.id);
    return res.status(200).json(resultado);
  } catch (error) {
    return next(error);
  }
};

export const activar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const bicicleta = await activarBicicleta(req.usuario!.usuarioId, req.params.id);
    return res.status(200).json({ bicicleta });
  } catch (error) {
    return next(error);
  }
};

export const desactivar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const bicicleta = await desactivarBicicleta(req.usuario!.usuarioId, req.params.id);
    return res.status(200).json({ bicicleta });
  } catch (error) {
    return next(error);
  }
};
