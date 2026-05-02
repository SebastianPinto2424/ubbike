import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entidad';
import { TipoNotificacion } from './tipo-notificacion';

@Entity('notificaciones')
export class Notificacion {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.notificaciones, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ length: 120 })
  titulo!: string;

  @Column({ type: 'text' })
  mensaje!: string;

  @Column({
    type: 'enum',
    enum: TipoNotificacion,
    default: TipoNotificacion.SISTEMA
  })
  tipo!: TipoNotificacion;

  @Column({ default: false })
  leida!: boolean;

  @Column({ type: 'jsonb', nullable: true })
  datos!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'creada_en' })
  creadaEn!: Date;
}
