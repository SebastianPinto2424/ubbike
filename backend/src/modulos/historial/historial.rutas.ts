import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { listar, resumen, exportar } from './historial.controlador';

const rutasHistorial = Router();

rutasHistorial.use(middlewareAutenticacion);
rutasHistorial.get('/exportar-csv', exportar);
rutasHistorial.get('/resumen', resumen);
rutasHistorial.get('/', listar);

export { rutasHistorial };
