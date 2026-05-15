import Joi from 'joi';
import { TipoMovimiento } from '../../historial/tipo-movimiento';

export const esquemaConfirmarQr = Joi.object({
  token: Joi.string().trim().required(),
  bicicleteroId: Joi.string().uuid().optional()
});

export const esquemaDenegarQr = Joi.object({
  token: Joi.string().trim().required(),
  motivo: Joi.string().trim().min(3).max(600).required(),
  bicicleteroId: Joi.string().uuid().optional()
});

export const esquemaGestionManual = Joi.object({
  correo: Joi.string().trim().email().optional(),
  rut: Joi.string().trim().max(20).optional(),
  bicicletaId: Joi.string().uuid().optional(),
  bicicleteroId: Joi.string().uuid().optional(),
  tipo: Joi.string()
    .valid(...Object.values(TipoMovimiento))
    .required(),
  denegar: Joi.boolean().default(false),
  motivo: Joi.when('denegar', {
    is: true,
    then: Joi.string().trim().min(3).max(600).required(),
    otherwise: Joi.string().trim().max(600).allow('', null)
  })
}).or('correo', 'rut');
