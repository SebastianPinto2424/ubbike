import 'reflect-metadata';
import { aplicacion } from './aplicacion';
import { fuenteDatos } from './configuracion/base-datos';
import { cargarDatosIniciales } from './configuracion/datos-iniciales';
import { ejecutarMigraciones } from './configuracion/ejecutar-migraciones';
import { entorno } from './configuracion/entorno';
import { prepararCompatibilidadRoles } from './configuracion/migracion-roles';

const iniciarServidor = async (): Promise<void> => {
  try {
    await prepararCompatibilidadRoles();
    await ejecutarMigraciones();
    await fuenteDatos.initialize();
    if (entorno.datosDemo.habilitados) {
      await cargarDatosIniciales();
    }

    aplicacion.listen(entorno.puerto, () => {
      console.log(`UBBike backend escuchando en puerto ${entorno.puerto}`);
    });
  } catch (error) {
    console.error('No se pudo iniciar el backend de UBBike', error);
    process.exit(1);
  }
};

void iniciarServidor();
