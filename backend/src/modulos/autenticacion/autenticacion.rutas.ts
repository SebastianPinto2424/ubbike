import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
import { limitarIntentos } from '../../comun/middlewares/limitador-intentos.middleware';
import { validarCuerpo } from '../../comun/middlewares/validar-cuerpo.middleware';
import {
  cambiarContrasena,
  iniciarSesion,
  obtenerPerfil,
  registrar,
  solicitarCambioContrasena,
  verificarCorreo
} from './autenticacion.controlador';
import {
  esquemaCambioContrasena,
  esquemaLogin,
  esquemaRegistro,
  esquemaSolicitudCambioContrasena
} from './autenticacion.validacion';

const rutasAutenticacion = Router();

rutasAutenticacion.post(
  ['/registro', '/register'],
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 20,
    mensaje: 'Demasiados registros desde este origen. Intenta mas tarde.'
  }),
  validarCuerpo(esquemaRegistro),
  registrar
);
rutasAutenticacion.post(
  '/login',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 10,
    mensaje: 'Demasiados intentos de ingreso. Intenta mas tarde.'
  }),
  validarCuerpo(esquemaLogin),
  iniciarSesion
);
rutasAutenticacion.get(['/perfil', '/me'], middlewareAutenticacion, obtenerPerfil);
rutasAutenticacion.get('/verificar-correo', verificarCorreo);
rutasAutenticacion.post(
  '/solicitar-cambio-contrasena',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 5,
    mensaje: 'Demasiadas solicitudes de cambio de contrasena. Intenta mas tarde.'
  }),
  validarCuerpo(esquemaSolicitudCambioContrasena),
  solicitarCambioContrasena
);
rutasAutenticacion.post(
  '/cambiar-contrasena',
  limitarIntentos({
    ventanaMs: 15 * 60 * 1000,
    maximo: 10,
    mensaje: 'Demasiados intentos de cambio de contrasena. Intenta mas tarde.'
  }),
  validarCuerpo(esquemaCambioContrasena),
  cambiarContrasena
);

export { rutasAutenticacion };
