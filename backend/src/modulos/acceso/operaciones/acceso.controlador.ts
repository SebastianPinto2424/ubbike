import { SolicitudAutenticada } from '../../../comun/middlewares/autenticacion.middleware';
import { controladorAsync } from '../../../comun/utils/controlador-async';
import { confirmarQr, denegarQr, registrarGestionManual } from './acceso.servicio';

export const confirmarAccesoQr = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const movimiento = await confirmarQr({
    token: req.body.token,
    bicicleteroId: req.body.bicicleteroId,
    guardiaId: req.usuario!.usuarioId,
    rol: req.usuario!.rol
  });

  return res.status(201).json({ movimiento });
});

export const denegarAccesoQr = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const movimiento = await denegarQr({
    token: req.body.token,
    motivo: req.body.motivo,
    bicicleteroId: req.body.bicicleteroId,
    guardiaId: req.usuario!.usuarioId,
    rol: req.usuario!.rol
  });

  return res.status(201).json({ movimiento });
});

export const registrarManual = controladorAsync<SolicitudAutenticada>(async (req, res) => {
  const movimiento = await registrarGestionManual({
    guardiaId: req.usuario!.usuarioId,
    rol: req.usuario!.rol,
    correo: req.body.correo,
    rut: req.body.rut,
    bicicletaId: req.body.bicicletaId,
    bicicleteroId: req.body.bicicleteroId,
    tipo: req.body.tipo,
    denegar: req.body.denegar,
    motivo: req.body.motivo
  });

  return res.status(201).json({ movimiento });
});
