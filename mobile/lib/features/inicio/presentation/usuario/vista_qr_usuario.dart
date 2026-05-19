part of '../pantalla_principal.dart';

class VistaQrUsuario extends StatefulWidget {
  const VistaQrUsuario({super.key});

  @override
  State<VistaQrUsuario> createState() => _VistaQrUsuarioState();
}

class _VistaQrUsuarioState extends State<VistaQrUsuario> {
  final qrApi = QrApi();
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  QrTemporalApp? qrActual;
  BicicletaApp? bicicletaActiva;
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  bool cargandoDatos = true;
  bool generando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        bicicletaApi.obtenerActiva(),
        solicitudGuardiaApi.listarBicicleteros(),
      ]);

      if (mounted) {
        final bicicleta = resultados[0] as BicicletaApp?;
        final listaBicicleteros = resultados[1] as List<BicicleteroApp>;
        setState(() {
          bicicletaActiva = bicicleta;
          bicicleteros = listaBicicleteros;
          bicicleteroSeleccionado = listaBicicleteros.isEmpty
              ? null
              : listaBicicleteros.firstWhere(
                  (item) => item.cuposDisponibles > 0,
                  orElse: () => listaBicicleteros.first,
                );
          cargandoDatos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => cargandoDatos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrActual;
    final segundosRestantes = qr == null
        ? 0
        : qr.expiraEn.difference(DateTime.now()).inSeconds.clamp(0, 15);
    final bicicleta = bicicletaActiva;
    final tipoOperacion =
        bicicleta?.dentroBicicletero == true ? 'RETIRO' : 'INGRESO';
    final debeSeleccionarBicicletero = tipoOperacion == 'INGRESO';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _EncabezadoSeccion(
          titulo: 'QR temporal',
          detalle:
              'La app detecta automaticamente si corresponde ingreso o retiro.',
          icono: Icons.qr_code_2,
        ),
        const SizedBox(height: 24),
        if (cargandoDatos)
          const Center(child: CircularProgressIndicator())
        else if (bicicleta == null)
          const _EstadoLista(
            icono: Icons.pedal_bike,
            titulo: 'Sin bicicleta activa',
            detalle: 'Activa una bicicleta antes de generar QR.',
          )
        else ...[
          if (debeSeleccionarBicicletero)
            Container(
              decoration: BoxDecoration(
                color: ColoresUbb.azulApp.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<BicicleteroApp>(
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                menuMaxHeight: 300,
                initialValue: bicicleteroSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Bicicletero a usar',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: ColoresUbb.azulApp),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                dropdownColor: Colors.white,
                items: bicicleteros
                    .map(
                      (bicicletero) => DropdownMenuItem(
                        value: bicicletero,
                        child: Text(
                          '${bicicletero.nombre} (${bicicletero.cuposDisponibles} cupos)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (valor) =>
                    setState(() => bicicleteroSeleccionado = valor),
              ),
            ),
          const SizedBox(height: 24),
          if (qr == null)
            const _EstadoLista(
              icono: Icons.qr_code_2,
              titulo: 'QR no generado',
              detalle: 'Selecciona el bicicletero y genera el codigo.',
            )
          else
            Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    _QrTemporal(
                      token: qr.token,
                      segundosRestantes: segundosRestantes,
                    ),
                    const SizedBox(height: 24),
                    ChipEstado(
                      texto: segundosRestantes > 0
                          ? 'Expira en $segundosRestantes s'
                          : 'QR expirado',
                      color: segundosRestantes > 0
                          ? ColoresUbb.azulApp
                          : ColoresUbb.rojoInstitucional,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: ColoresUbb.azulApp,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: generando ||
                    cargandoDatos ||
                    (debeSeleccionarBicicletero &&
                        bicicleteroSeleccionado == null)
                ? null
                : _generarQr,
            icon: generando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              qr == null || segundosRestantes == 0
                  ? 'Generar QR'
                  : 'Regenerar QR',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          if (qr != null) ...[
            const SizedBox(height: 24),
            Center(
              child: SelectableText(
                'Token de prueba: ${qr.token}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColoresUbb.textoSecundario.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _generarQr() async {
    setState(() => generando = true);

    try {
      final tipo =
          bicicletaActiva?.dentroBicicletero == true ? 'RETIRO' : 'INGRESO';
      final qr = await qrApi.generar(
        bicicleteroId: tipo == 'INGRESO' ? bicicleteroSeleccionado?.id : null,
      );

      if (mounted) {
        setState(() => qrActual = qr);
        _programarActualizacion();
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => generando = false);
      }
    }
  }

  void _programarActualizacion() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || qrActual == null) {
        return;
      }

      setState(() {});

      if (qrActual!.expiraEn.isAfter(DateTime.now())) {
        _programarActualizacion();
      }
    });
  }
}
