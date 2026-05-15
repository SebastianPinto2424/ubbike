import bcrypt from 'bcryptjs';
import { fuenteDatos } from './base-datos';
import { AsignacionGuardia } from '../modulos/acceso/asignaciones/asignacion-guardia.entidad';
import { Bicicletero } from '../modulos/bicicleteros/bicicletero.entidad';
import { crearNotificacion } from '../modulos/notificaciones/notificacion.servicio';
import { TipoNotificacion } from '../modulos/notificaciones/tipo-notificacion';
import { RolUsuario } from '../modulos/usuarios/rol-usuario';
import { Usuario } from '../modulos/usuarios/usuario.entidad';

const contrasenaDemo = 'UBBike2026*';

const usuariosDemo = [
  {
    nombre: 'Estudiante UBB',
    correo: 'estudiante@alumnos.ubiobio.cl',
    rut: '20.111.111-1',
    rol: RolUsuario.ESTUDIANTE
  },
  {
    nombre: 'Funcionario UBB',
    correo: 'funcionario@ubiobio.cl',
    rut: '16.222.222-2',
    rol: RolUsuario.FUNCIONARIO
  },
  {
    nombre: 'Guardia Bicicletero',
    correo: 'guardia@ubiobio.cl',
    rut: '13.333.333-3',
    rol: RolUsuario.GUARDIA
  },
  {
    nombre: 'Admin Central Seguridad',
    correo: 'admin.central@ubiobio.cl',
    rut: '12.444.444-4',
    rol: RolUsuario.ADMIN_CENTRAL
  },
  {
    nombre: 'Administrador UBBike',
    correo: 'administrador@ubiobio.cl',
    rut: '11.555.555-5',
    rol: RolUsuario.ADMINISTRADOR
  }
];

const bicicleterosBase = [
  {
    nombre: 'Bicicletero cercano al Centro de Idiomas',
    ubicacion: 'Sector Centro de Idiomas',
    nombresAnteriores: ['Bicicletero Central'],
    capacidad: 80
  },
  {
    nombre: 'Bicicletero cercano a la FACE',
    ubicacion: 'Sector FACE',
    nombresAnteriores: ['Bicicletero Biblioteca'],
    capacidad: 55
  }
];

export const cargarDatosIniciales = async (): Promise<void> => {
  const usuarios = fuenteDatos.getRepository(Usuario);
  const bicicleteros = fuenteDatos.getRepository(Bicicletero);
  const asignaciones = fuenteDatos.getRepository(AsignacionGuardia);
  const contrasenaHash = await bcrypt.hash(contrasenaDemo, 12);

  const centralAnterior = await usuarios.findOneBy({
    correo: 'central.seguridad@ubiobio.cl'
  });

  if (centralAnterior) {
    centralAnterior.nombre = 'Admin Central Seguridad';
    centralAnterior.correo = 'admin.central@ubiobio.cl';
    centralAnterior.rol = RolUsuario.ADMIN_CENTRAL;
    centralAnterior.cuentaActiva = true;
    centralAnterior.correoVerificado = true;
    centralAnterior.tokenVerificacionCorreoExpiraEn = null;
    await usuarios.save(centralAnterior);
  }

  for (const usuarioDemo of usuariosDemo) {
    const existente = await usuarios.findOneBy({ correo: usuarioDemo.correo });

    if (existente) {
      existente.nombre = usuarioDemo.nombre;
      existente.rut = usuarioDemo.rut;
      existente.rol = usuarioDemo.rol;
      existente.cuentaActiva = true;
      existente.correoVerificado = true;
      existente.tokenVerificacionCorreo = null;
      existente.tokenVerificacionCorreoExpiraEn = null;
      await usuarios.save(existente);
      continue;
    }

    const usuario = usuarios.create({
      ...usuarioDemo,
      contrasenaHash,
      cuentaActiva: true,
      correoVerificado: true
    });
    const guardado = await usuarios.save(usuario);

    await crearNotificacion({
      usuarioId: guardado.id,
      titulo: 'Bienvenido a UBBike',
      mensaje: 'Tu cuenta esta lista para usar el sistema.',
      tipo: TipoNotificacion.SISTEMA
    });
  }

  for (const bicicleteroBase of bicicleterosBase) {
    let existente = await bicicleteros.findOneBy({
      nombre: bicicleteroBase.nombre
    });

    for (const nombreAnterior of bicicleteroBase.nombresAnteriores) {
      if (existente) {
        break;
      }
      existente = await bicicleteros.findOneBy({ nombre: nombreAnterior });
    }

    const datosBicicletero = {
      nombre: bicicleteroBase.nombre,
      ubicacion: bicicleteroBase.ubicacion,
      capacidad: bicicleteroBase.capacidad
    };

    if (!existente) {
      await bicicleteros.save(
        bicicleteros.create({
          ...datosBicicletero,
          activo: true
        })
      );
    } else {
      existente.nombre = datosBicicletero.nombre;
      existente.ubicacion = bicicleteroBase.ubicacion;
      existente.capacidad = bicicleteroBase.capacidad;
      existente.activo = true;
      await bicicleteros.save(existente);
    }
  }

  for (const bicicleteroBase of bicicleterosBase) {
    for (const nombreAnterior of bicicleteroBase.nombresAnteriores) {
      const anterior = await bicicleteros.findOneBy({ nombre: nombreAnterior });

      if (anterior) {
        anterior.activo = false;
        await bicicleteros.save(anterior);
      }
    }
  }

  const guardia = await usuarios.findOneBy({ correo: 'guardia@ubiobio.cl' });
  const bicicleteroCentroIdiomas = await bicicleteros.findOneBy({
    nombre: 'Bicicletero cercano al Centro de Idiomas'
  });

  if (guardia && bicicleteroCentroIdiomas) {
    const asignacionExistente = await asignaciones.findOne({
      where: {
        guardia: { id: guardia.id },
        bicicletero: { id: bicicleteroCentroIdiomas.id },
        activa: true
      }
    });

    if (!asignacionExistente) {
      await asignaciones.save(
        asignaciones.create({
          guardia,
          bicicletero: bicicleteroCentroIdiomas,
          iniciaEn: new Date(),
          terminaEn: null,
          activa: true
        })
      );
    }
  }
};
