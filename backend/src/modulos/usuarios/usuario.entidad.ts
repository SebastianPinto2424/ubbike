import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn
} from 'typeorm';
import { AsignacionGuardia } from '../acceso/asignacion-guardia.entidad';
import { SolicitudGuardia } from '../acceso/solicitud-guardia.entidad';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Movimiento } from '../historial/movimiento.entidad';
import { Incidencia } from '../incidencias/incidencia.entidad';
import { Notificacion } from '../notificaciones/notificacion.entidad';
import { RolUsuario } from './rol-usuario';

@Entity('usuarios')
export class Usuario {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 120 })
  nombre!: string;

  @Column({ length: 160, unique: true })
  correo!: string;

  @Column({ type: 'varchar', length: 20, unique: true, nullable: true })
  rut!: string | null;

  @Column({
    type: 'enum',
    enum: RolUsuario,
    default: RolUsuario.ESTUDIANTE
  })
  rol!: RolUsuario;

  @Column({ name: 'contrasena_hash', length: 255 })
  contrasenaHash!: string;

  @Column({ name: 'correo_verificado', default: false })
  correoVerificado!: boolean;

  @Column({ name: 'cuenta_activa', default: true })
  cuentaActiva!: boolean;

  @Column({ name: 'version_sesion', default: 0 })
  versionSesion!: number;

  @Column({
    name: 'token_verificacion_correo',
    type: 'varchar',
    length: 120,
    nullable: true
  })
  tokenVerificacionCorreo!: string | null;

  @Column({
    name: 'token_cambio_contrasena',
    type: 'varchar',
    length: 120,
    nullable: true
  })
  tokenCambioContrasena!: string | null;

  @Column({
    name: 'token_cambio_contrasena_expira_en',
    type: 'timestamp with time zone',
    nullable: true
  })
  tokenCambioContrasenaExpiraEn!: Date | null;

  @OneToMany(() => Bicicleta, (bicicleta) => bicicleta.usuario)
  bicicletas!: Bicicleta[];

  @OneToMany(() => AsignacionGuardia, (asignacion) => asignacion.guardia)
  asignacionesGuardia!: AsignacionGuardia[];

  @OneToMany(() => SolicitudGuardia, (solicitud) => solicitud.solicitadaPorUsuario)
  solicitudesGuardiaCreadas!: SolicitudGuardia[];

  @OneToMany(() => SolicitudGuardia, (solicitud) => solicitud.guardiaAsignado)
  solicitudesGuardiaAsignadas!: SolicitudGuardia[];

  @OneToMany(() => Movimiento, (movimiento) => movimiento.usuario)
  movimientos!: Movimiento[];

  @OneToMany(() => Movimiento, (movimiento) => movimiento.validadoPorGuardia)
  movimientosValidados!: Movimiento[];

  @OneToMany(() => Incidencia, (incidencia) => incidencia.usuario)
  incidencias!: Incidencia[];

  @OneToMany(() => Notificacion, (notificacion) => notificacion.usuario)
  notificaciones!: Notificacion[];

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;

  @UpdateDateColumn({ name: 'actualizado_en' })
  actualizadoEn!: Date;
}
