import Joi from 'joi';
import { RolUsuario } from './rol-usuario';

export const esquemaActualizarPermisosUsuario = Joi.object({
  nombre: Joi.string().trim().min(3).max(120).optional(),
  correo: Joi.string().trim().email().max(160).optional(),
  rut: Joi.string().trim().max(20).allow('', null).optional(),
  rol: Joi.string()
    .valid(...Object.values(RolUsuario))
    .optional(),
  cuentaActiva: Joi.boolean().optional(),
  correoVerificado: Joi.boolean().optional()
}).min(1);
