part of '../pantalla_principal.dart';

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
  String tipoMovimiento = 'TODOS';
  String estadoMovimiento = 'TODOS';
  String origenMovimiento = 'TODOS';
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
      origen: origenMovimiento,
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
        _PanelFiltros(
          titulo: 'Filtros',
          detalle:
              '${_etiquetaPeriodoFiltro(periodo)} | ${_etiquetaTipoMovimientoFiltro(tipoMovimiento)} | ${_etiquetaEstadoMovimientoFiltro(estadoMovimiento)}',
          onLimpiar: () {
            filtroController.clear();
            periodo = 'MES';
            tipoMovimiento = 'TODOS';
            estadoMovimiento = 'TODOS';
            origenMovimiento = 'TODOS';
            _recargar();
          },
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
                onSelectionChanged: (valor) => _cambiarPeriodo(valor.first),
              ),
            ),
            const SizedBox(height: 12),
            _EtiquetaFiltro(
              texto: 'Tipo',
              child: _SegmentadoEnLinea<String>(
                segments: const [
                  ButtonSegment(value: 'TODOS', label: Text('Todos')),
                  ButtonSegment(value: 'INGRESO', label: Text('Ingresos')),
                  ButtonSegment(value: 'RETIRO', label: Text('Retiros')),
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
                  origenMovimiento = valor.first;
                  _recargar();
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: filtroController,
              decoration: const InputDecoration(
                labelText: 'Buscar por bicicleta o bicicletero',
                prefixIcon: Icon(Icons.search),
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
                      child: _TarjetaMovimientoCentral(
                        movimiento: movimiento,
                        mostrarIdentidad: false,
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
          color: seleccionado
              ? ColoresUbb.azulApp
              : ColoresUbb.azulApp.withValues(alpha: 0.05),
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
