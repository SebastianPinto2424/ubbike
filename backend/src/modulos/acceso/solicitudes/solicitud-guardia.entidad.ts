import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn
} from 'typeorm';
import { Bicicletero } from '../../bicicleteros/bicicletero.entidad';
import { Usuario } from '../../usuarios/usuario.entidad';
import { EstadoSolicitudGuardia } from './estado-solicitud-guardia';
import { TipoSolicitudGuardia } from './tipo-solicitud-guardia';

@Entity('solicitudes_guardia')
export class SolicitudGuardia {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.solicitudesGuardiaCreadas, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'solicitada_por_usuario_id' })
  solicitadaPorUsuario!: Usuario;

  @ManyToOne(() => Bicicletero, (bicicletero) => bicicletero.solicitudesGuardia, {
    nullable: false
  })
  @JoinColumn({ name: 'bicicletero_id' })
  bicicletero!: Bicicletero;

  @ManyToOne(() => Usuario, (usuario) => usuario.solicitudesGuardiaAsignadas, {
    nullable: true
  })
  @JoinColumn({ name: 'guardia_asignado_id' })
  guardiaAsignado!: Usuario | null;

  @Column({
    type: 'enum',
    enum: TipoSolicitudGuardia
  })
  tipo!: TipoSolicitudGuardia;

  @Column({
    type: 'enum',
    enum: EstadoSolicitudGuardia,
    default: EstadoSolicitudGuardia.PENDIENTE
  })
  estado!: EstadoSolicitudGuardia;

  @Column({ type: 'text', nullable: true })
  mensaje!: string | null;

  @Column({ name: 'notificada_guardia_en', type: 'timestamp with time zone', nullable: true })
  notificadaGuardiaEn!: Date | null;

  @Column({ name: 'acuse_recibo_en', type: 'timestamp with time zone', nullable: true })
  acuseReciboEn!: Date | null;

  @Column({ name: 'resuelta_en', type: 'timestamp with time zone', nullable: true })
  resueltaEn!: Date | null;

  @CreateDateColumn({ name: 'creada_en' })
  creadaEn!: Date;

  @UpdateDateColumn({ name: 'actualizada_en' })
  actualizadaEn!: Date;
}
