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

  @override
  void initState() {
    super.initState();
    futuroResumen = historialApi.resumen();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroResumen = historialApi.resumen();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
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
            return _GridIndicadoresCentral(
              indicadores: [
                _IndicadorCentral(
                  valor: resumen.movimientosSemana.toString(),
                  etiqueta: 'Movimientos semana',
                ),
                _IndicadorCentral(
                  valor: resumen.denegacionesSemana.toString(),
                  etiqueta: 'Denegaciones semana',
                ),
                _IndicadorCentral(
                  valor: resumen.operacionesPorGuardia.length.toString(),
                  etiqueta: 'Guardias con operaciones',
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
