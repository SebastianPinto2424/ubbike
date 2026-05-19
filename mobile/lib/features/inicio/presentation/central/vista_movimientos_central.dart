part of '../pantalla_principal.dart';

class VistaMovimientosCentral extends StatefulWidget {
  const VistaMovimientosCentral({super.key});

  @override
  State<VistaMovimientosCentral> createState() =>
      _VistaMovimientosCentralState();
}

class _VistaMovimientosCentralState extends State<VistaMovimientosCentral> {
  final historialApi = HistorialApi();
  final filtroController = TextEditingController();
  String periodo = 'SEMANA';
  String tipoMovimiento = 'TODOS';
  String estadoMovimiento = 'TODOS';
  String origenMovimiento = 'TODOS';
  String? bicicleteroId;
  String? guardiaId;
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  bool exportando = false;
  late Future<List<MovimientoApp>> futuroMovimientos;
  Future<OpcionesHistorialApp>? futuroOpciones;

  bool get _esCentral {
    final rol = SesionActual.usuario?.rol;
    return rol == RolUsuario.adminCentral || rol == RolUsuario.administrador;
  }

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
    if (_esCentral) {
      futuroOpciones = historialApi.opciones();
    }
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
      desde: fechaDesde,
      hasta: fechaHasta,
      tipo: tipoMovimiento,
      estado: estadoMovimiento,
      bicicleteroId: bicicleteroId,
      guardiaId: guardiaId,
      origen: origenMovimiento,
      limite: 300,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  String _resumenFiltros() {
    final busqueda = filtroController.text.trim();
    final partes = [
      _etiquetaPeriodoFiltro(periodo),
      if (fechaDesde != null || fechaHasta != null) _textoRangoFechas(),
      _etiquetaTipoMovimientoFiltro(tipoMovimiento),
      _etiquetaEstadoMovimientoFiltro(estadoMovimiento),
      _etiquetaOrigenMovimientoFiltro(origenMovimiento),
      if (bicicleteroId != null) 'Bicicletero seleccionado',
      if (guardiaId != null) 'Guardia seleccionado',
      if (busqueda.isNotEmpty) 'Busqueda activa',
    ];

    return partes.join(' | ');
  }

  void _limpiarFiltros() {
    filtroController.clear();
    periodo = 'SEMANA';
    tipoMovimiento = 'TODOS';
    estadoMovimiento = 'TODOS';
    origenMovimiento = 'TODOS';
    bicicleteroId = null;
    guardiaId = null;
    fechaDesde = null;
    fechaHasta = null;
    _recargar();
  }

  String _textoRangoFechas() {
    final desde =
        fechaDesde == null ? 'Inicio' : _formatearFechaCorta(fechaDesde!);
    final hasta =
        fechaHasta == null ? 'Hoy' : _formatearFechaCorta(fechaHasta!);
    return '$desde a $hasta';
  }

  Future<void> _exportarExcel() async {
    if (exportando) return;
    setState(() => exportando = true);
    try {
      final excel = await historialApi.exportarExcel(
        filtro: filtroController.text,
        periodo: periodo,
        desde: fechaDesde,
        hasta: fechaHasta,
        tipo: tipoMovimiento,
        estado: estadoMovimiento,
        bicicleteroId: bicicleteroId,
        guardiaId: guardiaId,
        origen: origenMovimiento,
      );
      final nombre =
          'historial-ubbike-${DateTime.now().millisecondsSinceEpoch}.xls';
      final mensaje = await descargarReporteTexto(
        nombreArchivo: nombre,
        contenido: excel,
        tipoMime: 'application/vnd.ms-excel;charset=utf-8',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  Future<void> _exportarPdf() async {
    if (exportando) return;
    setState(() => exportando = true);
    try {
      final movimientos = await futuroMovimientos;
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Header(
                level: 0, child: pw.Text('Reporte de Movimientos - ubbike')),
            pw.Text('Filtros: ${_resumenFiltros()}'),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>[
                  'Tipo',
                  'Estado',
                  'Fecha',
                  'Hora',
                  'Usuario',
                  'Correo',
                  'RUT',
                  'Bicicleta',
                  'Bicicletero',
                  'Guardia',
                  'Metodo',
                ],
                ...movimientos.map((m) => [
                      m.tipo == "INGRESO" ? "Ingreso" : "Retiro",
                      m.estado == "CONFIRMADO" ? "Confirmado" : "Denegado",
                      _formatearFecha(m.creadoEn),
                      _formatearHora(m.creadoEn),
                      m.usuarioNombre,
                      m.usuarioCorreo,
                      m.usuarioRut ?? 'Sin RUT',
                      m.bicicletaDescripcion,
                      m.bicicleteroNombre,
                      m.guardiaNombre,
                      _etiquetaOrigenMovimientoFiltro(m.origen),
                    ]),
              ],
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'historial-ubbike.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filtros',
                            style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _EtiquetaFiltro(
                      texto: 'Periodo',
                      child: _SegmentadoEnLinea<String>(
                        segments: const [
                          ButtonSegment(value: 'DIA', label: Text('Dia')),
                          ButtonSegment(value: 'SEMANA', label: Text('Semana')),
                          ButtonSegment(value: 'MES', label: Text('Mes')),
                          ButtonSegment(value: 'ANIO', label: Text('Ano')),
                        ],
                        selected: {periodo},
                        onSelectionChanged: (valor) {
                          setModalState(() => periodo = valor.first);
                          _recargar();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EtiquetaFiltro(
                      texto: 'Rango exacto',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final res = await showDatePicker(
                                context: context,
                                initialDate: fechaDesde ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(DateTime.now().year + 1),
                              );
                              if (res != null) {
                                setModalState(() => fechaDesde = res);
                                _recargar();
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(fechaDesde == null
                                ? 'Desde'
                                : _formatearFechaCorta(fechaDesde!)),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final res = await showDatePicker(
                                context: context,
                                initialDate: fechaHasta ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(DateTime.now().year + 1),
                              );
                              if (res != null) {
                                setModalState(() => fechaHasta = res);
                                _recargar();
                              }
                            },
                            icon: const Icon(Icons.event_available_outlined),
                            label: Text(fechaHasta == null
                                ? 'Hasta'
                                : _formatearFechaCorta(fechaHasta!)),
                          ),
                          if (fechaDesde != null || fechaHasta != null)
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  fechaDesde = null;
                                  fechaHasta = null;
                                });
                                _recargar();
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Quitar rango'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EtiquetaFiltro(
                      texto: 'Tipo de movimiento',
                      child: _SegmentadoEnLinea<String>(
                        segments: const [
                          ButtonSegment(value: 'TODOS', label: Text('Todos')),
                          ButtonSegment(
                              value: 'INGRESO', label: Text('Ingresos')),
                          ButtonSegment(
                              value: 'RETIRO', label: Text('Retiros')),
                        ],
                        selected: {tipoMovimiento},
                        onSelectionChanged: (valor) {
                          setModalState(() => tipoMovimiento = valor.first);
                          _recargar();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EtiquetaFiltro(
                      texto: 'Resultado',
                      child: _SegmentadoEnLinea<String>(
                        segments: const [
                          ButtonSegment(value: 'TODOS', label: Text('Todos')),
                          ButtonSegment(
                              value: 'CONFIRMADO', label: Text('Confirmados')),
                          ButtonSegment(
                              value: 'DENEGADO', label: Text('Denegados')),
                        ],
                        selected: {estadoMovimiento},
                        onSelectionChanged: (valor) {
                          setModalState(() => estadoMovimiento = valor.first);
                          _recargar();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EtiquetaFiltro(
                      texto: 'Origen',
                      child: _SegmentadoEnLinea<String>(
                        segments: const [
                          ButtonSegment(value: 'TODOS', label: Text('Todos')),
                          ButtonSegment(value: 'QR', label: Text('QR')),
                          ButtonSegment(value: 'MANUAL', label: Text('Manual')),
                        ],
                        selected: {origenMovimiento},
                        onSelectionChanged: (valor) {
                          setModalState(() => origenMovimiento = valor.first);
                          _recargar();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: filtroController,
                      decoration: InputDecoration(
                        labelText: 'Buscar por RUT, correo, bicicleta...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: filtroController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar busqueda',
                                onPressed: () {
                                  setModalState(() => filtroController.clear());
                                  _recargar();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (_) {
                        setModalState(() {});
                        _recargar();
                      },
                    ),
                    if (_esCentral && futuroOpciones != null) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<OpcionesHistorialApp>(
                        future: futuroOpciones,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final opciones = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: bicicleteroId,
                                  decoration: const InputDecoration(
                                      labelText: 'Bicicletero'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('Todos')),
                                    ...opciones.bicicleteros.map((b) =>
                                        DropdownMenuItem(
                                            value: b.id,
                                            child: Text(b.nombre))),
                                  ],
                                  onChanged: (v) {
                                    setModalState(() => bicicleteroId = v);
                                    _recargar();
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: guardiaId,
                                  decoration: const InputDecoration(
                                      labelText: 'Guardia'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('Todos')),
                                    ...opciones.guardias.map((g) =>
                                        DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.nombre))),
                                  ],
                                  onChanged: (v) {
                                    setModalState(() => guardiaId = v);
                                    _recargar();
                                  },
                                ),
                              ],
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _limpiarFiltros();
                              Navigator.pop(context);
                            },
                            child: const Text('Limpiar Filtros'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MovimientoApp>>(
      future: futuroMovimientos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar movimientos'));
        }

        final datos = snapshot.data ?? [];
        final fuente = FuenteMovimientos(movimientos: datos);

        return ListView(
          padding: const EdgeInsets.only(bottom: 50),
          children: [
            const _EncabezadoSeccion(
              titulo: 'Movimientos',
              detalle: 'Visualiza y filtra historial de ingresos y retiros.',
              icono: Icons.manage_search_outlined,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _mostrarFiltros(context),
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                  ),
                  OutlinedButton.icon(
                    onPressed: exportando ? null : _exportarExcel,
                    icon: exportando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('Excel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: exportando ? null : _exportarPdf,
                    icon: exportando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: Colors.transparent,
                cardTheme: const CardThemeData(
                  elevation: 0,
                  color: Colors.transparent,
                ),
              ),
              child: PaginatedDataTable(
                source: fuente,
                columns: const [
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('RUT')),
                  DataColumn(label: Text('Bicicleta')),
                  DataColumn(label: Text('Bicicletero')),
                  DataColumn(label: Text('Guardia')),
                  DataColumn(label: Text('Metodo')),
                ],
                columnSpacing: 16,
                horizontalMargin: 10,
                rowsPerPage: 10,
                showCheckboxColumn: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaMovimientoCentral extends StatelessWidget {
  const _TarjetaMovimientoCentral({
    required this.movimiento,
    this.mostrarIdentidad = true,
  });

  final MovimientoApp movimiento;
  final bool mostrarIdentidad;

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';
    final tipoTexto = esIngreso ? 'Ingreso' : 'Retiro';
    final motivo = movimiento.motivoDenegacion?.trim();
    final comentario = movimiento.comentarioGuardia?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esIngreso ? Icons.login : Icons.logout,
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mostrarIdentidad
                        ? '$tipoTexto | ${movimiento.usuarioNombre}'
                        : tipoTexto,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: confirmado ? 'Confirmado' : 'Denegado',
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mostrarIdentidad) ...[
              _FilaDato(
                etiqueta: 'Correo',
                valor: movimiento.usuarioCorreo,
                anchoCompleto: true,
              ),
              _FilaDato(
                etiqueta: 'RUT',
                valor: movimiento.usuarioRut ?? 'Sin RUT',
              ),
            ],
            _FilaDato(
              etiqueta: 'Bicicleta',
              valor: movimiento.bicicletaDescripcion,
            ),
            _FilaDato(
              etiqueta: 'Bicicletero',
              valor: movimiento.bicicleteroNombre,
              anchoCompleto: true,
            ),
            _FilaDato(etiqueta: 'Guardia', valor: movimiento.guardiaNombre),
            _FilaDato(
              etiqueta: 'Fecha',
              valor: _formatearFecha(movimiento.creadoEn),
            ),
            _FilaDato(
              etiqueta: 'Hora',
              valor: _formatearHora(movimiento.creadoEn),
            ),
            _FilaDato(
              etiqueta: 'Metodo',
              valor: _etiquetaOrigenMovimientoFiltro(movimiento.origen),
            ),
            if (motivo != null && motivo.isNotEmpty)
              _FilaDato(
                etiqueta: 'Motivo de rechazo',
                valor: motivo,
                anchoCompleto: true,
                valorColor: ColoresUbb.rojoInstitucional,
                valorPeso: FontWeight.w700,
              ),
            if (comentario != null && comentario.isNotEmpty)
              _FilaDato(
                etiqueta: 'Comentario guardia',
                valor: comentario,
                anchoCompleto: true,
                valorColor: ColoresUbb.textoSecundario,
                valorPeso: FontWeight.w700,
              ),
          ],
        ),
      ),
    );
  }
}

class _PanelFiltros extends StatelessWidget {
  const _PanelFiltros({
    required this.titulo,
    required this.detalle,
    required this.children,
    this.onLimpiar,
  });

  final String titulo;
  final String detalle;
  final List<Widget> children;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune, color: ColoresUbb.azulApp),
        title: Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Text(
          detalle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 6),
          ...children,
          if (onLimpiar != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLimpiar,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Restablecer filtros'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EtiquetaFiltro extends StatelessWidget {
  const _EtiquetaFiltro({required this.texto, required this.child});

  final String texto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresUbb.textoSecundario,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SegmentadoEnLinea<T extends Object> extends StatelessWidget {
  const _SegmentadoEnLinea({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: segments,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }
}

String _etiquetaPeriodoFiltro(String periodo) {
  return switch (periodo) {
    'DIA' => 'Dia',
    'SEMANA' => 'Semana',
    'MES' => 'Mes',
    'ANIO' => 'Ano',
    _ => periodo,
  };
}

String _etiquetaTipoMovimientoFiltro(String tipo) {
  return switch (tipo) {
    'TODOS' => 'Todos los movimientos',
    'INGRESO' => 'Ingresos',
    'RETIRO' => 'Retiros',
    _ => tipo,
  };
}

String _etiquetaEstadoMovimientoFiltro(String estado) {
  return switch (estado) {
    'TODOS' => 'Todos los resultados',
    'CONFIRMADO' => 'Confirmados',
    'DENEGADO' => 'Denegados',
    _ => estado,
  };
}

String _etiquetaOrigenMovimientoFiltro(String origen) {
  return switch (origen) {
    'TODOS' => 'Todos los origenes',
    'QR' => 'QR',
    'MANUAL' => 'Manual',
    _ => origen,
  };
}

String _formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}

String _formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}

String _formatearHora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}
