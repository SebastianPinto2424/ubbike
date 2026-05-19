part of '../pantalla_principal.dart';

class VistaAlertasGuardia extends StatefulWidget {
  const VistaAlertasGuardia({super.key});

  @override
  State<VistaAlertasGuardia> createState() => _VistaAlertasGuardiaState();
}

class _VistaAlertasGuardiaState extends State<VistaAlertasGuardia> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<List<SolicitudGuardiaApp>> futuroSolicitudes;
  Timer? temporizadorAlertas;
  Set<String> solicitudesConocidas = {};
  bool solicitudesInicializadas = false;

  @override
  void initState() {
    super.initState();
    futuroSolicitudes = _cargarSolicitudes();
    temporizadorAlertas = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _recargar(avisarNuevas: true),
    );
  }

  @override
  void dispose() {
    temporizadorAlertas?.cancel();
    super.dispose();
  }

  bool _solicitudAbierta(SolicitudGuardiaApp solicitud) {
    return solicitud.estado != 'RESUELTA' && solicitud.estado != 'CANCELADA';
  }

  Future<List<SolicitudGuardiaApp>> _cargarSolicitudes({
    bool avisarNuevas = false,
  }) async {
    final solicitudes = await solicitudGuardiaApi.listarSolicitudes();
    final abiertas = solicitudes.where(_solicitudAbierta).toList();
    final idsAbiertas = abiertas.map((solicitud) => solicitud.id).toSet();
    final nuevas = abiertas
        .where((solicitud) => !solicitudesConocidas.contains(solicitud.id))
        .toList();
    final debeAvisar =
        avisarNuevas && solicitudesInicializadas && nuevas.isNotEmpty;

    solicitudesConocidas = idsAbiertas;
    solicitudesInicializadas = true;

    if (debeAvisar && mounted) {
      final primera = nuevas.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevas.length == 1
                ? 'Nueva alerta en ${primera.bicicletero.nombre}'
                : '${nuevas.length} nuevas alertas asignadas',
          ),
        ),
      );
    }

    return solicitudes;
  }

  void _recargar({bool avisarNuevas = false}) {
    if (!mounted) {
      return;
    }

    setState(() {
      futuroSolicitudes = _cargarSolicitudes(avisarNuevas: avisarNuevas);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Alertas',
          detalle: 'Solicitudes enviadas por usuarios o central.',
          icono: Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<SolicitudGuardiaApp>>(
          future: futuroSolicitudes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar alertas',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final solicitudes = snapshot.data ?? [];

            if (solicitudes.isEmpty) {
              return const _EstadoLista(
                icono: Icons.notifications_active_outlined,
                titulo: 'Sin alertas',
                detalle: 'No hay solicitudes asignadas por ahora.',
              );
            }

            return Column(
              children: solicitudes
                  .map(
                    (solicitud) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaSolicitudGuardia(
                        solicitud: solicitud,
                        mostrarSolicitante: true,
                        onActualizar: (estado) async {
                          await solicitudGuardiaApi.actualizarEstado(
                            solicitudId: solicitud.id,
                            estado: estado,
                          );
                          _recargar();
                        },
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
