import crypto from 'crypto';
import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { TipoMovimiento } from '../historial/tipo-movimiento';
import { Usuario } from '../usuarios/usuario.entidad';
import { CodigoQrTemporal } from './codigo-qr-temporal.entidad';

const duracionQrSegundos = 15;

type DatosGenerarQr = {
  usuarioId: string;
  bicicletaId?: string;
  bicicleteroId?: string;
  tipo: TipoMovimiento;
};

const repoQr = () => fuenteDatos.getRepository(CodigoQrTemporal);
const repoBicicletas = () => fuenteDatos.getRepository(Bicicleta);
const repoBicicleteros = () => fuenteDatos.getRepository(Bicicletero);

const buscarBicicletaParaQr = async (usuarioId: string, bicicletaId?: string) => {
  const where = bicicletaId
    ? {
        id: bicicletaId,
        usuario: {
          id: usuarioId
        }
      }
    : {
        activa: true,
        usuario: {
          id: usuarioId
        }
      };

  const bicicleta = await repoBicicletas().findOne({
    where,
    relations: {
      usuario: true
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(
      404,
      bicicletaId
        ? 'Bicicleta no encontrada'
        : 'Debes activar una bicicleta antes de generar el QR'
    );
  }

  return bicicleta;
};

export const generarQrTemporal = async (datos: DatosGenerarQr) => {
  const bicicleta = await buscarBicicletaParaQr(datos.usuarioId, datos.bicicletaId);
  const bicicletero = datos.bicicleteroId
    ? await repoBicicleteros().findOneBy({ id: datos.bicicleteroId })
    : null;

  if (datos.bicicleteroId && !bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado');
  }

  await repoQr().update(
    {
      usuario: {
        id: datos.usuarioId
      },
      usado: false
    },
    {
      usado: true
    }
  );

  const token = `UBBIKE-${crypto.randomBytes(24).toString('base64url')}`;
  const expiraEn = new Date(Date.now() + duracionQrSegundos * 1000);
  const codigo = await repoQr().save(
    repoQr().create({
      token,
      usuario: { id: datos.usuarioId } as Usuario,
      bicicleta,
      bicicletero,
      tipo: datos.tipo,
      expiraEn,
      usado: false
    })
  );

  return {
    id: codigo.id,
    token: codigo.token,
    tipo: codigo.tipo,
    duracionSegundos: duracionQrSegundos,
    expiraEn: codigo.expiraEn,
    bicicleta: {
      id: bicicleta.id,
      descripcion: bicicleta.descripcion
    },
    bicicletero: bicicletero
      ? {
          id: bicicletero.id,
          nombre: bicicletero.nombre
        }
      : null
  };
};

export const validarQrTemporal = async (token: string) => {
  const codigo = await obtenerCodigoQrValido(token);

  return {
    valido: true,
    token: codigo.token,
    tipo: codigo.tipo,
    expiraEn: codigo.expiraEn,
    usuario: {
      id: codigo.usuario.id,
      nombre: codigo.usuario.nombre,
      correo: codigo.usuario.correo,
      rut: codigo.usuario.rut
    },
    bicicleta: {
      id: codigo.bicicleta.id,
      descripcion: codigo.bicicleta.descripcion,
      fotoUrl: codigo.bicicleta.fotoUrl
    },
    bicicletero: codigo.bicicletero
      ? {
          id: codigo.bicicletero.id,
          nombre: codigo.bicicletero.nombre
        }
      : null
  };
};

export const obtenerCodigoQrValido = async (token: string) => {
  const codigo = await repoQr().findOne({
    where: {
      token
    },
    relations: {
      usuario: true,
      bicicleta: {
        bicicleteroActual: true
      },
      bicicletero: true
    }
  });

  if (!codigo) {
    throw new ErrorHttp(404, 'QR no encontrado');
  }

  if (codigo.usado) {
    throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
  }

  if (codigo.expiraEn.getTime() < Date.now()) {
    throw new ErrorHttp(410, 'QR expirado. Debe regenerarse');
  }

  return codigo;
};
