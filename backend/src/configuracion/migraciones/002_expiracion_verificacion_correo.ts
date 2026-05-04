export const migracion002ExpiracionVerificacionCorreo = {
  id: '002_expiracion_verificacion_correo',
  descripcion: 'Agrega expiracion para tokens de verificacion de correo.',
  sql: [
    `
    ALTER TABLE usuarios
      ADD COLUMN IF NOT EXISTS token_verificacion_correo_expira_en timestamp with time zone;
    `,
    `
    UPDATE usuarios
    SET token_verificacion_correo_expira_en = now() + interval '24 hours'
    WHERE token_verificacion_correo IS NOT NULL
      AND correo_verificado = false
      AND token_verificacion_correo_expira_en IS NULL;
    `
  ]
};
