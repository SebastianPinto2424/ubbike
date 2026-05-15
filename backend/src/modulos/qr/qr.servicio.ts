import crypto from 'crypto';
import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { TipoMovimiento } from '../historial/tipo-movimiento';
import { AsignacionGuardia } from '../acceso/asignaciones/asignacion-guardia.entidad';
import { RolUsuario } from '../usuarios/rol-usuario';
import { Usuario } from '../usuarios/usuario.entidad';
import { CodigoQrTemporal } from './codigo-qr-temporal.entidad';

const duracionQrSegundos = 15;

type DatosGenerarQr = {
  usuarioId: string;
  bicicletaId?: string;
  bicicleteroId?: string;
  tipo?: TipoMovimiento;
};

type ContextoValidacionQr = {
  validadorUsuarioId: string;
  rol: string;
};

const repoQr = () => fuenteDatos.getRepository(CodigoQrTemporal);
const repoBicicletas = () => fuenteDatos.getRepository(Bicicleta);
const repoBicicleteros = () => fuenteDatos.getRepository(Bicicletero);
const repoAsignaciones = () => fuenteDatos.getRepository(AsignacionGuardia);

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
      usuario: true,
      bicicleteroActual: true
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(
      404,
      bicicletaId ? 'Bicicleta no encontrada' : 'Debes activar una bicicleta antes de generar el QR'
    );
  }

  return bicicleta;
};

export const generarQrTemporal = async (datos: DatosGenerarQr) => {
  const bicicleta = await buscarBicicletaParaQr(datos.usuarioId, datos.bicicletaId);
  const tipo =
    datos.tipo ?? (bicicleta.dentroBicicletero ? TipoMovimiento.SALIDA : TipoMovimiento.INGRESO);
  const bicicletero = datos.bicicleteroId
    ? await repoBicicleteros().findOneBy({ id: datos.bicicleteroId })
    : bicicleta.bicicleteroActual;

  if (datos.bicicleteroId && !bicicletero) {
    throw new ErrorHttp(404, 'Bicicletero no encontrado');
  }

  if (tipo === TipoMovimiento.INGRESO && !bicicletero) {
    throw new ErrorHttp(400, 'Selecciona un bicicletero para generar QR de ingreso');
  }

  if (tipo === TipoMovimiento.SALIDA && !bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta no registra ingreso activo');
  }

  if (tipo === TipoMovimiento.INGRESO && bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta ya registra ingreso activo');
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
      tipo,
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
      descripcion: bicicleta.descripcion,
      marca: bicicleta.marca,
      modelo: bicicleta.modelo,
      color: bicicleta.color,
      aro: bicicleta.aro,
      numeroSerie: bicicleta.numeroSerie,
      fotoUrl: bicicleta.fotoUrl
    },
    bicicletero: bicicletero
      ? {
          id: bicicletero.id,
          nombre: bicicletero.nombre
        }
      : null
  };
};

const validarBicicleteroGuardia = async (
  codigo: CodigoQrTemporal,
  contexto?: ContextoValidacionQr
) => {
  if (contexto?.rol !== RolUsuario.GUARDIA) {
    return;
  }

  const bicicleteroQr = codigo.bicicletero ?? codigo.bicicleta.bicicleteroActual;

  if (!bicicleteroQr) {
    throw new ErrorHttp(400, 'El QR no tiene bicicletero asociado');
  }

  const asignacion = await repoAsignaciones().findOne({
    where: {
      guardia: { id: contexto.validadorUsuarioId },
      bicicletero: { id: bicicleteroQr.id },
      activa: true
    }
  });

  if (!asignacion) {
    throw new ErrorHttp(403, 'El QR corresponde a otro bicicletero o no esta asignado a tu turno');
  }
};

export const validarQrTemporal = async (token: string, contexto?: ContextoValidacionQr) => {
  const codigo = await obtenerCodigoQrValido(token);
  await validarBicicleteroGuardia(codigo, contexto);

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
      marca: codigo.bicicleta.marca,
      modelo: codigo.bicicleta.modelo,
      color: codigo.bicicleta.color,
      aro: codigo.bicicleta.aro,
      numeroSerie: codigo.bicicleta.numeroSerie,
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
