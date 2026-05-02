import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { listar, resumen } from './historial.controlador';

const rutasHistorial = Router();

rutasHistorial.use(middlewareAutenticacion);
rutasHistorial.get('/', listar);
rutasHistorial.get('/resumen', resumen);

export { rutasHistorial };
