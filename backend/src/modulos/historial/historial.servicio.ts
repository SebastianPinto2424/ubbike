import { ErrorHttp } from '../../comun/errors/error-http';
import { prisma } from '../../configuracion/prisma';
import { Prisma } from '../../generated/prisma/client';
import { RolUsuario } from '../usuarios/rol-usuario';

type FiltrosHistorial = {
  usuarioId: string;
  rol: string;
  q?: string;
  periodo?: 'DIA' | 'SEMANA' | 'MES' | 'ANIO';
  tipo?: 'INGRESO' | 'SALIDA' | 'TODOS';
  estado?: 'CONFIRMADO' | 'DENEGADO' | 'TODOS';
  bicicleteroId?: string;
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

const mapearMovimiento = (movimiento: MovimientoCompleto) => ({
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

export const listarMovimientos = async (filtros: FiltrosHistorial) => {
  const limite = filtros.limite && filtros.limite > 0 ? filtros.limite : 100;
  const pagina = filtros.pagina && filtros.pagina > 0 ? filtros.pagina : 1;
  const saltar = (pagina - 1) * limite;
  const condiciones: Prisma.MovimientoWhereInput[] = [];

  if (filtros.rol === RolUsuario.GUARDIA) {
    condiciones.push({ validadoPorGuardiaId: filtros.usuarioId });
  } else if (!puedeVerTodo(filtros.rol)) {
    condiciones.push({ usuarioId: filtros.usuarioId });
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

  if (filtros.bicicleteroId) {
    condiciones.push({ bicicleteroId: filtros.bicicleteroId });
  }

  const desde = inicioPeriodo(filtros.periodo);

  if (desde) {
    condiciones.push({ creadoEn: { gte: desde } });
  }

  const where: Prisma.MovimientoWhereInput = condiciones.length ? { AND: condiciones } : {};
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

export const resumenHistorial = async (_usuarioId: string, rol: string) => {
  if (!puedeVerTodo(rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para ver el resumen central');
  }

  const movimientos = await prisma.movimiento.findMany({
    include: includeMovimientoCompleto
  });

  const semana = inicioPeriodo('SEMANA')!;
  const movimientosSemana = movimientos.filter((movimiento) => movimiento.creadoEn >= semana);

  return {
    movimientosSemana: movimientosSemana.length,
    denegacionesSemana: movimientosSemana.filter((movimiento) => movimiento.estado === 'DENEGADO')
      .length,
    operacionesPorGuardia: movimientosSemana.reduce<Record<string, number>>(
      (acumulado, movimiento) => {
        const nombre = movimiento.validadoPorGuardia.nombre;
        acumulado[nombre] = (acumulado[nombre] ?? 0) + 1;
        return acumulado;
      },
      {}
    )
  };
};
