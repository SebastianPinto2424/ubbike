import Joi from 'joi';

export const esquemaCrearBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).required(),
  fotoUrl: Joi.string().trim().uri().max(500).allow('', null),
  activar: Joi.boolean().default(false)
});

export const esquemaActualizarBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).optional(),
  fotoUrl: Joi.string().trim().uri().max(500).allow('', null).optional()
}).min(1);
