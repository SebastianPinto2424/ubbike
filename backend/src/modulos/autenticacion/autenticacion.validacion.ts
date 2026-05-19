import Joi from 'joi';

const validarRut = (valor: string, helpers: Joi.CustomHelpers) => {
  const limpio = valor.replace(/\./g, '').replace('-', '').toUpperCase();
  const cuerpo = limpio.slice(0, -1);
  const dv = limpio.slice(-1);

  if (!/^\d{7,8}[0-9K]$/.test(limpio)) {
    return helpers.error('any.invalid');
  }

  let suma = 0;
  let multiplicador = 2;

  for (let i = cuerpo.length - 1; i >= 0; i -= 1) {
    suma += Number(cuerpo[i]) * multiplicador;
    multiplicador = multiplicador === 7 ? 2 : multiplicador + 1;
  }

  const esperado = 11 - (suma % 11);
  const dvEsperado = esperado === 11 ? '0' : esperado === 10 ? 'K' : esperado.toString();

  return dv === dvEsperado ? valor : helpers.error('any.invalid');
};

const esquemaContrasena = Joi.string()
  .min(12)
  .max(72)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$/)
  .required()
  .messages({
    'string.min': 'La contrasena debe tener al menos 12 caracteres',
    'string.pattern.base': 'La contrasena debe incluir mayuscula, minuscula, numero y simbolo'
  });

export const esquemaRegistro = Joi.object({
  nombre: Joi.string().trim().min(2).max(120).required(),
  rut: Joi.string().trim().min(7).max(20).custom(validarRut).optional().messages({
    'any.invalid': 'El RUT no es valido'
  }),
  correo: Joi.string().trim().email().max(160).required(),
  contrasena: esquemaContrasena
});

export const esquemaLogin = Joi.object({
  correo: Joi.string().trim().email().required(),
  contrasena: Joi.string().required()
});

export const esquemaSolicitudCambioContrasena = Joi.object({
  correo: Joi.string().trim().email().required()
});

export const esquemaVerificarCorreo = Joi.object({
  token: Joi.string().trim().required()
});

export const esquemaCompletarRegistro = Joi.object({
  token: Joi.string().trim().required(),
  nombre: Joi.string().trim().min(2).max(120).required(),
  contrasena: esquemaContrasena
});

export const esquemaCambioContrasena = Joi.object({
  token: Joi.string().trim().required(),
  contrasena: esquemaContrasena
});
