part of '../pantalla_principal.dart';

class _GridIndicadoresCentral extends StatelessWidget {
  const _GridIndicadoresCentral({required this.indicadores});

  final List<Widget> indicadores;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 700;

        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: compacto ? 1 : 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: compacto ? 3.3 : 1.35,
          children: indicadores,
        );
      },
    );
  }
}

class _IndicadorCentral extends StatelessWidget {
  const _IndicadorCentral({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ColoresUbb.azulApp,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.anchoCompleto = false,
    this.valorColor,
    this.valorPeso = FontWeight.w800,
  });

  final String etiqueta;
  final String valor;
  final bool anchoCompleto;
  final Color? valorColor;
  final FontWeight valorPeso;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = anchoCompleto ||
              constraints.maxWidth < 380 ||
              valor.length > 28 ||
              valor.contains('@');
          final etiquetaWidget = Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          );
          final valorWidget = Text(
            valor,
            textAlign: compacto ? TextAlign.start : TextAlign.end,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valorColor,
                  fontWeight: valorPeso,
                ),
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                etiquetaWidget,
                const SizedBox(height: 2),
                valorWidget,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: etiquetaWidget),
              Flexible(child: valorWidget),
            ],
          );
        },
      ),
    );
  }
}
