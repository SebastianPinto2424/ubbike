part of '../pantalla_principal.dart';

class VistaSoporteUsuario extends StatelessWidget {
  const VistaSoporteUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VistaSoporteConTabs(
      titulo: 'Soporte',
      tabs: [
        Tab(icon: Icon(Icons.support_agent), text: 'Guardia'),
        Tab(icon: Icon(Icons.report_problem_outlined), text: 'Incidencias'),
      ],
      vistas: [
        VistaSolicitarGuardia(),
        VistaIncidencias(
          mostrarReportante: false,
          puedeGestionar: false,
          permitirBicicletaPropia: true,
        ),
      ],
    );
  }
}

class VistaSoporteGuardia extends StatelessWidget {
  const VistaSoporteGuardia({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VistaSoporteConTabs(
      titulo: 'Soporte',
      tabs: [
        Tab(icon: Icon(Icons.notifications_active_outlined), text: 'Alertas'),
        Tab(icon: Icon(Icons.report_problem_outlined), text: 'Incidencias'),
      ],
      vistas: [
        VistaAlertasGuardia(),
        VistaIncidencias(
          mostrarReportante: true,
          puedeGestionar: false,
          gestionGuardia: true,
        ),
      ],
    );
  }
}

class VistaSoporteCentral extends StatelessWidget {
  const VistaSoporteCentral({super.key});

  @override
  Widget build(BuildContext context) {
    return const _VistaSoporteConTabs(
      titulo: 'Soporte',
      tabs: [
        Tab(icon: Icon(Icons.campaign_outlined), text: 'Solicitudes'),
        Tab(icon: Icon(Icons.report_problem_outlined), text: 'Incidencias'),
      ],
      vistas: [
        VistaSolicitudesCentral(),
        VistaIncidencias(
          mostrarReportante: true,
          puedeGestionar: true,
          gestionCentral: true,
        ),
      ],
    );
  }
}

class _VistaSoporteConTabs extends StatelessWidget {
  const _VistaSoporteConTabs({
    required this.titulo,
    required this.tabs,
    required this.vistas,
  });

  final String titulo;
  final List<Tab> tabs;
  final List<Widget> vistas;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: TabBar(
              tabs: tabs,
              labelColor: ColoresUbb.azulApp,
              unselectedLabelColor: ColoresUbb.textoSecundario,
              indicatorColor: ColoresUbb.azulApp,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(children: vistas),
          ),
        ],
      ),
    );
  }
}
