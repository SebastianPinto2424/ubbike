part of '../pantalla_principal.dart';

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
