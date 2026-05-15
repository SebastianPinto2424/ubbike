part of '../pantalla_principal.dart';

class VistaSolicitudesCentral extends StatefulWidget {
  const VistaSolicitudesCentral({super.key});

  @override
  State<VistaSolicitudesCentral> createState() =>
      _VistaSolicitudesCentralState();
}

class _VistaSolicitudesCentralState extends State<VistaSolicitudesCentral> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<List<SolicitudGuardiaApp>> futuroSolicitudes;

  @override
  void initState() {
    super.initState();
    futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
  }

  void _recargar() {
    setState(() {
      futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Solicitudes',
          detalle: 'Prioriza atencion y coordina guardias por bicicletero.',
          icono: Icons.campaign_outlined,
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
                titulo: 'No se pudieron cargar solicitudes',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final solicitudes = snapshot.data ?? [];

            if (solicitudes.isEmpty) {
              return const _EstadoLista(
                icono: Icons.campaign_outlined,
                titulo: 'Sin solicitudes',
                detalle: 'No hay solicitudes de guardia registradas.',
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
                        permitirNotificarCentral: true,
                        mostrarAccionesGuardia: false,
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
