import { Router } from 'express';
import { middlewareAutenticacion } from '../../comun/middlewares/autenticacion.middleware';
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

rutasAutenticacion.post(['/registro', '/register'], validarCuerpo(esquemaRegistro), registrar);
rutasAutenticacion.post('/login', validarCuerpo(esquemaLogin), iniciarSesion);
rutasAutenticacion.get(['/perfil', '/me'], middlewareAutenticacion, obtenerPerfil);
rutasAutenticacion.get('/verificar-correo', verificarCorreo);
rutasAutenticacion.post(
  '/solicitar-cambio-contrasena',
  validarCuerpo(esquemaSolicitudCambioContrasena),
  solicitarCambioContrasena
);
rutasAutenticacion.post(
  '/cambiar-contrasena',
  validarCuerpo(esquemaCambioContrasena),
  cambiarContrasena
);

export { rutasAutenticacion };
