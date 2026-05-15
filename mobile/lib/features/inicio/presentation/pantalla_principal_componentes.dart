part of 'pantalla_principal.dart';

class _TarjetaBicicletaUsuario extends StatefulWidget {
  const _TarjetaBicicletaUsuario({
    required this.bicicleta,
    required this.onEditar,
    required this.onEliminar,
    required this.onCambiarActiva,
  });

  final BicicletaApp bicicleta;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final ValueChanged<bool> onCambiarActiva;

  @override
  State<_TarjetaBicicletaUsuario> createState() =>
      _TarjetaBicicletaUsuarioState();
}

class _TarjetaBicicletaUsuarioState extends State<_TarjetaBicicletaUsuario> {
  bool gestionAbierta = false;

  @override
  Widget build(BuildContext context) {
    final bicicleta = widget.bicicleta;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ColoresUbb.superficieAzulSuave,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: ColoresUbb.azulApp,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bicicleta.descripcion,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bicicleta.activa
                            ? 'Bicicleta seleccionada para generar QR.'
                            : 'Disponible para administrar en tu cuenta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ChipEstado(
                  texto: bicicleta.activa ? 'Activa' : 'Inactiva',
                  color: bicicleta.activa
                      ? ColoresUbb.exito
                      : ColoresUbb.textoSecundario,
                ),
              ],
            ),
            if (bicicleta.fotoUrl != null &&
                bicicleta.fotoUrl!.startsWith('data:image')) ...[
              const SizedBox(height: 14),
              _ImagenBicicleta(fotoDataUrl: bicicleta.fotoUrl!),
            ],
            const SizedBox(height: 14),
            _InfoBicicletaGrid(bicicleta: bicicleta),
            const SizedBox(height: 14),
            _BotonGestionBicicleta(
              expandido: gestionAbierta,
              onTap: () => setState(() => gestionAbierta = !gestionAbierta),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: gestionAbierta
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _PanelGestionBicicleta(
                bicicleta: bicicleta,
                onCambiarActiva: widget.onCambiarActiva,
                onEditar: widget.onEditar,
                onEliminar: widget.onEliminar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBicicletaGrid extends StatelessWidget {
  const _InfoBicicletaGrid({required this.bicicleta});

  final BicicletaApp bicicleta;

  @override
  Widget build(BuildContext context) {
    final usoActual = bicicleta.dentroBicicletero
        ? bicicleta.bicicleteroActualNombre ?? 'En bicicletero'
        : 'Fuera';
    final datos = [
      _DatoBicicletaInfo(
        icono: Icons.sell_outlined,
        etiqueta: 'Marca',
        valor: _valorInformado(bicicleta.marca),
      ),
      _DatoBicicletaInfo(
        icono: Icons.category_outlined,
        etiqueta: 'Modelo',
        valor: _valorInformado(bicicleta.modelo),
      ),
      _DatoBicicletaInfo(
        icono: Icons.palette_outlined,
        etiqueta: 'Color',
        valor: _valorInformado(bicicleta.color),
      ),
      _DatoBicicletaInfo(
        icono: Icons.circle_outlined,
        etiqueta: 'Aro',
        valor: _valorInformado(bicicleta.aro),
      ),
      _DatoBicicletaInfo(
        icono: Icons.qr_code_2,
        etiqueta: 'Serie',
        valor: _valorInformado(bicicleta.numeroSerie),
      ),
      _DatoBicicletaInfo(
        icono: bicicleta.dentroBicicletero
            ? Icons.lock_outline
            : Icons.lock_open_outlined,
        etiqueta: 'Uso actual',
        valor: usoActual,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reducimos el breakpoint para asegurar que siempre use 2 columnas en teléfonos normales
        final columnas = constraints.maxWidth < 280 ? 1 : 2;
        const separacion = 10.0;
        final ancho =
            (constraints.maxWidth - (separacion * (columnas - 1))) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: datos
              .map(
                (dato) => SizedBox(
                  width: ancho,
                  child: dato,
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _valorInformado(String? valor) {
    final limpio = valor?.trim();
    return limpio == null || limpio.isEmpty ? 'No informado' : limpio;
  }
}

class _DatoBicicletaInfo extends StatelessWidget {
  const _DatoBicicletaInfo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresUbb.azulApp.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: ColoresUbb.azulApp, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresUbb.azulApp.withOpacity(0.8),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ColoresUbb.azulNoche,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonGestionBicicleta extends StatelessWidget {
  const _BotonGestionBicicleta({
    required this.expandido,
    required this.onTap,
  });

  final bool expandido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresUbb.bordeFuerte),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: ColoresUbb.azulApp),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestionar bicicleta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresUbb.azulOscuro,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Icon(
                  expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColoresUbb.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelGestionBicicleta extends StatelessWidget {
  const _PanelGestionBicicleta({
    required this.bicicleta,
    required this.onCambiarActiva,
    required this.onEditar,
    required this.onEliminar,
  });

  final BicicletaApp bicicleta;
  final ValueChanged<bool> onCambiarActiva;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresUbb.fondo,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColoresUbb.borde),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: ColoresUbb.azulApp,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bicicleta.activa ? 'Activa' : 'Inactiva',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          'Solo una bicicleta puede quedar activa.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColoresUbb.textoSecundario,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: bicicleta.activa,
                    onChanged: (valor) => onCambiarActiva(valor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEliminar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresUbb.rojoInstitucional,
                      side: const BorderSide(
                        color: ColoresUbb.rojoInstitucional,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagenBicicleta extends StatelessWidget {
  const _ImagenBicicleta({required this.fotoDataUrl});

  final String fotoDataUrl;

  @override
  Widget build(BuildContext context) {
    final bytesFoto = _decodificarFotoDataUrl(fotoDataUrl);
    if (bytesFoto == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 150,
          width: double.infinity,
          color: ColoresUbb.superficieAzulSuave,
          child: const Icon(
            Icons.pedal_bike_outlined,
            color: ColoresUbb.azulApp,
            size: 46,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytesFoto,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _QrTemporal extends StatelessWidget {
  const _QrTemporal({
    required this.token,
    required this.segundosRestantes,
  });

  final String token;
  final int segundosRestantes;

  @override
  Widget build(BuildContext context) {
    final expirado = segundosRestantes <= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoDisponible =
            constraints.maxWidth.isFinite ? constraints.maxWidth - 28 : 240.0;
        final dimensionQr = anchoDisponible.clamp(160.0, 240.0).toDouble();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresUbb.bordeFuerte),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: expirado ? 0.22 : 1,
                  child: QrImageView(
                    data: token,
                    version: QrVersions.auto,
                    size: dimensionQr,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: ColoresUbb.azulOscuro,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: ColoresUbb.azulOscuro,
                    ),
                  ),
                ),
                if (expirado)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColoresUbb.rojoInstitucional,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'Expirado',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EstadoLista extends StatelessWidget {
  const _EstadoLista({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Card(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColoresUbb.azulApp.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: ColoresUbb.azulApp, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloApartado extends StatelessWidget {
  const _TituloApartado({required this.titulo, this.onRefresh});

  final String titulo;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Actualizar',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    );
  }
}

class _TarjetaBicicleteroApp extends StatelessWidget {
  const _TarjetaBicicleteroApp({required this.bicicletero});

  final BicicleteroApp bicicletero;

  @override
  Widget build(BuildContext context) {
    final uso = (bicicletero.porcentajeUso / 100).clamp(0.0, 1.0);
    final colorOcupado = uso >= 0.9 ? ColoresUbb.rojoInstitucional : ColoresUbb.azulApp;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulApp.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined, color: ColoresUbb.azulApp, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bicicletero.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bicicletero.ubicacion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                ChipEstado(
                  texto: '${bicicletero.porcentajeUso}%',
                  color: colorOcupado,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 28,
                      sections: [
                        PieChartSectionData(
                          value: bicicletero.ocupados.toDouble(),
                          color: colorOcupado,
                          title: '',
                          radius: 12,
                        ),
                        PieChartSectionData(
                          value: bicicletero.cuposDisponibles.toDouble(),
                          color: ColoresUbb.superficieAzul,
                          title: '',
                          radius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DatoCompactoIcono(
                        etiqueta: 'Disponibles',
                        valor: '${bicicletero.cuposDisponibles}',
                        color: ColoresUbb.superficieAzul,
                      ),
                      const SizedBox(height: 12),
                      _DatoCompactoIcono(
                        etiqueta: 'Ocupados',
                        valor: '${bicicletero.ocupados}/${bicicletero.capacidad}',
                        color: colorOcupado,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoCompactoIcono extends StatelessWidget {
  const _DatoCompactoIcono({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresUbb.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          valor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _DatoCompacto extends StatelessWidget {
  const _DatoCompacto({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresUbb.textoSecundario,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColoresUbb.azulOscuro,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSolicitudGuardia extends StatelessWidget {
  const _TarjetaSolicitudGuardia({
    required this.solicitud,
    this.mostrarSolicitante = false,
    this.permitirNotificarCentral = false,
    this.mostrarAccionesGuardia = true,
    this.onActualizar,
  });

  final SolicitudGuardiaApp solicitud;
  final bool mostrarSolicitante;
  final bool permitirNotificarCentral;
  final bool mostrarAccionesGuardia;
  final Future<void> Function(String estado)? onActualizar;

  @override
  Widget build(BuildContext context) {
    final cerrada =
        solicitud.estado == 'RESUELTA' || solicitud.estado == 'CANCELADA';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: ColoresUbb.azulApp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solicitud.bicicletero.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: _etiquetaEstadoSolicitud(solicitud.estado),
                  color: _colorEstadoSolicitud(solicitud.estado),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_etiquetaTipoSolicitud(solicitud.tipo)} | ${_formatearFecha(solicitud.creadaEn)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              solicitud.bicicletero.ubicacion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            if (mostrarSolicitante) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Solicitante',
                valor:
                    '${solicitud.solicitante.nombre} | ${solicitud.solicitante.correo}',
              ),
            ],
            if (solicitud.guardiaAsignado != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardia',
                valor: solicitud.guardiaAsignado!.nombre,
              ),
            ],
            if (solicitud.notificadaGuardiaEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Notificado',
                valor: _formatearFecha(solicitud.notificadaGuardiaEn!),
              ),
            ],
            if (solicitud.acuseReciboEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Acuse recibo',
                valor: _formatearFecha(solicitud.acuseReciboEn!),
              ),
            ],
            if (solicitud.guardiasAsignados.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardias asignados',
                valor: solicitud.guardiasAsignados
                    .map((guardia) => guardia.nombre)
                    .join(', '),
              ),
            ],
            if (solicitud.mensaje != null && solicitud.mensaje!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                solicitud.mensaje!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (!cerrada && onActualizar != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (permitirNotificarCentral &&
                      solicitud.guardiaAsignado != null)
                    OutlinedButton.icon(
                      onPressed: solicitud.puedeNotificarGuardia
                          ? () => _actualizar(context, 'NOTIFICADA')
                          : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(_textoBotonNotificarGuardia(solicitud)),
                    ),
                  if (mostrarAccionesGuardia) ...[
                    OutlinedButton.icon(
                      onPressed: solicitud.estado == 'VISTA'
                          ? null
                          : () => _actualizar(context, 'VISTA'),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Acusar recibo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: solicitud.estado == 'EN_CAMINO'
                          ? null
                          : () => _actualizar(context, 'EN_CAMINO'),
                      icon: const Icon(Icons.directions_walk),
                      label: const Text('En camino'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _actualizar(context, 'RESUELTA'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Resolver'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _actualizar(BuildContext context, String estado) async {
    try {
      await onActualizar?.call(estado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Solicitud ${_etiquetaEstadoSolicitud(estado)}')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }
}

String _etiquetaTipoSolicitud(String tipo) {
  return switch (tipo) {
    'GUARDIA_AUSENTE' => 'Guardia ausente',
    'REQUIERE_SERVICIO' => 'Requiere servicio',
    _ => tipo,
  };
}

String _textoBotonNotificarGuardia(SolicitudGuardiaApp solicitud) {
  final segundos = solicitud.segundosParaNotificarGuardia;

  if (solicitud.acuseReciboEn != null ||
      solicitud.estado == 'VISTA' ||
      solicitud.estado == 'EN_CAMINO') {
    return 'Acuse recibido';
  }

  if (segundos != null && segundos > 0) {
    return 'Re-notificar en ${segundos}s';
  }

  return 'Notificar guardia';
}

String _etiquetaEstadoSolicitud(String estado) {
  return switch (estado) {
    'PENDIENTE' => 'Pendiente',
    'NOTIFICADA' => 'Notificada',
    'VISTA' => 'Vista',
    'EN_CAMINO' => 'En camino',
    'RESUELTA' => 'Resuelta',
    'CANCELADA' => 'Cancelada',
    _ => estado,
  };
}

Color _colorEstadoSolicitud(String estado) {
  return switch (estado) {
    'PENDIENTE' => ColoresUbb.rojoInstitucional,
    'NOTIFICADA' => ColoresUbb.azulApp,
    'VISTA' => ColoresUbb.turquesa,
    'EN_CAMINO' => ColoresUbb.azulApp,
    'RESUELTA' => ColoresUbb.exito,
    'CANCELADA' => ColoresUbb.textoSecundario,
    _ => ColoresUbb.azulInstitucional,
  };
}

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
  const _FilaDato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 360 || valor.length > 34;
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({
    required this.titulo,
    required this.detalle,
    required this.icono,
  });

  final String titulo;
  final String detalle;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: ColoresUbb.azulNoche.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresUbb.azulNoche, // Todo azul
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: Colors.blue[300]), // Reemplaza turquesa por azul claro
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.86),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrDemostracion extends StatelessWidget {
  const QrDemostracion({super.key});

  static const patron = [
    1,
    1,
    1,
    0,
    1,
    0,
    1,
    1,
    1,
    1,
    0,
    1,
    0,
    0,
    1,
    1,
    0,
    1,
    1,
    1,
    1,
    1,
    0,
    1,
    1,
    1,
    1,
    0,
    0,
    1,
    0,
    1,
    1,
    0,
    0,
    1,
    1,
    0,
    0,
    1,
    1,
    0,
    1,
    0,
    0,
    0,
    1,
    1,
    0,
    0,
    1,
    0,
    1,
    1,
    1,
    1,
    0,
    1,
    0,
    0,
    1,
    1,
    0,
    1,
    0,
    1,
    1,
    1,
    0,
    0,
    1,
    1,
    1,
    1,
    1,
    0,
    1,
    1,
    1,
    0,
    1,
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColoresUbb.borde, width: 8),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: patron.length,
          itemBuilder: (context, index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color:
                    patron[index] == 1 ? ColoresUbb.azulOscuro : Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}
