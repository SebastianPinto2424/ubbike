import 'package:flutter/material.dart';

import '../../core/tema/colores_ubb.dart';

class MarcaUbbike extends StatelessWidget {
  const MarcaUbbike({
    super.key,
    this.compacta = false,
    this.sobreAzul = false,
  });

  final bool compacta;
  final bool sobreAzul;

  @override
  Widget build(BuildContext context) {
    final altoLogo = compacta ? 34.0 : 68.0;
    final anchoLogo = compacta ? 128.0 : 224.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: sobreAzul ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sobreAzul
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacta ? 4 : 0,
              vertical: compacta ? 4 : 0,
            ),
            child: Image.asset(
              'assets/imagenes/ubbike-logo-transparente.png',
              semanticLabel: 'Logo UBBike',
              height: altoLogo,
              width: anchoLogo,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        if (!compacta) ...[
          const SizedBox(height: 10),
          Text(
            'Universidad del Bio-Bio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresUbb.turquesa,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ],
    );
  }
}
