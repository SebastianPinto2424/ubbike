part of '../pantalla_principal.dart';

class VistaGestionManualGuardia extends StatefulWidget {
  const VistaGestionManualGuardia({super.key});

  @override
  State<VistaGestionManualGuardia> createState() =>
      _VistaGestionManualGuardiaState();
}

class _VistaGestionManualGuardiaState extends State<VistaGestionManualGuardia> {
  final accesoApi = AccesoApi();
  final correoController = TextEditingController();
  final rutController = TextEditingController();
  String operacion = 'INGRESO';
  bool registrando = false;

  @override
  void dispose() {
    correoController.dispose();
    rutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Gestion manual',
          detalle: 'Registra ingreso o retiro cuando el QR no pueda usarse.',
          icono: Icons.edit_note_outlined,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SegmentadoEnLinea<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'INGRESO',
                        label: Text('Ingreso'),
                        icon: Icon(Icons.login)),
                    ButtonSegment(
                        value: 'SALIDA',
                        label: Text('Retiro'),
                        icon: Icon(Icons.logout)),
                  ],
                  selected: {operacion},
                  onSelectionChanged: (valor) =>
                      setState(() => operacion = valor.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rutController,
                  decoration: const InputDecoration(
                    labelText: 'RUT',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColoresUbb.superficieAzulSuave,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColoresUbb.borde),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: ColoresUbb.azulApp),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Se usara la bicicleta activa del usuario. Si tiene mas de una, debe activarla desde su perfil.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: registrando ? null : _registrarManual,
                  icon: registrando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    registrando
                        ? 'Registrando...'
                        : 'Registrar ${operacion == 'INGRESO' ? 'ingreso' : 'retiro'}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _registrarManual() async {
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();

    if (correo.isEmpty && rut.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo institucional o RUT del usuario'),
        ),
      );
      return;
    }

    setState(() => registrando = true);

    try {
      final movimiento = await accesoApi.registrarManual(
        correo: correo,
        rut: rut,
        tipo: operacion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} registrado para ${movimiento.usuarioNombre}',
            ),
          ),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => registrando = false);
      }
    }
  }
}
