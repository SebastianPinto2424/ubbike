import { ErrorHttp } from '../../../comun/errors/error-http';
import { fuenteDatos } from '../../../configuracion/base-datos';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import { Bicicleta } from '../../bicicletas/bicicleta.entidad';
import { Bicicletero } from '../../bicicleteros/bicicletero.entidad';
import { EstadoMovimiento } from '../../historial/estado-movimiento';
import { Movimiento } from '../../historial/movimiento.entidad';
import { TipoMovimiento } from '../../historial/tipo-movimiento';
import { crearNotificacion } from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';
import { CodigoQrTemporal } from '../../qr/codigo-qr-temporal.entidad';
import { obtenerCodigoQrValido } from '../../qr/qr.servicio';
import { Usuario } from '../../usuarios/usuario.entidad';
import { RolUsuario } from '../../usuarios/rol-usuario';
import { AsignacionGuardia } from '../asignaciones/asignacion-guardia.entidad';

type DatosConfirmarQr = {
  token: string;
  guardiaId: string;
  rol: string;
  bicicleteroId?: string;
};

type DatosDenegarQr = DatosConfirmarQr & {
  motivo: string;
};

type DatosGestionManual = {
  guardiaId: string;
  rol: string;
  correo?: string;
  rut?: string;
  bicicletaId?: string;
  bicicleteroId?: string;
  tipo: TipoMovimiento;
  denegar?: boolean;
  motivo?: string | null;
};

const repoMovimientos = () => fuenteDatos.getRepository(Movimiento);
const repoQr = () => fuenteDatos.getRepository(CodigoQrTemporal);
const repoBicicletas = () => fuenteDatos.getRepository(Bicicleta);
const repoBicicleteros = () => fuenteDatos.getRepository(Bicicletero);
const repoUsuarios = () => fuenteDatos.getRepository(Usuario);
const repoAsignaciones = () => fuenteDatos.getRepository(AsignacionGuardia);

const mapearMovimiento = (movimiento: Movimiento) => ({
  id: movimiento.id,
  tipo: movimiento.tipo,
  estado: movimiento.estado,
  motivoDenegacion: movimiento.motivoDenegacion,
  origen: movimiento.origen,
  creadoEn: movimiento.creadoEn,
  usuario: {
    id: movimiento.usuario.id,
    nombre: movimiento.usuario.nombre,
    correo: movimiento.usuario.correo,
    rut: movimiento.usuario.rut
  },
  bicicleta: {
    id: movimiento.bicicleta.id,
    descripcion: movimiento.bicicleta.descripcion
  },
  bicicletero: {
    id: movimiento.bicicletero.id,
    nombre: movimiento.bicicletero.nombre
  },
  guardia: {
    id: movimiento.validadoPorGuardia.id,
    nombre: movimiento.validadoPorGuardia.nombre,
    correo: movimiento.validadoPorGuardia.correo
  }
});

const obtenerBicicleteroOperacion = async (
  guardiaId: string,
  rol: string,
  bicicleteroId?: string,
  bicicleteroQr?: Bicicletero | null
) => {
  const validarAsignacionGuardia = async (bicicletero: Bicicletero) => {
    if (rol !== RolUsuario.GUARDIA) {
      return;
    }

    const asignacion = await repoAsignaciones().findOne({
      where: {
        guardia: { id: guardiaId },
        bicicletero: { id: bicicletero.id },
        activa: true
      }
    });

    if (!asignacion) {
      throw new ErrorHttp(403, 'El guardia no esta asignado a este bicicletero');
    }
  };

  if (bicicleteroId) {
    const bicicletero = await repoBicicleteros().findOneBy({ id: bicicleteroId });
    if (!bicicletero) {
      throw new ErrorHttp(404, 'Bicicletero no encontrado');
    }

    await validarAsignacionGuardia(bicicletero);
    return bicicletero;
  }

  if (bicicleteroQr) {
    await validarAsignacionGuardia(bicicleteroQr);
    return bicicleteroQr;
  }

  const asignacion = await repoAsignaciones().findOne({
    where: {
      guardia: { id: guardiaId },
      activa: true
    },
    relations: {
      bicicletero: true
    },
    order: {
      iniciaEn: 'DESC'
    }
  });

  if (!asignacion) {
    throw new ErrorHttp(400, 'Debes indicar bicicletero para esta operacion');
  }

  return asignacion.bicicletero;
};

const validarReglaMovimiento = (bicicleta: Bicicleta, tipo: TipoMovimiento) => {
  if (tipo === TipoMovimiento.INGRESO && bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta ya registra ingreso activo');
  }

  if (tipo === TipoMovimiento.SALIDA && !bicicleta.dentroBicicletero) {
    throw new ErrorHttp(409, 'La bicicleta no registra ingreso activo');
  }
};

const registrarMovimiento = async ({
  usuario,
  bicicleta,
  bicicletero,
  guardiaId,
  tipo,
  estado,
  origen,
  motivo
}: {
  usuario: Usuario;
  bicicleta: Bicicleta;
  bicicletero: Bicicletero;
  guardiaId: string;
  tipo: TipoMovimiento;
  estado: EstadoMovimiento;
  origen: 'QR' | 'MANUAL';
  motivo?: string | null;
}) => {
  const movimiento = await repoMovimientos().save(
    repoMovimientos().create({
      usuario,
      bicicleta,
      bicicletero,
      validadoPorGuardia: { id: guardiaId } as Usuario,
      tipo,
      estado,
      origen,
      motivoDenegacion: motivo ?? null
    })
  );

  if (estado === EstadoMovimiento.CONFIRMADO) {
    if (tipo === TipoMovimiento.INGRESO) {
      bicicleta.dentroBicicletero = true;
      bicicleta.bicicleteroActual = bicicletero;
    } else {
      bicicleta.dentroBicicletero = false;
      bicicleta.bicicleteroActual = null;
    }

    await repoBicicletas().save(bicicleta);
  }

  await crearNotificacion({
    usuarioId: usuario.id,
    titulo:
      estado === EstadoMovimiento.CONFIRMADO
        ? `Movimiento confirmado: ${tipo.toLowerCase()}`
        : `Movimiento denegado: ${tipo.toLowerCase()}`,
    mensaje:
      estado === EstadoMovimiento.CONFIRMADO
        ? `${bicicleta.descripcion} fue registrada en ${bicicletero.nombre}.`
        : (motivo ?? 'Operacion denegada por guardia.'),
    tipo: TipoNotificacion.MOVIMIENTO,
    datos: {
      movimientoId: movimiento.id,
      estado,
      tipo
    }
  });

  await registrarAuditoria({
    actorUsuarioId: guardiaId,
    accion:
      estado === EstadoMovimiento.CONFIRMADO ? 'MOVIMIENTO_CONFIRMADO' : 'MOVIMIENTO_DENEGADO',
    entidad: 'movimientos',
    entidadId: movimiento.id,
    datos: {
      usuarioId: usuario.id,
      bicicletaId: bicicleta.id,
      bicicleteroId: bicicletero.id,
      tipo,
      estado,
      origen
    }
  });

  const movimientoCompleto = await repoMovimientos().findOneOrFail({
    where: { id: movimiento.id },
    relations: {
      usuario: true,
      bicicleta: true,
      bicicletero: true,
      validadoPorGuardia: true
    }
  });

  return mapearMovimiento(movimientoCompleto);
};

export const confirmarQr = async (datos: DatosConfirmarQr) => {
  const codigo = await obtenerCodigoQrValido(datos.token);
  const bicicletero = await obtenerBicicleteroOperacion(
    datos.guardiaId,
    datos.rol,
    datos.bicicleteroId,
    codigo.bicicletero
  );

  validarReglaMovimiento(codigo.bicicleta, codigo.tipo);

  const movimiento = await registrarMovimiento({
    usuario: codigo.usuario,
    bicicleta: codigo.bicicleta,
    bicicletero,
    guardiaId: datos.guardiaId,
    tipo: codigo.tipo,
    estado: EstadoMovimiento.CONFIRMADO,
    origen: 'QR'
  });

  codigo.usado = true;
  await repoQr().save(codigo);

  return movimiento;
};

export const denegarQr = async (datos: DatosDenegarQr) => {
  const codigo = await obtenerCodigoQrValido(datos.token);
  const bicicletero = await obtenerBicicleteroOperacion(
    datos.guardiaId,
    datos.rol,
    datos.bicicleteroId,
    codigo.bicicletero
  );

  const movimiento = await registrarMovimiento({
    usuario: codigo.usuario,
    bicicleta: codigo.bicicleta,
    bicicletero,
    guardiaId: datos.guardiaId,
    tipo: codigo.tipo,
    estado: EstadoMovimiento.DENEGADO,
    origen: 'QR',
    motivo: datos.motivo
  });

  codigo.usado = true;
  await repoQr().save(codigo);

  return movimiento;
};

export const registrarGestionManual = async (datos: DatosGestionManual) => {
  const usuario = await repoUsuarios().findOne({
    where: [
      ...(datos.correo ? [{ correo: datos.correo.toLowerCase() }] : []),
      ...(datos.rut ? [{ rut: datos.rut }] : [])
    ]
  });

  if (!usuario) {
    throw new ErrorHttp(404, 'Usuario no encontrado');
  }

  const bicicleta = await repoBicicletas().findOne({
    where: datos.bicicletaId
      ? {
          id: datos.bicicletaId,
          usuario: { id: usuario.id }
        }
      : {
          usuario: { id: usuario.id },
          activa: true
        },
    relations: {
      usuario: true,
      bicicleteroActual: true
    }
  });

  if (!bicicleta) {
    throw new ErrorHttp(404, 'Bicicleta activa no encontrada para el usuario');
  }

  const bicicletero = await obtenerBicicleteroOperacion(
    datos.guardiaId,
    datos.rol,
    datos.bicicleteroId,
    bicicleta.bicicleteroActual
  );

  const estado = datos.denegar ? EstadoMovimiento.DENEGADO : EstadoMovimiento.CONFIRMADO;

  if (estado === EstadoMovimiento.CONFIRMADO) {
    validarReglaMovimiento(bicicleta, datos.tipo);
  }

  return registrarMovimiento({
    usuario,
    bicicleta,
    bicicletero,
    guardiaId: datos.guardiaId,
    tipo: datos.tipo,
    estado,
    origen: 'MANUAL',
    motivo: datos.motivo
  });
};
