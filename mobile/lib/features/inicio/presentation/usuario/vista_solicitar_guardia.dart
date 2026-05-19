part of '../pantalla_principal.dart';

class VistaSolicitarGuardia extends StatefulWidget {
  const VistaSolicitarGuardia({super.key});

  @override
  State<VistaSolicitarGuardia> createState() => _VistaSolicitarGuardiaState();
}

class _VistaSolicitarGuardiaState extends State<VistaSolicitarGuardia> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  final mensajeController = TextEditingController();
  List<BicicleteroApp> bicicleteros = [];
  BicicleteroApp? bicicleteroSeleccionado;
  String tipoSolicitud = 'REQUIERE_SERVICIO';
  late Future<List<SolicitudGuardiaApp>> futuroSolicitudes;
  bool cargando = true;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
    _cargarBicicleteros();
  }

  @override
  void dispose() {
    mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarBicicleteros() async {
    try {
      final datos = await solicitudGuardiaApi.listarBicicleteros();
      if (mounted) {
        setState(() {
          bicicleteros = datos;
          bicicleteroSeleccionado = datos.isEmpty ? null : datos.first;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _enviarSolicitud() async {
    final bicicletero = bicicleteroSeleccionado;

    if (bicicletero == null || enviando) {
      return;
    }

    setState(() => enviando = true);

    try {
      await solicitudGuardiaApi.crearSolicitud(
        bicicleteroId: bicicletero.id,
        tipo: tipoSolicitud,
        mensaje: mensajeController.text.trim(),
      );

      if (mounted) {
        mensajeController.clear();
        setState(() {
          futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada al guardia con copia a central'),
          ),
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

  Future<void> _notificarGuardia(SolicitudGuardiaApp solicitud) async {
    if (enviando) {
      return;
    }

    setState(() => enviando = true);

    try {
      await solicitudGuardiaApi.notificarGuardia(solicitudId: solicitud.id);

      if (mounted) {
        setState(() {
          futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardia notificado nuevamente')),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _EncabezadoSeccion(
          titulo: 'Guardia',
          detalle:
              'Solicita apoyo y revisa si el guardia ya fue notificado o va en camino.',
          icono: Icons.support_agent,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side:
                BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cargando)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(
                      color: ColoresUbb.azulApp.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<BicicleteroApp>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      menuMaxHeight: 300,
                      initialValue: bicicleteroSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Bicicletero',
                        prefixIcon: Icon(Icons.location_on_outlined,
                            color: ColoresUbb.azulApp),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: Colors.white,
                      items: bicicleteros
                          .map(
                            (bicicletero) => DropdownMenuItem(
                              value: bicicletero,
                              child: Text(
                                bicicletero.nombre,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        setState(() => bicicleteroSeleccionado = valor);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _FiltroChip(
                      label: 'Requiere servicio',
                      value: 'REQUIERE_SERVICIO',
                      selectedValue: tipoSolicitud,
                      icon: Icons.notifications_active_outlined,
                      onTap: (v) => setState(() => tipoSolicitud = v),
                    ),
                    _FiltroChip(
                      label: 'Guardia ausente',
                      value: 'GUARDIA_AUSENTE',
                      selectedValue: tipoSolicitud,
                      icon: Icons.person_off_outlined,
                      onTap: (v) => setState(() => tipoSolicitud = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulApp.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: mensajeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje para el guardia (opcional)',
                      hintText: 'Ejemplo: estoy esperando en el acceso norte.',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColoresUbb.azulApp,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed:
                      bicicleteroSeleccionado == null ? null : _enviarSolicitud,
                  icon: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined, color: Colors.white),
                  label: Text(
                    enviando ? 'Enviando...' : 'Solicitar atencion',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<SolicitudGuardiaApp>>(
          future: futuroSolicitudes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar tus solicitudes',
                detalle: '${snapshot.error}',
                color: ColoresUbb.rojoInstitucional,
                onTap: () {
                  setState(() {
                    futuroSolicitudes = solicitudGuardiaApi.listarSolicitudes();
                  });
                },
              );
            }

            final solicitudes = snapshot.data ?? [];

            if (solicitudes.isEmpty) {
              return const _EstadoLista(
                icono: Icons.support_agent,
                titulo: 'Sin solicitudes recientes',
                detalle: 'Cuando solicites apoyo, el estado aparecera aqui.',
              );
            }

            return Column(
              children: solicitudes
                  .map(
                    (solicitud) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaSolicitudGuardia(
                        solicitud: solicitud,
                        mostrarAccionesGuardia: false,
                        permitirNotificarUsuario: true,
                        onNotificarGuardia: () => _notificarGuardia(solicitud),
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
