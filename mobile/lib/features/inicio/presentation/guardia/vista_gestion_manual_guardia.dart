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
  final comentarioController = TextEditingController();
  final bicicletaDescripcionController = TextEditingController();
  final bicicletaMarcaController = TextEditingController();
  final bicicletaModeloController = TextEditingController();
  final bicicletaColorController = TextEditingController();
  final bicicletaAroController = TextEditingController();
  final bicicletaNumeroSerieController = TextEditingController();
  String operacion = 'INGRESO';
  Timer? temporizadorBusqueda;
  CoincidenciaManualApp? coincidenciaManual;
  String? bicicletaSeleccionadaId;
  String? errorBusquedaManual;
  bool buscandoCoincidencia = false;
  bool busquedaRealizada = false;
  bool actualizandoCampos = false;
  bool registrando = false;

  @override
  void initState() {
    super.initState();
    correoController.addListener(_programarBusquedaCoincidencia);
    rutController.addListener(_programarBusquedaCoincidencia);
  }

  @override
  void dispose() {
    temporizadorBusqueda?.cancel();
    correoController.removeListener(_programarBusquedaCoincidencia);
    rutController.removeListener(_programarBusquedaCoincidencia);
    correoController.dispose();
    rutController.dispose();
    comentarioController.dispose();
    bicicletaDescripcionController.dispose();
    bicicletaMarcaController.dispose();
    bicicletaModeloController.dispose();
    bicicletaColorController.dispose();
    bicicletaAroController.dispose();
    bicicletaNumeroSerieController.dispose();
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
                        value: 'RETIRO',
                        label: Text('Retiro'),
                        icon: Icon(Icons.logout)),
                  ],
                  selected: {operacion},
                  onSelectionChanged: (valor) {
                    setState(() => operacion = valor.first);
                    _seleccionarBicicletaSugerida();
                  },
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
                _EstadoBusquedaManual(
                  buscando: buscandoCoincidencia,
                  busquedaRealizada: busquedaRealizada,
                  error: errorBusquedaManual,
                  coincidencia: coincidenciaManual,
                  onUsarDatos:
                      coincidenciaManual == null ? null : _autocompletarDatos,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  leading: const Icon(Icons.pedal_bike_outlined),
                  title: const Text('Datos de bicicleta'),
                  subtitle: Text(
                    bicicletaSeleccionadaId == null
                        ? 'Para usuario nuevo o bicicleta no registrada'
                        : 'Bicicleta registrada seleccionada',
                  ),
                  children: [
                    if ((coincidenciaManual?.bicicletas ?? const [])
                        .isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(bicicletaSeleccionadaId ?? 'sin-bici'),
                        isExpanded: true,
                        initialValue: bicicletaSeleccionadaId,
                        decoration: const InputDecoration(
                          labelText: 'Bicicleta registrada',
                          prefixIcon: Icon(Icons.pedal_bike_outlined),
                        ),
                        items: coincidenciaManual!.bicicletas
                            .map(
                              (bicicleta) => DropdownMenuItem(
                                value: bicicleta.id,
                                child: Text(
                                  _resumenBicicleta(bicicleta),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) => _seleccionarBicicleta(valor),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _usarBicicletaNoRegistrada,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Usar bicicleta no registrada'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: bicicletaDescripcionController,
                      readOnly: bicicletaSeleccionadaId != null,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                        hintText: 'Ej: MTB roja con canasto',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bicicletaMarcaController,
                      readOnly: bicicletaSeleccionadaId != null,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bicicletaModeloController,
                      readOnly: bicicletaSeleccionadaId != null,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        prefixIcon: Icon(Icons.directions_bike_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bicicletaColorController,
                      readOnly: bicicletaSeleccionadaId != null,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.palette_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bicicletaAroController,
                            readOnly: bicicletaSeleccionadaId != null,
                            decoration: const InputDecoration(
                              labelText: 'Aro',
                              prefixIcon: Icon(Icons.radio_button_unchecked),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bicicletaNumeroSerieController,
                            readOnly: bicicletaSeleccionadaId != null,
                            decoration: const InputDecoration(
                              labelText: 'N. serie',
                              prefixIcon: Icon(Icons.confirmation_number),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: comentarioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentario opcional del guardia',
                    hintText: 'Ej: Usuario posee U-Lock',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
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
                          'Si hay coincidencia, selecciona una bicicleta registrada. Si no aparece, completa los datos para crear un ingreso manual.',
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

  void _programarBusquedaCoincidencia() {
    if (actualizandoCampos) {
      return;
    }

    temporizadorBusqueda?.cancel();
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();

    if (correo.isEmpty && rut.isEmpty) {
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = null;
      });
      return;
    }

    if (!_datoBusquedaSuficiente(correo, rut)) {
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = null;
      });
      return;
    }

    setState(() {
      buscandoCoincidencia = true;
      busquedaRealizada = false;
      coincidenciaManual = null;
      bicicletaSeleccionadaId = null;
      errorBusquedaManual = null;
    });

    temporizadorBusqueda = Timer(
      const Duration(milliseconds: 550),
      () => _buscarCoincidencia(correo, rut),
    );
  }

  bool _datoBusquedaSuficiente(String correo, String rut) {
    final rutLimpio = rut.replaceAll('.', '').replaceAll('-', '');
    return correo.contains('@') || rutLimpio.length >= 7;
  }

  Future<void> _buscarCoincidencia(String correo, String rut) async {
    try {
      final coincidencia = await accesoApi.buscarCoincidenciaManual(
        correo: correo,
        rut: rut,
      );

      if (!mounted ||
          correoController.text.trim() != correo ||
          rutController.text.trim() != rut) {
        return;
      }

      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = true;
        coincidenciaManual = coincidencia;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = null;
      });
    } on ExcepcionApi catch (error) {
      if (!mounted) return;
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = true;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = error.mensaje;
      });
    }
  }

  void _autocompletarDatos() {
    final coincidencia = coincidenciaManual;
    if (coincidencia == null) {
      return;
    }

    actualizandoCampos = true;
    correoController.text = coincidencia.usuario.correo;
    rutController.text = coincidencia.usuario.rut ?? rutController.text.trim();
    actualizandoCampos = false;

    _seleccionarBicicletaSugerida();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Datos cargados para ${coincidencia.usuario.nombre}')),
    );
  }

  void _seleccionarBicicletaSugerida() {
    final bicicletas = coincidenciaManual?.bicicletas ?? const <BicicletaApp>[];

    if (bicicletas.isEmpty) {
      setState(() => bicicletaSeleccionadaId = null);
      return;
    }

    final preferida = _bicicletaPreferida(bicicletas);
    _seleccionarBicicleta(preferida.id);
  }

  BicicletaApp _bicicletaPreferida(List<BicicletaApp> bicicletas) {
    if (operacion == 'RETIRO') {
      final dentro =
          bicicletas.where((bicicleta) => bicicleta.dentroBicicletero);
      if (dentro.isNotEmpty) {
        return dentro.first;
      }
    }

    final activas = bicicletas.where((bicicleta) => bicicleta.activa);
    if (activas.isNotEmpty) {
      return activas.first;
    }

    return bicicletas.first;
  }

  BicicletaApp? _buscarBicicletaSeleccionada(String? bicicletaId) {
    if (bicicletaId == null) {
      return null;
    }

    for (final bicicleta
        in coincidenciaManual?.bicicletas ?? const <BicicletaApp>[]) {
      if (bicicleta.id == bicicletaId) {
        return bicicleta;
      }
    }

    return null;
  }

  void _seleccionarBicicleta(String? bicicletaId) {
    final bicicleta = _buscarBicicletaSeleccionada(bicicletaId);

    setState(() {
      bicicletaSeleccionadaId = bicicleta?.id;
      if (bicicleta != null) {
        _cargarDatosBicicleta(bicicleta);
      }
    });
  }

  void _cargarDatosBicicleta(BicicletaApp bicicleta) {
    bicicletaDescripcionController.text = bicicleta.descripcion;
    bicicletaMarcaController.text = bicicleta.marca ?? '';
    bicicletaModeloController.text = bicicleta.modelo ?? '';
    bicicletaColorController.text = bicicleta.color ?? '';
    bicicletaAroController.text = bicicleta.aro ?? '';
    bicicletaNumeroSerieController.text = bicicleta.numeroSerie ?? '';
  }

  void _usarBicicletaNoRegistrada() {
    setState(() {
      bicicletaSeleccionadaId = null;
      bicicletaDescripcionController.clear();
      bicicletaMarcaController.clear();
      bicicletaModeloController.clear();
      bicicletaColorController.clear();
      bicicletaAroController.clear();
      bicicletaNumeroSerieController.clear();
    });
  }

  String _resumenBicicleta(BicicletaApp bicicleta) {
    final estado = bicicleta.dentroBicicletero
        ? 'Dentro${bicicleta.bicicleteroActualNombre == null ? '' : ' - ${bicicleta.bicicleteroActualNombre}'}'
        : 'Fuera';
    final activa = bicicleta.activa ? 'Activa' : 'Inactiva';
    return '${bicicleta.descripcion} | $activa | $estado';
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
        bicicletaId: bicicletaSeleccionadaId,
        tipo: operacion,
        comentario: comentarioController.text.trim(),
        bicicletaDescripcion: bicicletaDescripcionController.text.trim(),
        bicicletaMarca: bicicletaMarcaController.text.trim(),
        bicicletaModelo: bicicletaModeloController.text.trim(),
        bicicletaColor: bicicletaColorController.text.trim(),
        bicicletaAro: bicicletaAroController.text.trim(),
        bicicletaNumeroSerie: bicicletaNumeroSerieController.text.trim(),
      );

      if (mounted) {
        comentarioController.clear();
        bicicletaDescripcionController.clear();
        bicicletaMarcaController.clear();
        bicicletaModeloController.clear();
        bicicletaColorController.clear();
        bicicletaAroController.clear();
        bicicletaNumeroSerieController.clear();
        setState(() {
          bicicletaSeleccionadaId = null;
          coincidenciaManual = null;
          busquedaRealizada = false;
          errorBusquedaManual = null;
        });
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

class _EstadoBusquedaManual extends StatelessWidget {
  const _EstadoBusquedaManual({
    required this.buscando,
    required this.busquedaRealizada,
    required this.coincidencia,
    required this.error,
    required this.onUsarDatos,
  });

  final bool buscando;
  final bool busquedaRealizada;
  final CoincidenciaManualApp? coincidencia;
  final String? error;
  final VoidCallback? onUsarDatos;

  @override
  Widget build(BuildContext context) {
    if (buscando) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
                child: Text('Buscando coincidencias en la base de datos...')),
          ],
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.error_outline,
          color: ColoresUbb.rojoInstitucional,
          children: [Text(error!)],
        ),
      );
    }

    final datos = coincidencia;
    if (datos != null) {
      final cantidadBicicletas = datos.bicicletas.length;
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.manage_search_outlined,
          color: ColoresUbb.exito,
          children: [
            Text(
              'Coincidencia encontrada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            _FilaDato(etiqueta: 'Usuario', valor: datos.usuario.nombre),
            _FilaDato(
              etiqueta: 'Correo',
              valor: datos.usuario.correo,
              anchoCompleto: true,
            ),
            _FilaDato(
              etiqueta: 'RUT',
              valor: datos.usuario.rut ?? 'Sin RUT',
            ),
            _FilaDato(
              etiqueta: 'Bicicletas',
              valor: cantidadBicicletas == 0
                  ? 'Sin bicicletas registradas'
                  : '$cantidadBicicletas registradas',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onUsarDatos,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Usar datos encontrados'),
              ),
            ),
          ],
        ),
      );
    }

    if (busquedaRealizada) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.info_outline,
          color: ColoresUbb.azulApp,
          children: [
            Text(
              'Sin coincidencia. Para un usuario nuevo, completa correo, RUT y datos de bicicleta.',
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _CajaBusquedaManual extends StatelessWidget {
  const _CajaBusquedaManual({
    required this.icono,
    required this.color,
    required this.children,
  });

  final IconData icono;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
