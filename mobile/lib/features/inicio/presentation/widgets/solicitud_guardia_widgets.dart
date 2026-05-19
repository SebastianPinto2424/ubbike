part of '../pantalla_principal.dart';

class _TarjetaSolicitudGuardia extends StatelessWidget {
  const _TarjetaSolicitudGuardia({
    required this.solicitud,
    this.mostrarSolicitante = false,
    this.permitirNotificarCentral = false,
    this.permitirNotificarUsuario = false,
    this.mostrarAccionesGuardia = true,
    this.onActualizar,
    this.onNotificarGuardia,
  });

  final SolicitudGuardiaApp solicitud;
  final bool mostrarSolicitante;
  final bool permitirNotificarCentral;
  final bool permitirNotificarUsuario;
  final bool mostrarAccionesGuardia;
  final Future<void> Function(String estado)? onActualizar;
  final Future<void> Function()? onNotificarGuardia;

  @override
  Widget build(BuildContext context) {
    final cerrada =
        solicitud.estado == 'RESUELTA' || solicitud.estado == 'CANCELADA';
    final mensaje = solicitud.mensaje?.trim();
    final etiquetaMensaje =
        mostrarSolicitante ? 'Mensaje del solicitante' : 'Mensaje enviado';

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
              _etiquetaTipoSolicitud(solicitud.tipo),
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
            const SizedBox(height: 8),
            _FilaDato(
              etiqueta: 'Fecha solicitud',
              valor: _formatearFecha(solicitud.creadaEn),
            ),
            _FilaDato(
              etiqueta: 'Hora solicitud',
              valor: _formatearHora(solicitud.creadaEn),
            ),
            if (mostrarSolicitante) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Solicitante',
                valor: solicitud.solicitante.nombre,
              ),
              _FilaDato(
                etiqueta: 'Correo solicitante',
                valor: solicitud.solicitante.correo,
                anchoCompleto: true,
              ),
            ],
            if (solicitud.guardiaAsignado != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardia asignado',
                valor: solicitud.guardiaAsignado!.nombre,
              ),
            ],
            if (solicitud.notificadaGuardiaEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardia notificado',
                valor: _formatearFechaHoraSolicitud(
                  solicitud.notificadaGuardiaEn!,
                ),
              ),
            ],
            if (solicitud.notificacionesGuardia > 0) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Avisos enviados',
                valor:
                    '${solicitud.notificacionesGuardia} ${solicitud.notificacionesGuardia == 1 ? 'vez' : 'veces'}',
              ),
            ],
            if (solicitud.ultimaNotificacionUsuarioEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Ultimo recordatorio',
                valor: _formatearFechaHoraSolicitud(
                  solicitud.ultimaNotificacionUsuarioEn!,
                ),
              ),
            ],
            if (solicitud.respondidaPorGuardiaEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Respuesta del guardia',
                valor: _formatearFechaHoraSolicitud(
                  solicitud.respondidaPorGuardiaEn!,
                ),
              ),
            ],
            if (solicitud.enCaminoEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardia en camino desde',
                valor: _formatearFechaHoraSolicitud(solicitud.enCaminoEn!),
              ),
            ],
            if (solicitud.resueltaEn != null) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta:
                    solicitud.estado == 'CANCELADA' ? 'Cancelada' : 'Resuelta',
                valor: _formatearFechaHoraSolicitud(solicitud.resueltaEn!),
              ),
            ],
            if (solicitud.guardiaAsignado == null &&
                solicitud.guardiasAsignados.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FilaDato(
                etiqueta: 'Guardias notificados',
                valor: solicitud.guardiasAsignados
                    .map((guardia) => guardia.nombre)
                    .join(', '),
                anchoCompleto: true,
              ),
            ],
            if (mensaje != null && mensaje.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BloqueMensajeSolicitud(
                titulo: etiquetaMensaje,
                mensaje: mensaje,
              ),
            ],
            if (!cerrada && onActualizar != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (permitirNotificarUsuario && onNotificarGuardia != null)
                    OutlinedButton.icon(
                      onPressed: solicitud.puedeNotificarGuardiaUsuario
                          ? () => _notificarGuardia(context)
                          : null,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        solicitud.notificacionesGuardia > 0
                            ? 'Recordar al guardia'
                            : 'Avisar al guardia',
                      ),
                    ),
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
                      onPressed: solicitud.estado == 'EN_CAMINO'
                          ? null
                          : () => _actualizar(context, 'EN_CAMINO'),
                      icon: const Icon(Icons.directions_walk),
                      label: const Text('Voy en camino'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _actualizar(context, 'RESUELTA'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar resuelta'),
                    ),
                  ],
                ],
              ),
            ],
            if (!cerrada &&
                onActualizar == null &&
                permitirNotificarUsuario &&
                onNotificarGuardia != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: solicitud.puedeNotificarGuardiaUsuario
                    ? () => _notificarGuardia(context)
                    : null,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  solicitud.guardiaAsignado == null
                      ? 'Central avisada'
                      : 'Recordar al guardia',
                ),
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

  Future<void> _notificarGuardia(BuildContext context) async {
    try {
      await onNotificarGuardia?.call();
    } on ExcepcionApi catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }
}

class _BloqueMensajeSolicitud extends StatelessWidget {
  const _BloqueMensajeSolicitud({
    required this.titulo,
    required this.mensaje,
  });

  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
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

  if (solicitud.respondidaPorGuardiaEn != null ||
      solicitud.estado == 'EN_CAMINO') {
    return solicitud.estado == 'EN_CAMINO'
        ? 'Guardia en camino'
        : 'Guardia respondio';
  }

  if (segundos != null && segundos > 0) {
    return 'Reenviar en ${segundos}s';
  }

  return solicitud.notificacionesGuardia > 0
      ? 'Reenviar aviso'
      : 'Avisar guardia';
}

String _etiquetaEstadoSolicitud(String estado) {
  return switch (estado) {
    'PENDIENTE' => 'Pendiente',
    'NOTIFICADA' => 'Guardia notificado',
    'EN_CAMINO' => 'Guardia en camino',
    'RESUELTA' => 'Resuelta',
    'CANCELADA' => 'Cancelada',
    _ => estado,
  };
}

Color _colorEstadoSolicitud(String estado) {
  return switch (estado) {
    'PENDIENTE' => ColoresUbb.rojoInstitucional,
    'NOTIFICADA' => ColoresUbb.azulApp,
    'EN_CAMINO' => ColoresUbb.turquesa,
    'RESUELTA' => ColoresUbb.exito,
    'CANCELADA' => ColoresUbb.textoSecundario,
    _ => ColoresUbb.azulInstitucional,
  };
}

String _formatearFechaHoraSolicitud(DateTime fecha) {
  return '${_formatearFecha(fecha)} ${_formatearHora(fecha)}';
}
