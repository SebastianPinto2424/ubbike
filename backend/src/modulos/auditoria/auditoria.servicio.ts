import { fuenteDatos } from '../../configuracion/base-datos';
import { Usuario } from '../usuarios/usuario.entidad';
import { AuditoriaEvento } from './auditoria.entidad';

type DatosAuditoria = {
  actorUsuarioId?: string | null;
  accion: string;
  entidad: string;
  entidadId?: string | null;
  ip?: string | null;
  userAgent?: string | null;
  datos?: Record<string, unknown> | null;
};

const repositorioAuditoria = () => fuenteDatos.getRepository(AuditoriaEvento);

export const registrarAuditoria = async (datos: DatosAuditoria): Promise<void> => {
  try {
    if (!fuenteDatos.isInitialized) {
      return;
    }

    await repositorioAuditoria().save(
      repositorioAuditoria().create({
        actorUsuario: datos.actorUsuarioId ? ({ id: datos.actorUsuarioId } as Usuario) : null,
        accion: datos.accion,
        entidad: datos.entidad,
        entidadId: datos.entidadId ?? null,
        ip: datos.ip ?? null,
        userAgent: datos.userAgent ?? null,
        datos: datos.datos ?? null
      })
    );
  } catch (error) {
    console.error('No se pudo registrar evento de auditoria', error);
  }
};
