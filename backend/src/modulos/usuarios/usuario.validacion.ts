import Joi from 'joi';
import { RolUsuario } from './rol-usuario';

export const esquemaActualizarPermisosUsuario = Joi.object({
  rol: Joi.string()
    .valid(...Object.values(RolUsuario))
    .optional(),
  cuentaActiva: Joi.boolean().optional(),
  correoVerificado: Joi.boolean().optional()
}).min(1);
