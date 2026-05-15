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
      tipo: tipoMovimiento,
      estado: estadoMovimiento,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  String _resumenFiltros() {
    final busqueda = filtroController.text.trim();
    final partes = [
      _etiquetaPeriodoFiltro(periodo),
      _etiquetaTipoMovimientoFiltro(tipoMovimiento),
      _etiquetaEstadoMovimientoFiltro(estadoMovimiento),
      if (busqueda.isNotEmpty) 'Busqueda activa',
    ];

    return partes.join(' | ');
  }

  void _limpiarFiltros() {
    filtroController.clear();
    periodo = 'SEMANA';
    tipoMovimiento = 'TODOS';
    estadoMovimiento = 'TODOS';
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Movimientos',
          detalle:
              'Filtra historial por fecha, usuario, bicicleta, tipo y estado.',
          icono: Icons.manage_search_outlined,
        ),
        const SizedBox(height: 16),
        _PanelFiltros(
          titulo: 'Filtros de historial',
          detalle: _resumenFiltros(),
          onLimpiar: _limpiarFiltros,
          children: [
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
                  periodo = valor.first;
                  _recargar();
                },
              ),
            ),
            const SizedBox(height: 12),
            _EtiquetaFiltro(
              texto: 'Tipo de movimiento',
              child: _SegmentadoEnLinea<String>(
                segments: const [
                  ButtonSegment(value: 'TODOS', label: Text('Todos')),
                  ButtonSegment(value: 'INGRESO', label: Text('Ingresos')),
                  ButtonSegment(value: 'SALIDA', label: Text('Retiros')),
                ],
                selected: {tipoMovimiento},
                onSelectionChanged: (valor) {
                  tipoMovimiento = valor.first;
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
                  ButtonSegment(value: 'DENEGADO', label: Text('Denegados')),
                ],
                selected: {estadoMovimiento},
                onSelectionChanged: (valor) {
                  estadoMovimiento = valor.first;
                  _recargar();
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: filtroController,
              decoration: InputDecoration(
                labelText:
                    'Buscar por RUT, correo, bicicleta, guardia o bicicletero',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filtroController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar busqueda',
                        onPressed: () {
                          filtroController.clear();
                          _recargar();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (_) => _recargar(),
            ),
          ],
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
                titulo: 'No se pudo cargar el historial',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final movimientos = snapshot.data ?? [];

            if (movimientos.isEmpty) {
              return const _EstadoLista(
                icono: Icons.manage_search_outlined,
                titulo: 'Sin movimientos',
                detalle: 'No hay registros para los filtros seleccionados.',
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

class _TarjetaMovimientoCentral extends StatelessWidget {
  const _TarjetaMovimientoCentral({required this.movimiento});

  final MovimientoApp movimiento;

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';

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
                    '${esIngreso ? 'Ingreso' : 'Retiro'} | ${movimiento.usuarioNombre}',
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
            _FilaDato(
              etiqueta: 'Correo',
              valor: movimiento.usuarioCorreo,
            ),
            _FilaDato(
              etiqueta: 'RUT',
              valor: movimiento.usuarioRut ?? 'Sin RUT',
            ),
            _FilaDato(
              etiqueta: 'Bicicleta',
              valor: movimiento.bicicletaDescripcion,
            ),
            _FilaDato(
              etiqueta: 'Bicicletero',
              valor: movimiento.bicicleteroNombre,
            ),
            _FilaDato(
              etiqueta: 'Guardia',
              valor: movimiento.guardiaNombre,
            ),
            _FilaDato(
              etiqueta: 'Fecha',
              valor: _formatearFecha(movimiento.creadoEn),
            ),
            if (movimiento.motivoDenegacion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo: ${movimiento.motivoDenegacion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.rojoInstitucional,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
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
    'SALIDA' => 'Retiros',
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

String _formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year} $hora:$minuto';
}
