part of '../pantalla_principal.dart';

class VistaEscanerQrGuardia extends StatefulWidget {
  const VistaEscanerQrGuardia({super.key});

  @override
  State<VistaEscanerQrGuardia> createState() => _VistaEscanerQrGuardiaState();
}

class _VistaEscanerQrGuardiaState extends State<VistaEscanerQrGuardia> {
  final accesoApi = AccesoApi();
  final tokenController = TextEditingController();
  QrValidadoApp? qrLeido;
  bool cargando = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrLeido;

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Escanear QR',
          detalle:
              'Despues de leer el QR, confirma o deniega indicando motivo.',
          icono: Icons.qr_code_scanner,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulOscuro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 88),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Token QR escaneado',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: cargando ? null : _validarQr,
                  icon: cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(cargando ? 'Validando...' : 'Validar QR'),
                ),
              ],
            ),
          ),
        ),
        if (qr != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ChipEstado(texto: 'QR valido', color: ColoresUbb.exito),
                  const SizedBox(height: 16),
                  _FilaDato(etiqueta: 'Usuario', valor: qr.usuarioNombre),
                  _FilaDato(etiqueta: 'RUT', valor: qr.usuarioRut ?? 'Sin RUT'),
                  _FilaDato(etiqueta: 'Correo', valor: qr.usuarioCorreo),
                  _FilaDato(
                    etiqueta: 'Operacion',
                    valor: qr.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro',
                  ),
                  _FilaDato(
                    etiqueta: 'Bicicleta',
                    valor: qr.bicicletaDescripcion,
                  ),
                  _FilaDato(
                    etiqueta: 'Bicicletero',
                    valor: qr.bicicleteroNombre ?? 'Asignacion del guardia',
                  ),
                  const SizedBox(height: 14),
                  _FichaVerificacionBicicleta(qr: qr),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _confirmarQr(qr),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      qr.tipo == 'INGRESO'
                          ? 'Confirmar ingreso'
                          : 'Confirmar retiro',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarDenegacion(context, qr),
                    icon: const Icon(Icons.block_outlined),
                    label: Text(
                      qr.tipo == 'INGRESO'
                          ? 'Denegar ingreso'
                          : 'Denegar retiro',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _validarQr() async {
    if (tokenController.text.trim().isEmpty) {
      return;
    }

    setState(() => cargando = true);

    try {
      final qr = await accesoApi.validarQr(tokenController.text.trim());
      if (mounted) {
        setState(() => qrLeido = qr);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() => qrLeido = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _confirmarQr(QrValidadoApp qr) async {
    try {
      final movimiento = await accesoApi.confirmarQr(qr.token);
      if (mounted) {
        setState(() => qrLeido = null);
        tokenController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} confirmado',
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
    }
  }

  void _mostrarDenegacion(BuildContext context, QrValidadoApp qr) {
    final motivoController = TextEditingController();
    final mensajero = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (contextoHoja) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(contextoHoja).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Motivo de denegacion',
                  style: Theme.of(contextoHoja)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Indica el motivo',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await accesoApi.denegarQr(
                        token: qr.token,
                        motivo: motivoController.text.trim(),
                      );
                      if (contextoHoja.mounted) {
                        Navigator.pop(contextoHoja);
                      }
                      if (mounted) {
                        setState(() => qrLeido = null);
                        tokenController.clear();
                        mensajero.showSnackBar(
                          const SnackBar(content: Text('Operacion denegada')),
                        );
                      }
                    } on ExcepcionApi catch (error) {
                      if (contextoHoja.mounted) {
                        ScaffoldMessenger.of(contextoHoja).showSnackBar(
                          SnackBar(content: Text(error.mensaje)),
                        );
                      }
                    } catch (_) {
                      if (contextoHoja.mounted) {
                        ScaffoldMessenger.of(contextoHoja).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo conectar con el backend'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Registrar denegacion'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(motivoController.dispose);
  }
}

class _FichaVerificacionBicicleta extends StatelessWidget {
  const _FichaVerificacionBicicleta({required this.qr});

  final QrValidadoApp qr;

  @override
  Widget build(BuildContext context) {
    final foto = qr.bicicletaFotoUrl;
    final bytesFoto = _decodificarFotoDataUrl(foto);
    final detalles = <Widget>[
      if (qr.bicicletaMarca?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaMarca!, color: ColoresUbb.azulApp),
      if (qr.bicicletaModelo?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaModelo!, color: ColoresUbb.azulMedio),
      if (qr.bicicletaColor?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaColor!, color: ColoresUbb.turquesa),
      if (qr.bicicletaAro?.isNotEmpty == true)
        ChipEstado(texto: 'Aro ${qr.bicicletaAro}', color: ColoresUbb.exito),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verificacion de bicicleta',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final contenido = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qr.bicicletaDescripcion,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (detalles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: detalles),
                  ],
                  if (qr.bicicletaNumeroSerie?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _FilaDato(
                      etiqueta: 'Serie',
                      valor: qr.bicicletaNumeroSerie!,
                    ),
                  ],
                ],
              );

              final fotoWidget = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: bytesFoto != null
                      ? Image.memory(
                          bytesFoto,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: ColoresUbb.superficie,
                          child: const Icon(
                            Icons.pedal_bike_outlined,
                            color: ColoresUbb.azulApp,
                            size: 48,
                          ),
                        ),
                ),
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: fotoWidget),
                    const SizedBox(height: 12),
                    contenido,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fotoWidget,
                  const SizedBox(width: 14),
                  Expanded(child: contenido),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
