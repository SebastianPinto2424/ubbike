import { Router } from 'express';
import { middlewareAutenticacion } from '../../../comun/middlewares/autenticacion.middleware';
import { validarCuerpo } from '../../../comun/middlewares/validar-cuerpo.middleware';
import { actualizarEstado, crear, listar } from './solicitud-guardia.controlador';
import {
  esquemaActualizarEstadoSolicitudGuardia,
  esquemaCrearSolicitudGuardia
} from './solicitud-guardia.validacion';

const rutasSolicitudesGuardia = Router();

rutasSolicitudesGuardia.use(middlewareAutenticacion);
rutasSolicitudesGuardia.get('/', listar);
rutasSolicitudesGuardia.post('/', validarCuerpo(esquemaCrearSolicitudGuardia), crear);
rutasSolicitudesGuardia.patch(
  '/:id/estado',
  validarCuerpo(esquemaActualizarEstadoSolicitudGuardia),
  actualizarEstado
);

export { rutasSolicitudesGuardia };
