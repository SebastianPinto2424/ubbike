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
import { Movimiento } from '../historial/movimiento.entidad';
import { Incidencia } from '../incidencias/incidencia.entidad';

@Entity('bicicleteros')
export class Bicicletero {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 120, unique: true })
  nombre!: string;

  @Column({ length: 255 })
  ubicacion!: string;

  @Column({ default: 80 })
  capacidad!: number;

  @Column({ default: true })
  activo!: boolean;

  @OneToMany(() => AsignacionGuardia, (asignacion) => asignacion.bicicletero)
  asignacionesGuardia!: AsignacionGuardia[];

  @OneToMany(() => SolicitudGuardia, (solicitud) => solicitud.bicicletero)
  solicitudesGuardia!: SolicitudGuardia[];

  @OneToMany(() => Movimiento, (movimiento) => movimiento.bicicletero)
  movimientos!: Movimiento[];

  @OneToMany(() => Incidencia, (incidencia) => incidencia.bicicletero)
  incidencias!: Incidencia[];

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;

  @UpdateDateColumn({ name: 'actualizado_en' })
  actualizadoEn!: Date;
}
