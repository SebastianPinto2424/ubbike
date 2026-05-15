export const TipoMovimiento = {
  INGRESO: 'INGRESO',
  SALIDA: 'SALIDA'
} as const;

export type TipoMovimiento = (typeof TipoMovimiento)[keyof typeof TipoMovimiento];
