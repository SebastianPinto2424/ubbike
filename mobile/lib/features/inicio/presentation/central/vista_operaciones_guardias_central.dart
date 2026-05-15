part of '../pantalla_principal.dart';

class _ResumenGuardia {
  int total = 0;
  int denegaciones = 0;
  final bicicleteros = <String>{};
}

Map<String, _ResumenGuardia> _agruparPorGuardia(
  List<MovimientoApp> movimientos,
) {
  final resumen = <String, _ResumenGuardia>{};

  for (final movimiento in movimientos) {
    final guardia = resumen.putIfAbsent(
      movimiento.guardiaNombre,
      _ResumenGuardia.new,
    );

    guardia.total += 1;
    if (movimiento.estado == 'DENEGADO') {
      guardia.denegaciones += 1;
    }
    guardia.bicicleteros.add(movimiento.bicicleteroNombre);
  }

  return resumen;
}

class VistaOperacionesGuardiasCentral extends StatefulWidget {
  const VistaOperacionesGuardiasCentral({super.key});

  @override
  State<VistaOperacionesGuardiasCentral> createState() =>
      _VistaOperacionesGuardiasCentralState();
}

class _VistaOperacionesGuardiasCentralState
    extends State<VistaOperacionesGuardiasCentral> {
  final historialApi = HistorialApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  String periodo = 'DIA';
  String estadoMovimiento = 'TODOS';
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
    _cargarBicicleteros();
  }

  Future<void> _cargarBicicleteros() async {
    try {
      final datos = await solicitudGuardiaApi.listarBicicleteros();
      if (mounted) {
        setState(() => bicicleteros = datos);
      }
    } catch (_) {
      if (mounted) {
        setState(() => bicicleteros = []);
      }
    }
  }

  Future<List<MovimientoApp>> _obtenerMovimientos() {
    return historialApi.listar(
      periodo: periodo,
      estado: estadoMovimiento,
      bicicleteroId: bicicleteroSeleccionado?.id,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  String _resumenFiltros() {
    return [
      _etiquetaPeriodoFiltro(periodo),
      bicicleteroSeleccionado?.nombre ?? 'Todos los bicicleteros',
      _etiquetaEstadoMovimientoFiltro(estadoMovimiento),
    ].join(' | ');
  }

  void _limpiarFiltros() {
    periodo = 'DIA';
    estadoMovimiento = 'TODOS';
    bicicleteroSeleccionado = null;
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Operaciones por guardia',
          detalle: 'Filtra guardias por bicicletero, periodo y resultado.',
          icono: Icons.security_outlined,
        ),
        const SizedBox(height: 16),
        _PanelFiltros(
          titulo: 'Filtros de operaciones',
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
            DropdownButtonFormField<BicicleteroApp?>(
              key: ValueKey(bicicleteroSeleccionado?.id ?? 'todos'),
              initialValue: bicicleteroSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Bicicletero',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: [
                const DropdownMenuItem<BicicleteroApp?>(
                  value: null,
                  child: Text('Todos los bicicleteros'),
                ),
                ...bicicleteros.map(
                  (bicicletero) => DropdownMenuItem<BicicleteroApp?>(
                    value: bicicletero,
                    child: Text(
                      bicicletero.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (valor) {
                bicicleteroSeleccionado = valor;
                _recargar();
              },
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
                titulo: 'No se pudieron cargar operaciones',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final resumen = _agruparPorGuardia(snapshot.data ?? []);
            final entradas = resumen.entries.toList()
              ..sort((a, b) => b.value.total.compareTo(a.value.total));

            if (entradas.isEmpty) {
              return const _EstadoLista(
                icono: Icons.security_outlined,
                titulo: 'Sin operaciones',
                detalle: 'No hay validaciones para el periodo seleccionado.',
              );
            }

            return Column(
              children: entradas
                  .map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaAccion(
                        icono: Icons.verified_user_outlined,
                        titulo: entrada.key,
                        detalle:
                            '${entrada.value.total} validaciones | ${entrada.value.denegaciones} denegaciones | ${entrada.value.bicicleteros.join(', ')}',
                        color: entrada.value.denegaciones == 0
                            ? ColoresUbb.exito
                            : ColoresUbb.amarilloInstitucional,
                      ),
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
