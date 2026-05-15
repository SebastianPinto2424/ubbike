export const TipoNotificacion = {
  SISTEMA: 'SISTEMA',
  CUENTA: 'CUENTA',
  SEGURIDAD: 'SEGURIDAD',
  SOLICITUD_GUARDIA: 'SOLICITUD_GUARDIA',
  MOVIMIENTO: 'MOVIMIENTO'
} as const;

export type TipoNotificacion = (typeof TipoNotificacion)[keyof typeof TipoNotificacion];
