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

const separarLista = (valor: string | undefined, valorPorDefecto: string[]): string[] => {
  if (!valor) {
    return valorPorDefecto;
  }

  return valor
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
};

const ambiente = process.env.NODE_ENV ?? 'development';
const secretoJwt = process.env.JWT_SECRET ?? 'cambiar-este-secreto-en-produccion';
const contrasenaBaseDatos = process.env.DB_PASSWORD ?? '';

if (
  secretoJwt === 'cambiar-este-secreto-en-produccion' ||
  secretoJwt.includes('REEMPLAZAR') ||
  secretoJwt.length < 32
) {
  throw new Error('JWT_SECRET debe ser seguro y tener al menos 32 caracteres');
}

if (!contrasenaBaseDatos || contrasenaBaseDatos === 'ubbike' || contrasenaBaseDatos.length < 16) {
  throw new Error('DB_PASSWORD debe ser seguro y tener al menos 16 caracteres');
}

export const entorno = {
  ambiente,
  puerto: convertirNumero(process.env.PORT, 3000),
  baseDatos: {
    host: process.env.DB_HOST ?? 'localhost',
    puerto: convertirNumero(process.env.DB_PORT, 5432),
    usuario: process.env.DB_USER ?? 'ubbike',
    contrasena: contrasenaBaseDatos,
    nombre: process.env.DB_NAME ?? 'ubbike',
    sincronizar: convertirBooleano(
      process.env.DB_SYNCHRONIZE,
      process.env.NODE_ENV !== 'production'
    )
  },
  jwt: {
    secreto: secretoJwt,
    expiracion: process.env.JWT_EXPIRES_IN ?? '2h',
    emisor: process.env.JWT_ISSUER ?? 'ubbike-api',
    audiencia: process.env.JWT_AUDIENCE ?? 'ubbike-app'
  },
  cors: {
    origenes: separarLista(process.env.CORS_ORIGINS, [
      'http://localhost:8081',
      'http://127.0.0.1:8081'
    ])
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
  },
  datosDemo: {
    habilitados: convertirBooleano(process.env.SEED_DEMO_DATA, ambiente !== 'production')
  }
};
