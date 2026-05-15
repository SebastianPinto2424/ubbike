import { SolicitudAutenticada } from '../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../comun/utils/controlador-async';
import {
  listarNotificacionesUsuario,
  marcarNotificacionLeida,
  marcarTodasLeidas
} from './notificacion.servicio';

export const listarNotificaciones = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const notificaciones = await listarNotificacionesUsuario(req.usuario!.usuarioId);
  return res.status(200).json({ notificaciones });
});

export const marcarLeida = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const notificacion = await marcarNotificacionLeida(req.usuario!.usuarioId, req.params.id);
  return res.status(200).json({ notificacion });
});

export const marcarTodas = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const resultado = await marcarTodasLeidas(req.usuario!.usuarioId);
  return res.status(200).json(resultado);
});
