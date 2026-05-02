import dotenv from 'dotenv';

dotenv.config();

const convertirNumero = (valor: string | undefined, valorPorDefecto: number): number => {
  const valorConvertido = Number(valor);
  return Number.isNaN(valorConvertido) ? valorPorDefecto : valorConvertido;
};

const convertirBooleano = (valor: string | undefined, valorPorDefecto: boolean): boolean => {
  if (valor === undefined) {
    return valorPorDefecto;
  }

  return ['true', '1', 'yes', 'si'].includes(valor.toLowerCase());
};

export const entorno = {
  ambiente: process.env.NODE_ENV ?? 'development',
  puerto: convertirNumero(process.env.PORT, 3000),
  baseDatos: {
    host: process.env.DB_HOST ?? 'localhost',
    puerto: convertirNumero(process.env.DB_PORT, 5432),
    usuario: process.env.DB_USER ?? 'ubbike',
    contrasena: process.env.DB_PASSWORD ?? 'ubbike',
    nombre: process.env.DB_NAME ?? 'ubbike',
    sincronizar: convertirBooleano(process.env.DB_SYNCHRONIZE, true)
  },
  jwt: {
    secreto: process.env.JWT_SECRET ?? 'cambiar-este-secreto-en-produccion',
    expiracion: process.env.JWT_EXPIRES_IN ?? '8h'
  },
  correo: {
    host: process.env.SMTP_HOST,
    puerto: convertirNumero(process.env.SMTP_PORT, 1025),
    seguro: convertirBooleano(process.env.SMTP_SECURE, false),
    usuario: process.env.SMTP_USER,
    contrasena: process.env.SMTP_PASSWORD,
    remitente: process.env.MAIL_FROM ?? 'UBBike <no-reply@ubbike.local>'
  },
  app: {
    urlFrontend: process.env.FRONTEND_URL ?? 'http://localhost:8081'
  }
};
