import { parse } from 'json2csv';
import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../comun/utils/controlador-async';
import { listarMovimientos, resumenHistorial } from './historial.servicio';

const crearFiltrosHistorial = (req: SolicitudAutenticada, limite: number, pagina: number) => ({
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

export const listar = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const limite = req.query.limit ? parseInt(req.query.limit as string) : 100;
  const pagina = req.query.page ? parseInt(req.query.page as string) : 1;
  const resultado = await listarMovimientos(crearFiltrosHistorial(req, limite, pagina));

  return res.status(200).json(resultado);
});

export const resumen = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const datos = await resumenHistorial(req.usuario!.usuarioId, req.usuario!.rol);
  return res.status(200).json({ resumen: datos });
});

export const exportar = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const resultado = await listarMovimientos(crearFiltrosHistorial(req, 100000, 1));

  const csvData = resultado.datos.map((movimiento) => ({
    ID: movimiento.id,
    Tipo: movimiento.tipo,
    Estado: movimiento.estado,
    'Usuario Nombre': movimiento.usuario.nombre,
    'Usuario Correo': movimiento.usuario.correo,
    Bicicleta: movimiento.bicicleta.descripcion,
    Bicicletero: movimiento.bicicletero?.nombre || '-',
    'Guardia Validador': movimiento.guardia?.nombre || '-',
    'Fecha Creacion': movimiento.creadoEn.toISOString()
  }));

  const csv = parse(csvData);
  res.header('Content-Type', 'text/csv');
  res.attachment('historial-movimientos-ubbike.csv');
  return res.send(csv);
});
