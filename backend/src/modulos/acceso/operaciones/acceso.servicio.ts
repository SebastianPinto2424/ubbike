import { ErrorHttp } from '../../../comun/errors/error-http';
import { prisma, type ClientePrisma } from '../../../configuracion/prisma';
import { Prisma } from '../../../generated/prisma/client';
import { registrarAuditoria } from '../../auditoria/auditoria.servicio';
import { EstadoMovimiento } from '../../historial/estado-movimiento';
import { TipoMovimiento } from '../../historial/tipo-movimiento';
import { crearNotificacion } from '../../notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../../notificaciones/tipo-notificacion';
import { obtenerCodigoQrValido } from '../../qr/qr.servicio';
import { RolUsuario } from '../../usuarios/rol-usuario';
import { includeMovimientoCompleto, mapearMovimiento } from './acceso.mapeador';
import { validarReglaMovimiento } from './acceso.reglas';

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

type UsuarioOperacion = Prisma.UsuarioGetPayload<Record<string, never>>;
type BicicleteroOperacion = Prisma.BicicleteroGetPayload<Record<string, never>>;
type BicicletaOperacion = Prisma.BicicletaGetPayload<{
  include: {
    bicicleteroActual: true;
  };
}>;

const obtenerBicicleteroOperacion = async (
  guardiaId: string,
  rol: string,
  bicicleteroId?: string,
  bicicleteroQr?: BicicleteroOperacion | null,
  db: ClientePrisma = prisma
) => {
  const validarAsignacionGuardia = async (bicicletero: BicicleteroOperacion) => {
    if (rol !== RolUsuario.GUARDIA) {
      return;
    }

    const asignacion = await db.asignacionGuardia.findFirst({
      where: {
        guardiaId,
        bicicleteroId: bicicletero.id,
        activa: true
      }
    });

    if (!asignacion) {
      throw new ErrorHttp(403, 'El guardia no esta asignado a este bicicletero');
    }
  };

  if (bicicleteroId) {
    const bicicletero = await db.bicicletero.findUnique({
      where: {
        id: bicicleteroId
      }
    });

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

  const asignacion = await db.asignacionGuardia.findFirst({
    where: {
      guardiaId,
      activa: true
    },
    include: {
      bicicletero: true
    },
    orderBy: {
      iniciaEn: 'desc'
    }
  });

  if (!asignacion) {
    throw new ErrorHttp(400, 'Debes indicar bicicletero para esta operacion');
  }

  return asignacion.bicicletero;
};

const registrarMovimiento = async ({
  usuario,
  bicicleta,
  bicicletero,
  guardiaId,
  tipo,
  estado,
  origen,
  motivo,
  db
}: {
  usuario: UsuarioOperacion;
  bicicleta: BicicletaOperacion;
  bicicletero: BicicleteroOperacion;
  guardiaId: string;
  tipo: TipoMovimiento;
  estado: EstadoMovimiento;
  origen: 'QR' | 'MANUAL';
  motivo?: string | null;
  db: ClientePrisma;
}) => {
  const movimiento = await db.movimiento.create({
    data: {
      usuarioId: usuario.id,
      bicicletaId: bicicleta.id,
      bicicleteroId: bicicletero.id,
      validadoPorGuardiaId: guardiaId,
      tipo,
      estado,
      origen,
      motivoDenegacion: motivo ?? null
    }
  });

  if (estado === EstadoMovimiento.CONFIRMADO) {
    await db.bicicleta.update({
      where: {
        id: bicicleta.id
      },
      data:
        tipo === TipoMovimiento.INGRESO
          ? {
              dentroBicicletero: true,
              bicicleteroActualId: bicicletero.id
            }
          : {
              dentroBicicletero: false,
              bicicleteroActualId: null
            }
    });
  }

  await crearNotificacion(
    {
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
    },
    db
  );

  await registrarAuditoria(
    {
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
    },
    db
  );

  const movimientoCompleto = await db.movimiento.findUniqueOrThrow({
    where: {
      id: movimiento.id
    },
    include: includeMovimientoCompleto
  });

  return mapearMovimiento(movimientoCompleto);
};

export const confirmarQr = async (datos: DatosConfirmarQr) => {
  return prisma.$transaction(async (db) => {
    const codigo = await obtenerCodigoQrValido(datos.token, db);
    const bicicletero = await obtenerBicicleteroOperacion(
      datos.guardiaId,
      datos.rol,
      datos.bicicleteroId,
      codigo.bicicletero,
      db
    );
    const tipo = codigo.tipo as TipoMovimiento;

    validarReglaMovimiento(codigo.bicicleta, tipo);

    const marcado = await db.codigoQrTemporal.updateMany({
      where: {
        id: codigo.id,
        usado: false
      },
      data: {
        usado: true
      }
    });

    if (marcado.count !== 1) {
      throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
    }

    return registrarMovimiento({
      usuario: codigo.usuario,
      bicicleta: codigo.bicicleta,
      bicicletero,
      guardiaId: datos.guardiaId,
      tipo,
      estado: EstadoMovimiento.CONFIRMADO,
      origen: 'QR',
      db
    });
  });
};

export const denegarQr = async (datos: DatosDenegarQr) => {
  return prisma.$transaction(async (db) => {
    const codigo = await obtenerCodigoQrValido(datos.token, db);
    const bicicletero = await obtenerBicicleteroOperacion(
      datos.guardiaId,
      datos.rol,
      datos.bicicleteroId,
      codigo.bicicletero,
      db
    );
    const tipo = codigo.tipo as TipoMovimiento;

    const marcado = await db.codigoQrTemporal.updateMany({
      where: {
        id: codigo.id,
        usado: false
      },
      data: {
        usado: true
      }
    });

    if (marcado.count !== 1) {
      throw new ErrorHttp(409, 'QR ya fue usado o reemplazado');
    }

    return registrarMovimiento({
      usuario: codigo.usuario,
      bicicleta: codigo.bicicleta,
      bicicletero,
      guardiaId: datos.guardiaId,
      tipo,
      estado: EstadoMovimiento.DENEGADO,
      origen: 'QR',
      motivo: datos.motivo,
      db
    });
  });
};

export const registrarGestionManual = async (datos: DatosGestionManual) => {
  return prisma.$transaction(async (db) => {
    const criteriosUsuario = [
      ...(datos.correo ? [{ correo: datos.correo.toLowerCase() }] : []),
      ...(datos.rut ? [{ rut: datos.rut }] : [])
    ];

    if (!criteriosUsuario.length) {
      throw new ErrorHttp(400, 'Debes indicar correo o RUT');
    }

    const usuario = await db.usuario.findFirst({
      where: {
        OR: criteriosUsuario
      }
    });

    if (!usuario) {
      throw new ErrorHttp(404, 'Usuario no encontrado');
    }

    const bicicleta = await db.bicicleta.findFirst({
      where: datos.bicicletaId
        ? {
            id: datos.bicicletaId,
            usuarioId: usuario.id,
            eliminadoEn: null
          }
        : {
            usuarioId: usuario.id,
            activa: true,
            eliminadoEn: null
          },
      include: {
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
      bicicleta.bicicleteroActual,
      db
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
      motivo: datos.motivo,
      db
    });
  });
};
