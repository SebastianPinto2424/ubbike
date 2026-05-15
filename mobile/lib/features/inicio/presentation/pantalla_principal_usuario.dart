part of 'pantalla_principal.dart';

class VistaInicioUsuario extends StatefulWidget {
  const VistaInicioUsuario({super.key});

  @override
  State<VistaInicioUsuario> createState() => _VistaInicioUsuarioState();
}

class _VistaInicioUsuarioState extends State<VistaInicioUsuario> {
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<BicicletaApp?> futuroBicicletaActiva;
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroBicicletaActiva = bicicletaApi.obtenerActiva();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroBicicletaActiva = bicicletaApi.obtenerActiva();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Usuario UBB')}',
          detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
          icono: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<BicicletaApp?>(
          future: futuroBicicletaActiva,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _EstadoLista(
                icono: Icons.pedal_bike,
                titulo: 'Cargando estado',
                detalle: 'Consultando tu bicicleta activa.',
              );
            }
            return _EstadoActualUsuario(bicicleta: snapshot.data);
          },
        ),
        const SizedBox(height: 16),
        _TituloApartado(titulo: 'Uso de bicicleteros', onRefresh: _recargar),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicleteroApp>>(
          future: futuroBicicleteros,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar bicicleteros',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            final bicicleteros = snapshot.data ?? [];
            if (bicicleteros.isEmpty) {
              return const _EstadoLista(
                icono: Icons.location_off_outlined,
                titulo: 'Sin bicicleteros activos',
                detalle: 'Cuando existan bicicleteros activos apareceran aqui.',
              );
            }
            return Column(
              children: bicicleteros
                  .map(
                    (bicicletero) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicleteroApp(bicicletero: bicicletero),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EstadoActualUsuario extends StatelessWidget {
  const _EstadoActualUsuario({required this.bicicleta});

  final BicicletaApp? bicicleta;

  @override
  Widget build(BuildContext context) {
    final bicicleta = this.bicicleta;
    final dentro = bicicleta?.dentroBicicletero ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: ColoresUbb.azulApp.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresUbb.azulApp, // Dejar solo azul como solicitó
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                dentro ? Icons.lock_outline : Icons.lock_open_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bicicleta == null
                  ? 'Sin bicicleta activa'
                  : dentro
                      ? 'Bicicleta dentro'
                      : 'Sin bicicleta dentro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              bicicleta == null
                  ? 'Registra una bicicleta y marcala como activa para generar QR.'
                  : dentro
                      ? '${bicicleta.descripcion} esta en ${bicicleta.bicicleteroActualNombre ?? 'un bicicletero'}. El siguiente QR sera de retiro.'
                      : '${bicicleta.descripcion} esta lista. El siguiente QR sera de ingreso.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.86),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaBicicletas extends StatefulWidget {
  const VistaBicicletas({super.key});

  @override
  State<VistaBicicletas> createState() => _VistaBicicletasState();
}

class _VistaBicicletasState extends State<VistaBicicletas> {
  final bicicletaApi = BicicletaApi();
  late Future<List<BicicletaApp>> futuroBicicletas;

  @override
  void initState() {
    super.initState();
    futuroBicicletas = bicicletaApi.listar();
  }

  void _recargar() {
    setState(() {
      futuroBicicletas = bicicletaApi.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Bicicletas',
          detalle: 'Administra las bicicletas asociadas a tu cuenta.',
          icono: Icons.pedal_bike,
        ),
        const SizedBox(height: 16),
        const _TituloApartado(titulo: 'Mis bicicletas'),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicletaApp>>(
          future: futuroBicicletas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _EstadoLista(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar bicicletas',
                detalle: 'Revisa que el backend este activo.',
              );
            }

            final bicicletas = snapshot.data ?? [];

            if (bicicletas.isEmpty) {
              return SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pedal_bike,
                        size: 64,
                        color: ColoresUbb.textoSecundario,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin bicicletas',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: ColoresUbb.textoSecundario),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca abajo para registrar tu primera bicicleta',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: ColoresUbb.textoSecundario),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: bicicletas
                  .map(
                    (bicicleta) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicletaUsuario(
                        bicicleta: bicicleta,
                        onEditar: () => _mostrarFormularioBicicleta(
                          bicicleta: bicicleta,
                        ),
                        onEliminar: () => _eliminarBicicleta(bicicleta),
                        onCambiarActiva: (activa) =>
                            _cambiarEstadoActivoBicicleta(bicicleta, activa),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _mostrarFormularioBicicleta,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: ColoresUbb.azulApp.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColoresUbb.azulApp.withOpacity(0.5),
                style: BorderStyle.none, // We will just use background
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 32, color: ColoresUbb.azulApp),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registrar nueva bicicleta',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ColoresUbb.azulApp,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Agrega descripcion, foto y datos visibles para validacion.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const VistaMovimientosUsuario(),
      ],
    );
  }

  Future<void> _cambiarEstadoActivoBicicleta(
    BicicletaApp bicicleta,
    bool activa,
  ) async {
    if (bicicleta.activa == activa) {
      return;
    }

    try {
      if (activa) {
        await bicicletaApi.activar(bicicleta.id);
      } else {
        await bicicletaApi.desactivar(bicicleta.id);
      }
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activa
                  ? '${bicicleta.descripcion} activada'
                  : '${bicicleta.descripcion} inactiva',
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

  Future<void> _eliminarBicicleta(BicicletaApp bicicleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bicicleta'),
        content: Text('Se eliminara "${bicicleta.descripcion}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await bicicletaApi.eliminar(bicicleta.id);
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bicicleta eliminada')),
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

  Future<void> _mostrarFormularioBicicleta({BicicletaApp? bicicleta}) async {
    final guardo = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => _FormularioBicicletaSheet(
        bicicleta: bicicleta,
        bicicletaApi: bicicletaApi,
      ),
    );

    if (guardo == true && mounted) {
      _recargar();
    }
  }
}

class _FormularioBicicletaSheet extends StatefulWidget {
  const _FormularioBicicletaSheet({
    required this.bicicleta,
    required this.bicicletaApi,
  });

  final BicicletaApp? bicicleta;
  final BicicletaApi bicicletaApi;

  @override
  State<_FormularioBicicletaSheet> createState() =>
      _FormularioBicicletaSheetState();
}

class _FormularioBicicletaSheetState extends State<_FormularioBicicletaSheet> {
  late final TextEditingController descripcionController;
  late final TextEditingController marcaController;
  late final TextEditingController modeloController;
  late final TextEditingController colorController;
  late final TextEditingController aroController;
  late final TextEditingController numeroSerieController;
  late String? fotoSeleccionada;
  late bool activar;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    final bicicleta = widget.bicicleta;
    descripcionController =
        TextEditingController(text: bicicleta?.descripcion ?? '');
    marcaController = TextEditingController(text: bicicleta?.marca ?? '');
    modeloController = TextEditingController(text: bicicleta?.modelo ?? '');
    colorController = TextEditingController(text: bicicleta?.color ?? '');
    aroController = TextEditingController(text: bicicleta?.aro ?? '');
    numeroSerieController =
        TextEditingController(text: bicicleta?.numeroSerie ?? '');
    fotoSeleccionada = bicicleta?.fotoUrl;
    activar = bicicleta?.activa ?? false;
  }

  @override
  void dispose() {
    descripcionController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    aroController.dispose();
    numeroSerieController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final imagen = await ImagePicker().pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagen == null) {
        return;
      }

      final mime = _normalizarMimeFoto(imagen.mimeType, imagen.name);
      if (!_mimesFotoPermitidos.contains(mime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La foto debe ser JPG, PNG o WEBP.')),
          );
        }
        return;
      }

      final bytes = await imagen.readAsBytes();
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      if (dataUrl.length > _maxFotoDataUrlLength) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('La foto es muy pesada. Elige una imagen mas liviana.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => fotoSeleccionada = dataUrl);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la foto.')),
        );
      }
    }
  }

  Future<void> _guardar() async {
    final descripcion = descripcionController.text.trim();
    if (descripcion.isEmpty || guardando) {
      return;
    }

    setState(() => guardando = true);

    try {
      final bicicleta = widget.bicicleta;
      if (bicicleta == null) {
        await widget.bicicletaApi.crear(
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: colorController.text.trim(),
          aro: aroController.text.trim(),
          numeroSerie: numeroSerieController.text.trim(),
          fotoUrl: fotoSeleccionada,
          activar: activar,
        );
      } else {
        await widget.bicicletaApi.actualizar(
          bicicletaId: bicicleta.id,
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: colorController.text.trim(),
          aro: aroController.text.trim(),
          numeroSerie: numeroSerieController.text.trim(),
          fotoUrl: fotoSeleccionada,
        );
        if (activar && !bicicleta.activa) {
          await widget.bicicletaApi.activar(bicicleta.id);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bicicleta = widget.bicicleta;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              bicicleta == null ? 'Registrar bicicleta' : 'Editar bicicleta',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripcion',
                prefixIcon: Icon(Icons.pedal_bike),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: aroController,
                    decoration: const InputDecoration(
                      labelText: 'Aro',
                      prefixIcon: Icon(Icons.circle_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numeroSerieController,
              decoration: const InputDecoration(
                labelText: 'Numero de serie',
                prefixIcon: Icon(Icons.qr_code_2),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            _SelectorFotoBicicleta(
              fotoDataUrl: fotoSeleccionada,
              onCamara: () => _seleccionarFoto(ImageSource.camera),
              onGaleria: () => _seleccionarFoto(ImageSource.gallery),
              onQuitar: fotoSeleccionada == null
                  ? null
                  : () => setState(() => fotoSeleccionada = null),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: activar,
              onChanged: guardando
                  ? null
                  : (valor) => setState(() => activar = valor ?? false),
              title: const Text('Usar como bicicleta activa'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: guardando ? null : _guardar,
              icon: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(guardando ? 'Guardando' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorFotoBicicleta extends StatelessWidget {
  const _SelectorFotoBicicleta({
    required this.fotoDataUrl,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
  });

  final String? fotoDataUrl;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final foto = fotoDataUrl;
    final bytesFoto = _decodificarFotoDataUrl(foto);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bytesFoto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytesFoto,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamara,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
                OutlinedButton.icon(
                  onPressed: onGaleria,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Subir foto'),
                ),
                if (onQuitar != null)
                  TextButton.icon(
                    onPressed: onQuitar,
                    icon: const Icon(Icons.close),
                    label: const Text('Quitar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VistaMovimientosUsuario extends StatefulWidget {
  const VistaMovimientosUsuario({super.key});

  @override
  State<VistaMovimientosUsuario> createState() =>
      _VistaMovimientosUsuarioState();
}

class _VistaMovimientosUsuarioState extends State<VistaMovimientosUsuario> {
  final historialApi = HistorialApi();
  final filtroController = TextEditingController();
  String periodo = 'MES';
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
  }

  @override
  void dispose() {
    filtroController.dispose();
    super.dispose();
  }

  Future<List<MovimientoApp>> _obtenerMovimientos() {
    return historialApi.listar(
      filtro: filtroController.text,
      periodo: periodo,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  void _cambiarPeriodo(String nuevoPeriodo) {
    if (periodo != nuevoPeriodo) {
      setState(() {
        periodo = nuevoPeriodo;
        _recargar();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloApartado(titulo: 'Mis movimientos', onRefresh: _recargar),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FiltroChip(label: 'Dia', value: 'DIA', selectedValue: periodo, onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(label: 'Semana', value: 'SEMANA', selectedValue: periodo, onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(label: 'Mes', value: 'MES', selectedValue: periodo, onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(label: 'Ano', value: 'ANIO', selectedValue: periodo, onTap: (v) => _cambiarPeriodo(v)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: ColoresUbb.azulApp.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: filtroController,
            decoration: const InputDecoration(
              labelText: 'Filtrar por bicicleta',
              prefixIcon: Icon(Icons.search, color: ColoresUbb.azulApp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (_) => _recargar(),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MovimientoApp>>(
          future: futuroMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar movimientos',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            final movimientos = snapshot.data ?? [];
            if (movimientos.isEmpty) {
              return const _EstadoLista(
                icono: Icons.history,
                titulo: 'Sin movimientos',
                detalle: 'Tus ingresos y retiros apareceran aqui.',
              );
            }
            return Column(
              children: movimientos
                  .map(
                    (movimiento) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaMovimientoCentral(movimiento: movimiento),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bool seleccionado = value == selectedValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? ColoresUbb.azulApp : ColoresUbb.azulApp.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: seleccionado ? Colors.white : ColoresUbb.azulApp,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: seleccionado ? Colors.white : ColoresUbb.azulApp,
                fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        bicicleta?.dentroBicicletero == true ? 'SALIDA' : 'INGRESO';
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
                color: ColoresUbb.azulApp.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<BicicleteroApp>(
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                menuMaxHeight: 300,
                initialValue: bicicleteroSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Bicicletero a usar',
                  prefixIcon: Icon(Icons.location_on_outlined, color: ColoresUbb.azulApp),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: generando ||
                    cargandoDatos ||
                    bicicleta == null ||
                    (debeSeleccionarBicicletero &&
                        bicicleteroSeleccionado == null)
                ? null
                : _generarQr,
            icon: generando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              qr == null || segundosRestantes == 0
                  ? 'Generar QR'
                  : 'Regenerar QR',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          
          if (qr != null) ...[
            const SizedBox(height: 24),
            Center(
              child: SelectableText(
                'Token de prueba: ${qr.token}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColoresUbb.textoSecundario.withOpacity(0.5),
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
          bicicletaActiva?.dentroBicicletero == true ? 'SALIDA' : 'INGRESO';
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

class VistaSolicitarGuardia extends StatefulWidget {
  const VistaSolicitarGuardia({super.key});

  @override
  State<VistaSolicitarGuardia> createState() => _VistaSolicitarGuardiaState();
}

class _VistaSolicitarGuardiaState extends State<VistaSolicitarGuardia> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  final mensajeController = TextEditingController();
  List<BicicleteroApp> bicicleteros = [];
  BicicleteroApp? bicicleteroSeleccionado;
  String tipoSolicitud = 'REQUIERE_SERVICIO';
  late Future<List<SolicitudGuardiaApp>> futuroSolicitudes;
  bool cargando = true;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
    _cargarBicicleteros();
  }

  @override
  void dispose() {
    mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarBicicleteros() async {
    try {
      final datos = await solicitudGuardiaApi.listarBicicleteros();
      if (mounted) {
        setState(() {
          bicicleteros = datos;
          bicicleteroSeleccionado = datos.isEmpty ? null : datos.first;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _enviarSolicitud() async {
    final bicicletero = bicicleteroSeleccionado;

    if (bicicletero == null || enviando) {
      return;
    }

    setState(() => enviando = true);

    try {
      await solicitudGuardiaApi.crearSolicitud(
        bicicleteroId: bicicletero.id,
        tipo: tipoSolicitud,
        mensaje: mensajeController.text.trim(),
      );

      if (mounted) {
        mensajeController.clear();
        setState(() {
          futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada al guardia con copia a central'),
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
        setState(() => enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _EncabezadoSeccion(
          titulo: 'Guardia',
          detalle:
              'Solicita apoyo si el guardia no esta visible o necesitas atencion.',
          icono: Icons.support_agent,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cargando)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(
                      color: ColoresUbb.azulApp.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<BicicleteroApp>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      menuMaxHeight: 300,
                      initialValue: bicicleteroSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Bicicletero',
                        prefixIcon: Icon(Icons.location_on_outlined, color: ColoresUbb.azulApp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: Colors.white,
                      items: bicicleteros
                          .map(
                            (bicicletero) => DropdownMenuItem(
                              value: bicicletero,
                              child: Text(
                                bicicletero.nombre,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setState(() => bicicleteroSeleccionado = valor);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _FiltroChip(
                      label: 'Requiere servicio',
                      value: 'REQUIERE_SERVICIO',
                      selectedValue: tipoSolicitud,
                      icon: Icons.notifications_active_outlined,
                      onTap: (v) => setState(() => tipoSolicitud = v),
                    ),
                    _FiltroChip(
                      label: 'Guardia ausente',
                      value: 'GUARDIA_AUSENTE',
                      selectedValue: tipoSolicitud,
                      icon: Icons.person_off_outlined,
                      onTap: (v) => setState(() => tipoSolicitud = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulApp.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: mensajeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje opcional',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColoresUbb.azulApp,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed:
                      bicicleteroSeleccionado == null ? null : _enviarSolicitud,
                  icon: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined, color: Colors.white),
                  label: Text(
                    enviando ? 'Enviando...' : 'Enviar solicitud a central',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<SolicitudGuardiaApp>>(
          future: futuroSolicitudes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar tus solicitudes',
                detalle: '${snapshot.error}',
                color: ColoresUbb.rojoInstitucional,
                onTap: () {
                  setState(() {
                    futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
                  });
                },
              );
            }

            final solicitudes = snapshot.data ?? [];

            if (solicitudes.isEmpty) {
              return const _EstadoLista(
                icono: Icons.support_agent,
                titulo: 'Sin solicitudes recientes',
                detalle: 'Cuando solicites apoyo, el estado aparecera aqui.',
              );
            }

            return Column(
              children: solicitudes
                  .map(
                    (solicitud) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaSolicitudGuardia(solicitud: solicitud),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
