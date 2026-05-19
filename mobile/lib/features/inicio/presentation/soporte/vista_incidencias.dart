part of '../pantalla_principal.dart';

class VistaIncidencias extends StatefulWidget {
  const VistaIncidencias({
    super.key,
    required this.mostrarReportante,
    required this.puedeGestionar,
    this.permitirBicicletaPropia = false,
    this.gestionGuardia = false,
    this.gestionCentral = false,
  });

  final bool mostrarReportante;
  final bool puedeGestionar;
  final bool permitirBicicletaPropia;
  final bool gestionGuardia;
  final bool gestionCentral;

  @override
  State<VistaIncidencias> createState() => _VistaIncidenciasState();
}

class _VistaIncidenciasState extends State<VistaIncidencias> {
  final incidenciaApi = IncidenciaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  final bicicletaApi = BicicletaApi();
  final descripcionController = TextEditingController();
  final busquedaController = TextEditingController();
  late Future<List<IncidenciaApp>> futuroIncidencias;
  List<BicicleteroApp> bicicleteros = [];
  List<BicicletaApp> bicicletas = [];
  BicicleteroApp? bicicleteroSeleccionado;
  BicicletaApp? bicicletaSeleccionada;
  String tipoSeleccionado = 'OTRO';
  String estadoFiltro = 'TODOS';
  String tipoFiltro = 'TODOS';
  bool cargandoFormulario = true;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    futuroIncidencias = _cargarIncidencias();
    _cargarFormulario();
  }

  @override
  void dispose() {
    descripcionController.dispose();
    busquedaController.dispose();
    super.dispose();
  }

  Future<List<IncidenciaApp>> _cargarIncidencias() {
    return incidenciaApi.listar(
      estado: estadoFiltro,
      tipo: tipoFiltro,
      q: busquedaController.text,
    );
  }

  Future<void> _cargarFormulario() async {
    try {
      final datosBicicletero = widget.gestionGuardia
          ? await solicitudGuardiaApi.obtenerBicicleteroGestionado()
          : null;
      final bicicleterosDisponibles = widget.gestionGuardia
          ? [
              if (datosBicicletero != null) datosBicicletero,
            ]
          : await solicitudGuardiaApi.listarBicicleteros();
      final bicicletasUsuario = widget.permitirBicicletaPropia
          ? await bicicletaApi.listar()
          : <BicicletaApp>[];

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteros = bicicleterosDisponibles;
        bicicletas = bicicletasUsuario;
        bicicleteroSeleccionado =
            bicicleterosDisponibles.isEmpty ? null : bicicleterosDisponibles.first;
        cargandoFormulario = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => cargandoFormulario = false);
      }
    }
  }

  void _recargar() {
    setState(() {
      futuroIncidencias = _cargarIncidencias();
    });
  }

  Future<void> _crearIncidencia() async {
    final bicicletero = bicicleteroSeleccionado;
    final descripcion = descripcionController.text.trim();

    if (bicicletero == null || descripcion.length < 8 || enviando) {
      return;
    }

    setState(() => enviando = true);

    try {
      await incidenciaApi.crear(
        bicicleteroId: bicicletero.id,
        tipo: tipoSeleccionado,
        descripcion: descripcion,
        bicicletaId: bicicletaSeleccionada?.id,
      );

      if (mounted) {
        descripcionController.clear();
        setState(() {
          bicicletaSeleccionada = null;
          tipoSeleccionado = 'OTRO';
          futuroIncidencias = _cargarIncidencias();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidencia registrada correctamente')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => enviando = false);
      }
    }
  }

  Future<void> _actualizarEstado(IncidenciaApp incidencia, String estado) async {
    final respuesta = await _pedirRespuestaGestion(
      incidencia: incidencia,
      estado: estado,
    );

    if (respuesta == null && estado != 'EN_REVISION') {
      return;
    }

    try {
      await incidenciaApi.actualizarEstado(
        incidenciaId: incidencia.id,
        estado: estado,
        respuesta: respuesta,
      );

      if (mounted) {
        _recargar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incidencia ${_etiquetaEstadoIncidencia(estado).toLowerCase()}')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }

  Future<String?> _pedirRespuestaGestion({
    required IncidenciaApp incidencia,
    required String estado,
  }) async {
    if (estado == 'EN_REVISION') {
      return '';
    }

    final controller = TextEditingController(text: incidencia.respuesta ?? '');

    final respuesta = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_etiquetaEstadoIncidencia(estado)),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Respuesta de cierre',
              hintText: 'Explica la resolución o el motivo del cierre.',
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final texto = controller.text.trim();

                if (texto.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La respuesta debe explicar el cierre.'),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop(texto);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return respuesta;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: widget.gestionCentral ? 'Incidencias y revisión' : 'Incidencias',
          detalle: widget.gestionCentral
              ? 'Revisa, filtra y gestiona reportes operativos del sistema.'
              : 'Registra y revisa problemas asociados a bicicleteros o bicicletas.',
          icono: Icons.report_problem_outlined,
        ),
        const SizedBox(height: 16),
        _FormularioIncidencia(
          cargando: cargandoFormulario,
          enviando: enviando,
          bicicleteros: bicicleteros,
          bicicletas: bicicletas,
          bicicleteroSeleccionado: bicicleteroSeleccionado,
          bicicletaSeleccionada: bicicletaSeleccionada,
          tipoSeleccionado: tipoSeleccionado,
          descripcionController: descripcionController,
          permitirBicicletaPropia: widget.permitirBicicletaPropia,
          onBicicletero: (valor) => setState(() => bicicleteroSeleccionado = valor),
          onBicicleta: (valor) => setState(() => bicicletaSeleccionada = valor),
          onTipo: (valor) => setState(() => tipoSeleccionado = valor),
          onEnviar: _crearIncidencia,
        ),
        const SizedBox(height: 16),
        _FiltrosIncidencias(
          estado: estadoFiltro,
          tipo: tipoFiltro,
          busquedaController: busquedaController,
          onEstado: (valor) {
            setState(() {
              estadoFiltro = valor;
              futuroIncidencias = _cargarIncidencias();
            });
          },
          onTipo: (valor) {
            setState(() {
              tipoFiltro = valor;
              futuroIncidencias = _cargarIncidencias();
            });
          },
          onBuscar: _recargar,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<IncidenciaApp>>(
          future: futuroIncidencias,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar incidencias',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final incidencias = snapshot.data ?? [];

            if (incidencias.isEmpty) {
              return const _EstadoLista(
                icono: Icons.report_problem_outlined,
                titulo: 'Sin incidencias',
                detalle: 'Cuando exista un reporte operativo aparecera aqui.',
              );
            }

            return Column(
              children: incidencias
                  .map(
                    (incidencia) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaIncidencia(
                        incidencia: incidencia,
                        mostrarReportante: widget.mostrarReportante,
                        puedeGestionar: widget.puedeGestionar,
                        gestionGuardia: widget.gestionGuardia,
                        onActualizarEstado: (estado) =>
                            _actualizarEstado(incidencia, estado),
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

class _FormularioIncidencia extends StatelessWidget {
  const _FormularioIncidencia({
    required this.cargando,
    required this.enviando,
    required this.bicicleteros,
    required this.bicicletas,
    required this.bicicleteroSeleccionado,
    required this.bicicletaSeleccionada,
    required this.tipoSeleccionado,
    required this.descripcionController,
    required this.permitirBicicletaPropia,
    required this.onBicicletero,
    required this.onBicicleta,
    required this.onTipo,
    required this.onEnviar,
  });

  final bool cargando;
  final bool enviando;
  final List<BicicleteroApp> bicicleteros;
  final List<BicicletaApp> bicicletas;
  final BicicleteroApp? bicicleteroSeleccionado;
  final BicicletaApp? bicicletaSeleccionada;
  final String tipoSeleccionado;
  final TextEditingController descripcionController;
  final bool permitirBicicletaPropia;
  final ValueChanged<BicicleteroApp?> onBicicletero;
  final ValueChanged<BicicletaApp?> onBicicleta;
  final ValueChanged<String> onTipo;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar incidencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            if (cargando)
              const Center(child: CircularProgressIndicator())
            else if (bicicleteros.isEmpty)
              const _AvisoFormularioIncidencia(
                icono: Icons.location_off_outlined,
                titulo: 'Sin bicicletero disponible',
                detalle: 'No hay un bicicletero disponible para asociar el reporte.',
              )
            else ...[
              DropdownButtonFormField<BicicleteroApp>(
                isExpanded: true,
                initialValue: bicicleteroSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Bicicletero',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: bicicleteros
                    .map(
                      (bicicletero) => DropdownMenuItem(
                        value: bicicletero,
                        child: Text(
                          bicicletero.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: enviando ? null : onBicicletero,
              ),
              const SizedBox(height: 12),
              if (permitirBicicletaPropia)
                DropdownButtonFormField<BicicletaApp?>(
                  isExpanded: true,
                  initialValue: bicicletaSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Bicicleta asociada (opcional)',
                    prefixIcon: Icon(Icons.pedal_bike_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<BicicletaApp?>(
                      value: null,
                      child: Text('Sin bicicleta asociada'),
                    ),
                    ...bicicletas.map(
                      (bicicleta) => DropdownMenuItem<BicicletaApp?>(
                        value: bicicleta,
                        child: Text(
                          bicicleta.descripcion,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: enviando ? null : onBicicleta,
                ),
              if (permitirBicicletaPropia) const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de incidencia',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _tiposIncidencia
                    .map(
                      (tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(_etiquetaTipoIncidencia(tipo)),
                      ),
                    )
                    .toList(),
                onChanged: enviando ? null : (valor) => onTipo(valor ?? 'OTRO'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descripcionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe el problema con claridad.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: enviando ? null : onEnviar,
                icon: enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(enviando ? 'Registrando' : 'Registrar incidencia'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvisoFormularioIncidencia extends StatelessWidget {
  const _AvisoFormularioIncidencia({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresUbb.azulApp.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: ColoresUbb.azulApp),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
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

class _FiltrosIncidencias extends StatelessWidget {
  const _FiltrosIncidencias({
    required this.estado,
    required this.tipo,
    required this.busquedaController,
    required this.onEstado,
    required this.onTipo,
    required this.onBuscar,
  });

  final String estado;
  final String tipo;
  final TextEditingController busquedaController;
  final ValueChanged<String> onEstado;
  final ValueChanged<String> onTipo;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: busquedaController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onBuscar(),
              decoration: InputDecoration(
                labelText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: onBuscar,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in ['TODOS', 'PENDIENTE', 'EN_REVISION', 'RESUELTA'])
                  _FiltroChip(
                    label: _etiquetaEstadoIncidencia(item),
                    value: item,
                    selectedValue: estado,
                    onTap: onEstado,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FiltroChip(
                  label: 'Todos los tipos',
                  value: 'TODOS',
                  selectedValue: tipo,
                  onTap: onTipo,
                ),
                for (final item in _tiposIncidencia)
                  _FiltroChip(
                    label: _etiquetaTipoIncidencia(item),
                    value: item,
                    selectedValue: tipo,
                    onTap: onTipo,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaIncidencia extends StatelessWidget {
  const _TarjetaIncidencia({
    required this.incidencia,
    required this.mostrarReportante,
    required this.puedeGestionar,
    required this.gestionGuardia,
    required this.onActualizarEstado,
  });

  final IncidenciaApp incidencia;
  final bool mostrarReportante;
  final bool puedeGestionar;
  final bool gestionGuardia;
  final ValueChanged<String> onActualizarEstado;

  @override
  Widget build(BuildContext context) {
    final cerrada =
        incidencia.estado == 'RESUELTA' || incidencia.estado == 'DESCARTADA';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.report_problem_outlined,
                    color: ColoresUbb.azulApp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _etiquetaTipoIncidencia(incidencia.tipo),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: _etiquetaEstadoIncidencia(incidencia.estado),
                  color: _colorEstadoIncidencia(incidencia.estado),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              incidencia.descripcion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _FilaDato(
              etiqueta: 'Bicicletero',
              valor: incidencia.bicicletero.nombre,
            ),
            _FilaDato(
              etiqueta: 'Fecha',
              valor: _formatearFecha(incidencia.creadaEn),
            ),
            _FilaDato(
              etiqueta: 'Hora',
              valor: _formatearHora(incidencia.creadaEn),
            ),
            if (incidencia.bicicleta != null)
              _FilaDato(
                etiqueta: 'Bicicleta',
                valor: incidencia.bicicleta!.descripcion,
              ),
            if (mostrarReportante)
              _FilaDato(
                etiqueta: 'Reportada por',
                valor: incidencia.reportadaPorUsuario.nombre,
                anchoCompleto: true,
              ),
            if (incidencia.gestionadaPorUsuario != null)
              _FilaDato(
                etiqueta: 'Gestionada por',
                valor: incidencia.gestionadaPorUsuario!.nombre,
                anchoCompleto: true,
              ),
            if (incidencia.respuesta != null &&
                incidencia.respuesta!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _BloqueMensajeSolicitud(
                titulo: 'Respuesta de gestión',
                mensaje: incidencia.respuesta!,
              ),
            ],
            if (puedeGestionar && !cerrada) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: incidencia.estado == 'EN_REVISION'
                        ? null
                        : () => onActualizarEstado('EN_REVISION'),
                    icon: const Icon(Icons.manage_search_outlined),
                    label: const Text('En revisión'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onActualizarEstado('RESUELTA'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Resolver'),
                  ),
                  if (!gestionGuardia)
                    TextButton.icon(
                      onPressed: () => onActualizarEstado('DESCARTADA'),
                      icon: const Icon(Icons.block_outlined),
                      label: const Text('Descartar'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const List<String> _tiposIncidencia = [
  'PROBLEMA_QR',
  'DANO_BICICLETA',
  'DANO_INFRAESTRUCTURA',
  'PROBLEMA_MOVIMIENTO',
  'USUARIO_DATOS',
  'OTRO',
];

String _etiquetaTipoIncidencia(String tipo) {
  return switch (tipo) {
    'PROBLEMA_QR' => 'Problema con QR',
    'DANO_BICICLETA' => 'Daño de bicicleta',
    'DANO_INFRAESTRUCTURA' => 'Daño de infraestructura',
    'PROBLEMA_MOVIMIENTO' => 'Problema de movimiento',
    'USUARIO_DATOS' => 'Datos de usuario',
    'OTRO' => 'Otro',
    _ => tipo,
  };
}

String _etiquetaEstadoIncidencia(String estado) {
  return switch (estado) {
    'TODOS' => 'Todos',
    'PENDIENTE' => 'Pendiente',
    'EN_REVISION' => 'En revisión',
    'RESUELTA' => 'Resuelta',
    'DESCARTADA' => 'Descartada',
    _ => estado,
  };
}

Color _colorEstadoIncidencia(String estado) {
  return switch (estado) {
    'PENDIENTE' => ColoresUbb.rojoInstitucional,
    'EN_REVISION' => ColoresUbb.azulApp,
    'RESUELTA' => ColoresUbb.exito,
    'DESCARTADA' => ColoresUbb.textoSecundario,
    _ => ColoresUbb.azulInstitucional,
  };
}
