import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn
} from 'typeorm';
import { Usuario } from '../usuarios/usuario.entidad';

@Entity('auditoria_eventos')
export class AuditoriaEvento {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'actor_usuario_id' })
  actorUsuario!: Usuario | null;

  @Column({ length: 120 })
  accion!: string;

  @Column({ length: 120 })
  entidad!: string;

  @Column({ name: 'entidad_id', type: 'varchar', length: 120, nullable: true })
  entidadId!: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  ip!: string | null;

  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  datos!: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;
}
