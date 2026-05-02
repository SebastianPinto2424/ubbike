import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn
} from 'typeorm';
import { Movimiento } from '../historial/movimiento.entidad';
import { Incidencia } from '../incidencias/incidencia.entidad';
import { Usuario } from '../usuarios/usuario.entidad';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';

@Entity('bicicletas')
export class Bicicleta {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.bicicletas, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @Column({ length: 255 })
  descripcion!: string;

  @Column({ type: 'varchar', length: 80, nullable: true })
  marca!: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  modelo!: string | null;

  @Column({ type: 'varchar', length: 60, nullable: true })
  color!: string | null;

  @Column({ type: 'varchar', length: 30, nullable: true })
  aro!: string | null;

  @Column({ name: 'numero_serie', type: 'varchar', length: 120, nullable: true })
  numeroSerie!: string | null;

  @Column({ name: 'foto_url', type: 'text', nullable: true })
  fotoUrl!: string | null;

  @Column({ default: false })
  activa!: boolean;

  @Column({ name: 'dentro_bicicletero', default: false })
  dentroBicicletero!: boolean;

  @ManyToOne(() => Bicicletero, { nullable: true })
  @JoinColumn({ name: 'bicicletero_actual_id' })
  bicicleteroActual!: Bicicletero | null;

  @OneToMany(() => Movimiento, (movimiento) => movimiento.bicicleta)
  movimientos!: Movimiento[];

  @OneToMany(() => Incidencia, (incidencia) => incidencia.bicicleta)
  incidencias!: Incidencia[];

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;

  @UpdateDateColumn({ name: 'actualizado_en' })
  actualizadoEn!: Date;

  @DeleteDateColumn({ name: 'eliminado_en', nullable: true })
  eliminadoEn!: Date | null;
}
