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
              _FiltroChip(
                  label: 'Dia',
                  value: 'DIA',
                  selectedValue: periodo,
                  onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(
                  label: 'Semana',
                  value: 'SEMANA',
                  selectedValue: periodo,
                  onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(
                  label: 'Mes',
                  value: 'MES',
                  selectedValue: periodo,
                  onTap: (v) => _cambiarPeriodo(v)),
              const SizedBox(width: 8),
              _FiltroChip(
                  label: 'Ano',
                  value: 'ANIO',
                  selectedValue: periodo,
                  onTap: (v) => _cambiarPeriodo(v)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: ColoresUbb.azulApp.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: filtroController,
            decoration: const InputDecoration(
              labelText: 'Filtrar por bicicleta',
              prefixIcon: Icon(Icons.search, color: ColoresUbb.azulApp),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
