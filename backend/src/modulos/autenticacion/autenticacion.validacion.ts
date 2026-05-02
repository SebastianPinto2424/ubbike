import Joi from 'joi';
import { RolUsuario } from '../usuarios/rol-usuario';

const rolesRegistrables = Object.values(RolUsuario).filter(
  (rol) => rol !== RolUsuario.ADMINISTRADOR
);

export const esquemaRegistro = Joi.object({
  nombre: Joi.string().trim().min(2).max(120).required(),
  rut: Joi.string().trim().min(7).max(20).optional(),
  correo: Joi.string().trim().email().max(160).required(),
  contrasena: Joi.string().min(8).max(72).required(),
  rol: Joi.string()
    .valid(...rolesRegistrables)
    .default(RolUsuario.ESTUDIANTE)
});

export const esquemaLogin = Joi.object({
  correo: Joi.string().trim().email().required(),
  contrasena: Joi.string().required()
});

export const esquemaSolicitudCambioContrasena = Joi.object({
  correo: Joi.string().trim().email().required()
});

export const esquemaCambioContrasena = Joi.object({
  token: Joi.string().trim().required(),
  contrasena: Joi.string().min(8).max(72).required()
});
