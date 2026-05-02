import Joi from 'joi';

export const esquemaCrearBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).required(),
  marca: Joi.string().trim().max(80).allow('', null),
  modelo: Joi.string().trim().max(80).allow('', null),
  color: Joi.string().trim().max(60).allow('', null),
  aro: Joi.string().trim().max(30).allow('', null),
  numeroSerie: Joi.string().trim().max(120).allow('', null),
  fotoUrl: Joi.string().trim().max(1500000).allow('', null),
  activar: Joi.boolean().default(false)
});

export const esquemaActualizarBicicleta = Joi.object({
  descripcion: Joi.string().trim().min(3).max(255).optional(),
  marca: Joi.string().trim().max(80).allow('', null).optional(),
  modelo: Joi.string().trim().max(80).allow('', null).optional(),
  color: Joi.string().trim().max(60).allow('', null).optional(),
  aro: Joi.string().trim().max(30).allow('', null).optional(),
  numeroSerie: Joi.string().trim().max(120).allow('', null).optional(),
  fotoUrl: Joi.string().trim().max(1500000).allow('', null).optional()
}).min(1);
