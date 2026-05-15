import { SolicitudAutenticada } from '../../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../../comun/utils/controlador-async';
import {
  actualizarEstadoSolicitudGuardia,
  crearSolicitudGuardia,
  listarSolicitudesGuardia
} from './solicitud-guardia.servicio';

export const crear = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const solicitud = await crearSolicitudGuardia({
    usuarioId: req.usuario!.usuarioId,
    bicicleteroId: req.body.bicicleteroId,
    tipo: req.body.tipo,
    mensaje: req.body.mensaje
  });

  return res.status(201).json({ solicitud });
});

export const listar = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const solicitudes = await listarSolicitudesGuardia({
    usuarioId: req.usuario!.usuarioId,
    rol: req.usuario!.rol
  });

  return res.status(200).json({ solicitudes });
});

export const actualizarEstado = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const solicitud = await actualizarEstadoSolicitudGuardia(
    req.usuario!.usuarioId,
    req.usuario!.rol,
    req.params.id,
    req.body.estado
  );

  return res.status(200).json({ solicitud });
});
