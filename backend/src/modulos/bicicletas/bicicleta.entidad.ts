import {
  Column,
  CreateDateColumn,
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

  @Column({ name: 'foto_url', type: 'varchar', length: 500, nullable: true })
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
}
