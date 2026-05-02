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
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Usuario } from '../usuarios/usuario.entidad';
import { EstadoIncidencia } from './estado-incidencia';

@Entity('incidencias')
export class Incidencia {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Usuario, (usuario) => usuario.incidencias, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @ManyToOne(() => Bicicletero, (bicicletero) => bicicletero.incidencias, {
    nullable: false
  })
  @JoinColumn({ name: 'bicicletero_id' })
  bicicletero!: Bicicletero;

  @ManyToOne(() => Bicicleta, (bicicleta) => bicicleta.incidencias, {
    nullable: true
  })
  @JoinColumn({ name: 'bicicleta_id' })
  bicicleta!: Bicicleta | null;

  @Column({ type: 'text' })
  descripcion!: string;

  @Column({
    type: 'enum',
    enum: EstadoIncidencia,
    default: EstadoIncidencia.PENDIENTE
  })
  estado!: EstadoIncidencia;

  @CreateDateColumn({ name: 'creada_en' })
  creadaEn!: Date;

  @UpdateDateColumn({ name: 'actualizada_en' })
  actualizadaEn!: Date;
}
