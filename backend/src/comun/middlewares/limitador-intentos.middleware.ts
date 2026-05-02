import { NextFunction, Request, Response } from 'express';

type OpcionesLimitador = {
  ventanaMs: number;
  maximo: number;
  mensaje: string;
};

type RegistroIntentos = {
  cantidad: number;
  reiniciaEn: number;
};

const intentos = new Map<string, RegistroIntentos>();

export const limitarIntentos =
  (opciones: OpcionesLimitador) => (req: Request, res: Response, next: NextFunction) => {
    const ahora = Date.now();
    const clave = `${req.ip}:${req.path}`;
    const registro = intentos.get(clave);

    if (!registro || registro.reiniciaEn <= ahora) {
      intentos.set(clave, {
        cantidad: 1,
        reiniciaEn: ahora + opciones.ventanaMs
      });
      return next();
    }

    if (registro.cantidad >= opciones.maximo) {
      const segundos = Math.ceil((registro.reiniciaEn - ahora) / 1000);
      res.setHeader('Retry-After', segundos.toString());
      return res.status(429).json({
        message: opciones.mensaje
      });
    }

    registro.cantidad += 1;
    intentos.set(clave, registro);
    return next();
  };
