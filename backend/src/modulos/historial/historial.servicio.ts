import { ErrorHttp } from '../../comun/errors/error-http';
import { fuenteDatos } from '../../configuracion/base-datos';
import { RolUsuario } from '../usuarios/rol-usuario';
import { Movimiento } from './movimiento.entidad';

type FiltrosHistorial = {
  usuarioId: string;
  rol: string;
  q?: string;
  periodo?: 'DIA' | 'SEMANA' | 'MES';
};

const repoMovimientos = () => fuenteDatos.getRepository(Movimiento);

const inicioPeriodo = (periodo?: 'DIA' | 'SEMANA' | 'MES') => {
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

  return fecha;
};

const puedeVerTodo = (rol: string) =>
  [RolUsuario.ADMIN_CENTRAL, RolUsuario.ADMINISTRADOR].includes(rol as RolUsuario);

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

export const listarMovimientos = async (filtros: FiltrosHistorial) => {
  const consulta = repoMovimientos()
    .createQueryBuilder('movimiento')
    .leftJoinAndSelect('movimiento.usuario', 'usuario')
    .leftJoinAndSelect('movimiento.bicicleta', 'bicicleta')
    .leftJoinAndSelect('movimiento.bicicletero', 'bicicletero')
    .leftJoinAndSelect('movimiento.validadoPorGuardia', 'guardia')
    .orderBy('movimiento.creadoEn', 'DESC')
    .take(100);

  if (filtros.rol === RolUsuario.GUARDIA) {
    consulta.andWhere('guardia.id = :usuarioId', {
      usuarioId: filtros.usuarioId
    });
  } else if (!puedeVerTodo(filtros.rol)) {
    consulta.andWhere('usuario.id = :usuarioId', {
      usuarioId: filtros.usuarioId
    });
  }

  if (filtros.q) {
    const q = `%${filtros.q.toLowerCase()}%`;
    consulta.andWhere(
      '(LOWER(usuario.nombre) LIKE :q OR LOWER(usuario.correo) LIKE :q OR LOWER(COALESCE(usuario.rut, \'\')) LIKE :q OR LOWER(guardia.nombre) LIKE :q)',
      { q }
    );
  }

  const desde = inicioPeriodo(filtros.periodo);

  if (desde) {
    consulta.andWhere('movimiento.creadoEn >= :desde', { desde });
  }

  const movimientos = await consulta.getMany();
  return movimientos.map(mapearMovimiento);
};

export const resumenHistorial = async (usuarioId: string, rol: string) => {
  if (!puedeVerTodo(rol)) {
    throw new ErrorHttp(403, 'No tienes permisos para ver el resumen central');
  }

  const movimientos = await repoMovimientos().find({
    relations: {
      usuario: true,
      bicicleta: true,
      bicicletero: true,
      validadoPorGuardia: true
    }
  });

  const semana = inicioPeriodo('SEMANA')!;
  const movimientosSemana = movimientos.filter(
    (movimiento) => movimiento.creadoEn >= semana
  );

  return {
    movimientosSemana: movimientosSemana.length,
    denegacionesSemana: movimientosSemana.filter(
      (movimiento) => movimiento.estado === 'DENEGADO'
    ).length,
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
