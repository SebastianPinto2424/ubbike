import { NextFunction, Response } from 'express';
import { parse } from 'json2csv';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { listarMovimientos, resumenHistorial } from './historial.servicio';

export const listar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const limite = req.query.limit ? parseInt(req.query.limit as string) : 100;
    const pagina = req.query.page ? parseInt(req.query.page as string) : 1;

    const resultado = await listarMovimientos({
      usuarioId: req.usuario!.usuarioId,
      rol: req.usuario!.rol,
      q: req.query.q?.toString(),
      periodo: req.query.periodo as 'DIA' | 'SEMANA' | 'MES' | 'ANIO' | undefined,
      tipo: req.query.tipo as 'INGRESO' | 'SALIDA' | 'TODOS' | undefined,
      estado: req.query.estado as 'CONFIRMADO' | 'DENEGADO' | 'TODOS' | undefined,
      bicicleteroId: req.query.bicicleteroId?.toString(),
      limite,
      pagina
    });

    return res.status(200).json(resultado);
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

export const exportar = async (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
  try {
    const resultado = await listarMovimientos({
      usuarioId: req.usuario!.usuarioId,
      rol: req.usuario!.rol,
      q: req.query.q?.toString(),
      periodo: req.query.periodo as 'DIA' | 'SEMANA' | 'MES' | 'ANIO' | undefined,
      tipo: req.query.tipo as 'INGRESO' | 'SALIDA' | 'TODOS' | undefined,
      estado: req.query.estado as 'CONFIRMADO' | 'DENEGADO' | 'TODOS' | undefined,
      bicicleteroId: req.query.bicicleteroId?.toString(),
      limite: 100000,
      pagina: 1
    });

    const csvData = resultado.datos.map((m) => ({
      ID: m.id,
      Tipo: m.tipo,
      Estado: m.estado,
      'Usuario Nombre': m.usuario.nombre,
      'Usuario Correo': m.usuario.correo,
      Bicicleta: m.bicicleta.descripcion,
      Bicicletero: m.bicicletero?.nombre || '-',
      'Guardia Validador': m.guardia?.nombre || '-',
      'Fecha Creación': m.creadoEn.toISOString()
    }));

    const csv = parse(csvData);
    res.header('Content-Type', 'text/csv');
    res.attachment('historial-movimientos-ubbike.csv');
    return res.send(csv);
  } catch (error) {
    return next(error);
  }
};
