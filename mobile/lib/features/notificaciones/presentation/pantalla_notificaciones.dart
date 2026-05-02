import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../shared/modelos/notificacion_app.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../data/notificacion_api.dart';

class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  final notificacionApi = NotificacionApi();
  late Future<List<NotificacionApp>> futuroNotificaciones;

  @override
  void initState() {
    super.initState();
    futuroNotificaciones = notificacionApi.listar();
  }

  Future<void> _recargar() async {
    setState(() {
      futuroNotificaciones = notificacionApi.listar();
    });
  }

  Future<void> _marcarLeidas() async {
    await notificacionApi.marcarTodasLeidas();
    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como leidas',
            onPressed: _marcarLeidas,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: ContenedorResponsivo(
        anchoMaximo: 760,
        child: FutureBuilder<List<NotificacionApp>>(
          future: futuroNotificaciones,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final mensaje = snapshot.error is ExcepcionApi
                  ? (snapshot.error! as ExcepcionApi).mensaje
                  : 'No se pudieron cargar las notificaciones';
              return _EstadoNotificaciones(
                icono: Icons.cloud_off_outlined,
                titulo: 'Sin conexion',
                mensaje: mensaje,
              );
            }

            final notificaciones = snapshot.data ?? [];

            if (notificaciones.isEmpty) {
              return const _EstadoNotificaciones(
                icono: Icons.notifications_none_outlined,
                titulo: 'Sin notificaciones',
                mensaje: 'Aqui veras solicitudes, alertas y cambios de cuenta.',
              );
            }

            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView.separated(
                itemCount: notificaciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _TarjetaNotificacion(
                    notificacion: notificaciones[index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({required this.notificacion});

  final NotificacionApp notificacion;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notificacion.leida ? ColoresUbb.superficie : Colors.white,
      child: ListTile(
        leading: Icon(
          _iconoPorTipo(notificacion.tipo),
          color: notificacion.leida
              ? ColoresUbb.textoSecundario
              : ColoresUbb.azulInstitucional,
        ),
        title: Text(
          notificacion.titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Text(notificacion.mensaje),
        trailing: notificacion.leida
            ? null
            : const ChipEstado(texto: 'Nueva', color: ColoresUbb.exito),
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'CUENTA':
        return Icons.manage_accounts_outlined;
      case 'SOLICITUD_GUARDIA':
        return Icons.support_agent;
      case 'SEGURIDAD':
        return Icons.security_outlined;
      case 'MOVIMIENTO':
        return Icons.history;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class _EstadoNotificaciones extends StatelessWidget {
  const _EstadoNotificaciones({
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: ColoresUbb.azulInstitucional, size: 44),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
