part of '../pantalla_principal.dart';

class VistaDashboardCentral extends StatefulWidget {
  const VistaDashboardCentral({super.key});

  @override
  State<VistaDashboardCentral> createState() => _VistaDashboardCentralState();
}

class _VistaDashboardCentralState extends State<VistaDashboardCentral> {
  final historialApi = HistorialApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<ResumenHistorialApp> futuroResumen;
  late Future<List<BicicleteroApp>> futuroBicicleteros;
  String periodoResumen = 'SEMANA';

  @override
  void initState() {
    super.initState();
    futuroResumen = _obtenerResumen();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  Future<ResumenHistorialApp> _obtenerResumen() {
    return historialApi.resumen(periodo: periodoResumen);
  }

  void _recargar() {
    setState(() {
      futuroResumen = _obtenerResumen();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
    });
  }

  void _cambiarPeriodoResumen(String valor) {
    setState(() {
      periodoResumen = valor;
      futuroResumen = _obtenerResumen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Central')}',
          detalle: 'Dashboard de movimientos y cupos disponibles.',
          icono: Icons.dashboard_outlined,
        ),
        const SizedBox(height: 16),
        _PanelFiltros(
          titulo: 'Filtro del dashboard',
          detalle: _etiquetaPeriodoFiltro(periodoResumen),
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
                selected: {periodoResumen},
                onSelectionChanged: (valor) =>
                    _cambiarPeriodoResumen(valor.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<ResumenHistorialApp>(
          future: futuroResumen,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GridIndicadoresCentral(
                indicadores: [
                  _IndicadorCentral(
                      valor: '...', etiqueta: 'Movimientos semana'),
                  _IndicadorCentral(
                      valor: '...', etiqueta: 'Denegaciones semana'),
                  _IndicadorCentral(
                      valor: '2', etiqueta: 'Bicicleteros activos'),
                ],
              );
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el resumen',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final resumen = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GridIndicadoresCentral(
                  indicadores: [
                    _IndicadorCentral(
                      valor: resumen.totalMovimientos.toString(),
                      etiqueta: 'Movimientos filtrados',
                    ),
                    _IndicadorCentral(
                      valor: resumen.denegados.toString(),
                      etiqueta: 'Denegaciones',
                    ),
                    _IndicadorCentral(
                      valor: resumen.manuales.toString(),
                      etiqueta: 'Movimientos manuales',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RankingResumen(
                  titulo: 'Operaciones por guardia',
                  datos: resumen.operacionesPorGuardia,
                  icono: Icons.security_outlined,
                ),
                const SizedBox(height: 10),
                _RankingResumen(
                  titulo: 'Operaciones por bicicletero',
                  datos: resumen.operacionesPorBicicletero,
                  icono: Icons.location_on_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _TituloApartado(titulo: 'Cupos por bicicletero', onRefresh: _recargar),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicleteroApp>>(
          future: futuroBicicleteros,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar cupos',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            return Column(
              children: (snapshot.data ?? [])
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

class _RankingResumen extends StatelessWidget {
  const _RankingResumen({
    required this.titulo,
    required this.datos,
    required this.icono,
  });

  final String titulo;
  final Map<String, int> datos;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final entradas = datos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximo = entradas.isEmpty ? 1 : entradas.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: ColoresUbb.azulApp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entradas.isEmpty)
              Text(
                'Sin datos para el filtro seleccionado.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.textoSecundario,
                    ),
              )
            else
              ...entradas.take(5).map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entrada.key,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                entrada.value.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: entrada.value / maximo,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
