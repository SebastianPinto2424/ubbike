import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { RolUsuario } from '../usuarios/rol-usuario';

type FiltrosHistorial = {
  usuarioId: string;
  rol: string;
  q?: string;
  periodo?: 'DIA' | 'SEMANA' | 'MES' | 'ANIO';
  desde?: string;
  hasta?: string;
  tipo?: 'INGRESO' | 'RETIRO' | 'TODOS';
  estado?: 'CONFIRMADO' | 'DENEGADO' | 'TODOS';
  bicicleteroId?: string;
  guardiaId?: string;
  origen?: 'QR' | 'MANUAL' | 'TODOS';
  pagina?: number;
  limite?: number;
};

const rolesCentral: string[] = [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR];

const includeMovimientoCompleto = {
  usuario: true,
  bicicleta: true,
  bicicletero: true,
  validadoPorGuardia: true
} satisfies Prisma.MovimientoInclude;

type MovimientoCompleto = Prisma.MovimientoGetPayload<{
  include: typeof includeMovimientoCompleto;
}>;

const inicioPeriodo = (periodo?: 'DIA' | 'SEMANA' | 'MES' | 'ANIO') => {
  if (!periodo) {
    return null;
  }

  const fecha = new Date();

  if (periodo === 'DIA') {
    fecha.setHours(0, 0, 0, 0);
  }

  if (periodo === 'SEMANA') {
    fecha.setDate(fecha.getDate() - 7);
  }

  if (periodo === 'MES') {
    fecha.setMonth(fecha.getMonth() - 1);
  }

  if (periodo === 'ANIO') {
    fecha.setFullYear(fecha.getFullYear() - 1);
  }

  return fecha;
};

const puedeVerTodo = (rol: string) => rolesCentral.includes(rol);

const normalizarFecha = (valor: string, finDia: boolean) => {
  const esFechaSimple = /^\d{4}-\d{2}-\d{2}$/.test(valor);
  const fecha = new Date(esFechaSimple ? `${valor}T00:00:00` : valor);

  if (Number.isNaN(fecha.getTime())) {
    throw new ErrorHttp(400, 'Filtro de fecha invalido');
  }

  if (esFechaSimple && finDia) {
    fecha.setHours(23, 59, 59, 999);
  }

  return fecha;
};

const mapearMovimiento = (movimiento: MovimientoCompleto) => ({
  id: movimiento.id,
  tipo: movimiento.tipo,
  estado: movimiento.estado,
  motivoDenegacion: movimiento.motivoDenegacion,
  comentarioGuardia: movimiento.comentarioGuardia,
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

const construirWhereMovimientos = (filtros: FiltrosHistorial) => {
  const condiciones: Prisma.MovimientoWhereInput[] = [];

  if (filtros.rol === RolUsuario.GUARDIA) {
    condiciones.push({ validadoPorGuardiaId: filtros.usuarioId });
  } else if (!puedeVerTodo(filtros.rol)) {
    condiciones.push({ usuarioId: filtros.usuarioId });
  } else if (filtros.guardiaId) {
    condiciones.push({ validadoPorGuardiaId: filtros.guardiaId });
  }

  if (filtros.q) {
    const q = filtros.q;
    condiciones.push({
      OR: [
        { usuario: { nombre: { contains: q, mode: 'insensitive' } } },
        { usuario: { correo: { contains: q, mode: 'insensitive' } } },
        { usuario: { rut: { contains: q, mode: 'insensitive' } } },
        { validadoPorGuardia: { nombre: { contains: q, mode: 'insensitive' } } },
        { validadoPorGuardia: { correo: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { descripcion: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { marca: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { modelo: { contains: q, mode: 'insensitive' } } },
        { bicicleta: { numeroSerie: { contains: q, mode: 'insensitive' } } },
        { bicicletero: { nombre: { contains: q, mode: 'insensitive' } } }
      ]
    });
  }

  if (filtros.tipo && filtros.tipo !== 'TODOS') {
    condiciones.push({ tipo: filtros.tipo });
  }

  if (filtros.estado && filtros.estado !== 'TODOS') {
    condiciones.push({ estado: filtros.estado });
  }

  if (filtros.origen && filtros.origen !== 'TODOS') {
    condiciones.push({ origen: filtros.origen });
  }

  if (filtros.bicicleteroId) {
    condiciones.push({ bicicleteroId: filtros.bicicleteroId });
  }

  const fecha: Prisma.DateTimeFilter = {};
  const desde = filtros.desde
    ? normalizarFecha(filtros.desde, false)
    : inicioPeriodo(filtros.periodo);
  const hasta = filtros.hasta ? normalizarFecha(filtros.hasta, true) : null;

  if (desde) {
    fecha.gte = desde;
  }

  if (hasta) {
    fecha.lte = hasta;
  }

  if (fecha.gte || fecha.lte) {
    condiciones.push({ creadoEn: fecha });
  }

  return condiciones.length ? { AND: condiciones } : {};
};

export const listarMovimientos = async (filtros: FiltrosHistorial) => {
  const limite = filtros.limite && filtros.limite > 0 ? filtros.limite : 100;
  const pagina = filtros.pagina && filtros.pagina > 0 ? filtros.pagina : 1;
  const saltar = (pagina - 1) * limite;
  const where = construirWhereMovimientos(filtros);
  const [movimientos, total] = await Promise.all([
    prisma.movimiento.findMany({
      where,
      include: includeMovimientoCompleto,
      orderBy: {
        creadoEn: 'desc'
      },
      take: limite,
      skip: saltar
    }),
    prisma.movimiento.count({ where })
  ]);

  return {
    datos: movimientos.map(mapearMovimiento),
    metadatos: {
      total,
      pagina: pagina,
      limite: limite,
      totalPaginas: Math.ceil(total / limite)
    }
  };
};

export const resumenHistorial = async (filtros: FiltrosHistorial) => {
  if (!puedeVerTodo(filtros.rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para ver el resumen central');
  }

  const where = construirWhereMovimientos(filtros);
  const movimientos = await prisma.movimiento.findMany({
    where,
    include: includeMovimientoCompleto
  });

  const contar = (predicado: (movimiento: MovimientoCompleto) => boolean) =>
    movimientos.filter(predicado).length;
  const agrupar = (selector: (movimiento: MovimientoCompleto) => string) =>
    movimientos.reduce<Record<string, number>>((acumulado, movimiento) => {
      const clave = selector(movimiento);
      acumulado[clave] = (acumulado[clave] ?? 0) + 1;
      return acumulado;
    }, {});

  return {
    totalMovimientos: movimientos.length,
    ingresos: contar((movimiento) => movimiento.tipo === 'INGRESO'),
    retiros: contar((movimiento) => movimiento.tipo === 'RETIRO'),
    confirmados: contar((movimiento) => movimiento.estado === 'CONFIRMADO'),
    denegados: contar((movimiento) => movimiento.estado === 'DENEGADO'),
    manuales: contar((movimiento) => movimiento.origen === 'MANUAL'),
    qr: contar((movimiento) => movimiento.origen === 'QR'),
    movimientosSemana: movimientos.length,
    denegacionesSemana: contar((movimiento) => movimiento.estado === 'DENEGADO'),
    operacionesPorGuardia: agrupar((movimiento) => movimiento.validadoPorGuardia.nombre),
    operacionesPorBicicletero: agrupar((movimiento) => movimiento.bicicletero.nombre)
  };
};

export const opcionesHistorial = async (rol: string) => {
  if (!puedeVerTodo(rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para ver filtros centrales');
  }

  const [bicicleteros, guardias] = await Promise.all([
    prisma.bicicletero.findMany({
      where: {
        activo: true
      },
      orderBy: {
        nombre: 'asc'
      }
    }),
    prisma.usuario.findMany({
      where: {
        rol: RolUsuario.GUARDIA,
        cuentaActiva: true
      },
      orderBy: {
        nombre: 'asc'
      }
    })
  ]);

  return {
    bicicleteros: bicicleteros.map((bicicletero) => ({
      id: bicicletero.id,
      nombre: bicicletero.nombre,
      ubicacion: bicicletero.ubicacion,
      capacidad: bicicletero.capacidad,
      ocupados: 0,
      cuposDisponibles: bicicletero.capacidad,
      porcentajeUso: 0
    })),
    guardias: guardias.map((guardia) => ({
      id: guardia.id,
      nombre: guardia.nombre,
      correo: guardia.correo,
      rut: guardia.rut,
      rol: guardia.rol,
      correoVerificado: guardia.correoVerificado,
      registroParcial: guardia.registroParcial,
      cuentaActiva: guardia.cuentaActiva
    }))
  };
};
