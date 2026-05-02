import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn
} from 'typeorm';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Usuario } from '../usuarios/usuario.entidad';
import { EstadoMovimiento } from './estado-movimiento';
import { TipoMovimiento } from './tipo-movimiento';

@Entity('movimientos')
export class Movimiento {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Bicicleta, (bicicleta) => bicicleta.movimientos, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'bicicleta_id' })
  bicicleta!: Bicicleta;

  @ManyToOne(() => Usuario, (usuario) => usuario.movimientos, {
    nullable: false,
    onDelete: 'CASCADE'
  })
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @ManyToOne(() => Bicicletero, (bicicletero) => bicicletero.movimientos, {
    nullable: false
  })
  @JoinColumn({ name: 'bicicletero_id' })
  bicicletero!: Bicicletero;

  @ManyToOne(() => Usuario, (usuario) => usuario.movimientosValidados, {
    nullable: false
  })
  @JoinColumn({ name: 'validado_por_guardia_id' })
  validadoPorGuardia!: Usuario;

  @Column({
    type: 'enum',
    enum: TipoMovimiento
  })
  tipo!: TipoMovimiento;

  @Column({
    type: 'enum',
    enum: EstadoMovimiento,
    default: EstadoMovimiento.CONFIRMADO
  })
  estado!: EstadoMovimiento;

  @Column({ name: 'motivo_denegacion', type: 'text', nullable: true })
  motivoDenegacion!: string | null;

  @Column({ name: 'origen', type: 'varchar', length: 30, default: 'QR' })
  origen!: 'QR' | 'MANUAL';

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;
}
