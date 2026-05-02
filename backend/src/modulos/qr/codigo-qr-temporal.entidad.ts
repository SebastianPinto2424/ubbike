import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn
} from 'typeorm';
import { Bicicleta } from '../bicicletas/bicicleta.entidad';
import { Bicicletero } from '../bicicleteros/bicicletero.entidad';
import { TipoMovimiento } from '../historial/tipo-movimiento';
import { Usuario } from '../usuarios/usuario.entidad';

@Entity('codigos_qr_temporales')
export class CodigoQrTemporal {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 160, unique: true })
  token!: string;

  @ManyToOne(() => Usuario, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'usuario_id' })
  usuario!: Usuario;

  @ManyToOne(() => Bicicleta, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bicicleta_id' })
  bicicleta!: Bicicleta;

  @ManyToOne(() => Bicicletero, { nullable: true })
  @JoinColumn({ name: 'bicicletero_id' })
  bicicletero!: Bicicletero | null;

  @Column({
    type: 'enum',
    enum: TipoMovimiento
  })
  tipo!: TipoMovimiento;

  @Column({ name: 'expira_en', type: 'timestamp with time zone' })
  expiraEn!: Date;

  @Column({ default: false })
  usado!: boolean;

  @CreateDateColumn({ name: 'creado_en' })
  creadoEn!: Date;
}
