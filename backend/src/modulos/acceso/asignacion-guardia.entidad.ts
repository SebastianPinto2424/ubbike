import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn
} from 'typeorm';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { Usuario } from '../usuarios/usuario.entidad';

@Entity('asignaciones_guardias')
export class AsignacionGuardia {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.asignacionesGuardia, {
    nullable: false
  })
  @JoinColumn({ name: 'guardia_id' })
  guardia!: Usuario;

  @ManyToOne(() => Bicicletero, (bicicletero) => bicicletero.asignacionesGuardia, {
    nullable: false
  })
  @JoinColumn({ name: 'bicicletero_id' })
  bicicletero!: Bicicletero;

  @Column({ name: 'inicia_en', type: 'timestamp with time zone' })
  iniciaEn!: Date;

  @Column({ name: 'termina_en', type: 'timestamp with time zone', nullable: true })
  terminaEn!: Date | null;

  @Column({ default: true })
  activa!: boolean;

  @CreateDateColumn({ name: 'creada_en' })
  creadaEn!: Date;

  @UpdateDateColumn({ name: 'actualizada_en' })
  actualizadaEn!: Date;
}
