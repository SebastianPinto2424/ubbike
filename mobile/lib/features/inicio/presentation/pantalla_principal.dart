import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/tema/colores_ubb.dart';
import '../../../core/servicios/excepcion_api.dart';
import '../../../features/acceso/data/solicitud_guardia_api.dart';
import '../../../features/admin/presentation/vista_gestion_usuarios.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../features/auth/presentation/pantalla_login.dart';
import '../../../features/bicicletas/data/bicicleta_api.dart';
import '../../../features/acceso/data/acceso_api.dart';
import '../../../features/historial/data/historial_api.dart';
import '../../../features/notificaciones/presentation/pantalla_notificaciones.dart';
import '../../../features/qr/data/qr_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/datos_demo.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/servicios/sesion_actual.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import '../../../shared/widgets/tarjeta_accion.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, required this.rol});

  final RolUsuario rol;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int indice = 0;

  @override
  Widget build(BuildContext context) {
    final destinos = _destinosPorRol(widget.rol);
    final paginas = _paginasPorRol(widget.rol);

    return Scaffold(
      appBar: AppBar(
        title: const MarcaUbbike(compacta: true, sobreAzul: true),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PantallaNotificaciones(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () {
              SesionActual.cerrar();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PantallaLogin()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ContenedorResponsivo(
        anchoMaximo: 940,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: paginas[indice],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (nuevoIndice) =>
            setState(() => indice = nuevoIndice),
        destinations: destinos,
      ),
    );
  }

  List<NavigationDestination> _destinosPorRol(RolUsuario rol) {
    if (rol == RolUsuario.guardia) {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'QR'),
        NavigationDestination(
            icon: Icon(Icons.edit_note_outlined), label: 'Manual'),
        NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined), label: 'Alertas'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Perfil'),
      ];
    }

    if (rol == RolUsuario.adminCentral) {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), label: 'Inicio'),
        NavigationDestination(
            icon: Icon(Icons.manage_search_outlined), label: 'Movimientos'),
        NavigationDestination(
            icon: Icon(Icons.security_outlined), label: 'Guardias'),
        NavigationDestination(
            icon: Icon(Icons.campaign_outlined), label: 'Solicitudes'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Perfil'),
      ];
    }

    if (rol == RolUsuario.administrador) {
      return const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), label: 'Inicio'),
        NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined), label: 'Usuarios'),
        NavigationDestination(
            icon: Icon(Icons.campaign_outlined), label: 'Solicitudes'),
        NavigationDestination(
            icon: Icon(Icons.security_outlined), label: 'Guardias'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Perfil'),
      ];
    }

    return const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.pedal_bike), label: 'Bicicletas'),
      NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'QR'),
      NavigationDestination(icon: Icon(Icons.support_agent), label: 'Guardia'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
    ];
  }

  List<Widget> _paginasPorRol(RolUsuario rol) {
    if (rol == RolUsuario.guardia) {
      return const [
        VistaInicioGuardia(),
        VistaEscanerQrGuardia(),
        VistaGestionManualGuardia(),
        VistaAlertasGuardia(),
        VistaPerfil(rol: RolUsuario.guardia),
      ];
    }

    if (rol == RolUsuario.adminCentral) {
      return const [
        VistaDashboardCentral(),
        VistaMovimientosCentral(),
        VistaOperacionesGuardiasCentral(),
        VistaSolicitudesCentral(),
        VistaPerfil(rol: RolUsuario.adminCentral),
      ];
    }

    if (rol == RolUsuario.administrador) {
      return const [
        VistaDashboardCentral(),
        VistaGestionUsuarios(),
        VistaSolicitudesCentral(),
        VistaOperacionesGuardiasCentral(),
        VistaPerfil(rol: RolUsuario.administrador),
      ];
    }

    return [
      const VistaInicioUsuario(),
      const VistaBicicletas(),
      const VistaQrUsuario(),
      const VistaSolicitarGuardia(),
      VistaPerfil(rol: rol),
    ];
  }
}

class VistaInicioUsuario extends StatelessWidget {
  const VistaInicioUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Inicio',
          detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
          icono: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        const _EstadoActualUsuario(),
        const SizedBox(height: 16),
        Text(
          'Bicicleteros',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...bicicleterosDemo.map(
          (bicicletero) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TarjetaBicicletero(bicicletero: bicicletero),
          ),
        ),
      ],
    );
  }
}

class _EstadoActualUsuario extends StatelessWidget {
  const _EstadoActualUsuario();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColoresUbb.azulInstitucional,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_open_outlined, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              'Sin bicicleta dentro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando llegues, genera un QR temporal y presentalo al guardia.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaBicicletas extends StatefulWidget {
  const VistaBicicletas({super.key});

  @override
  State<VistaBicicletas> createState() => _VistaBicicletasState();
}

class _VistaBicicletasState extends State<VistaBicicletas> {
  final bicicletaApi = BicicletaApi();
  late Future<List<BicicletaApp>> futuroBicicletas;

  @override
  void initState() {
    super.initState();
    futuroBicicletas = bicicletaApi.listar();
  }

  void _recargar() {
    setState(() {
      futuroBicicletas = bicicletaApi.listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Bicicletas',
          detalle: 'Administra las bicicletas asociadas a tu cuenta.',
          icono: Icons.pedal_bike,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<BicicletaApp>>(
          future: futuroBicicletas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _EstadoLista(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar bicicletas',
                detalle: 'Revisa que el backend este activo.',
              );
            }

            final bicicletas = snapshot.data ?? [];

            if (bicicletas.isEmpty) {
              return const _EstadoLista(
                icono: Icons.pedal_bike,
                titulo: 'Sin bicicletas registradas',
                detalle: 'Agrega tu primera bicicleta para generar QR.',
              );
            }

            return Column(
              children: bicicletas
                  .map(
                    (bicicleta) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicletaUsuario(
                        bicicleta: bicicleta,
                        onEditar: () => _mostrarFormularioBicicleta(
                          context,
                          bicicleta: bicicleta,
                        ),
                        onEliminar: () => _eliminarBicicleta(bicicleta),
                        onActivar: bicicleta.activa
                            ? null
                            : () => _activarBicicleta(bicicleta),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        TarjetaAccion(
          icono: Icons.add_circle_outline,
          titulo: 'Registrar bicicleta',
          detalle: 'Agrega descripcion, foto y datos visibles para validacion.',
          onTap: () => _mostrarFormularioBicicleta(context),
        ),
      ],
    );
  }

  Future<void> _activarBicicleta(BicicletaApp bicicleta) async {
    try {
      await bicicletaApi.activar(bicicleta.id);
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bicicleta.descripcion} activada')),
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

  Future<void> _eliminarBicicleta(BicicletaApp bicicleta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bicicleta'),
        content: Text('Se eliminara "${bicicleta.descripcion}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await bicicletaApi.eliminar(bicicleta.id);
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bicicleta eliminada')),
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

  Future<void> _mostrarFormularioBicicleta(
    BuildContext context, {
    BicicletaApp? bicicleta,
  }) async {
    final descripcionController = TextEditingController(
      text: bicicleta?.descripcion ?? '',
    );
    final fotoController =
        TextEditingController(text: bicicleta?.fotoUrl ?? '');
    bool activar = bicicleta?.activa ?? false;

    final guardo = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    bicicleta == null
                        ? 'Registrar bicicleta'
                        : 'Editar bicicleta',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripcion',
                      prefixIcon: Icon(Icons.pedal_bike),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fotoController,
                    decoration: const InputDecoration(
                      labelText: 'URL de foto opcional',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: activar,
                    onChanged: (valor) =>
                        setModalState(() => activar = valor ?? false),
                    title: const Text('Usar como bicicleta activa'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (descripcionController.text.trim().isEmpty) {
                        return;
                      }

                      try {
                        if (bicicleta == null) {
                          await bicicletaApi.crear(
                            descripcion: descripcionController.text.trim(),
                            fotoUrl: fotoController.text.trim().isEmpty
                                ? null
                                : fotoController.text.trim(),
                            activar: activar,
                          );
                        } else {
                          await bicicletaApi.actualizar(
                            bicicletaId: bicicleta.id,
                            descripcion: descripcionController.text.trim(),
                            fotoUrl: fotoController.text.trim().isEmpty
                                ? null
                                : fotoController.text.trim(),
                          );
                          if (activar && !bicicleta.activa) {
                            await bicicletaApi.activar(bicicleta.id);
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } on ExcepcionApi catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.mensaje)),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    descripcionController.dispose();
    fotoController.dispose();

    if (guardo == true) {
      _recargar();
    }
  }
}

class VistaQrUsuario extends StatefulWidget {
  const VistaQrUsuario({super.key});

  @override
  State<VistaQrUsuario> createState() => _VistaQrUsuarioState();
}

class _VistaQrUsuarioState extends State<VistaQrUsuario> {
  final qrApi = QrApi();
  QrTemporalApp? qrActual;
  String tipoOperacion = 'INGRESO';
  bool generando = false;

  @override
  Widget build(BuildContext context) {
    final qr = qrActual;
    final segundosRestantes = qr == null
        ? 0
        : qr.expiraEn.difference(DateTime.now()).inSeconds.clamp(0, 15);

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'QR temporal',
          detalle: 'El codigo dura 15 segundos. Si vence, debe regenerarse.',
          icono: Icons.qr_code_2,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'INGRESO',
                      label: Text('Ingreso'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: 'SALIDA',
                      label: Text('Retiro'),
                      icon: Icon(Icons.logout),
                    ),
                  ],
                  selected: {tipoOperacion},
                  onSelectionChanged: qr == null || segundosRestantes == 0
                      ? (valor) => setState(() => tipoOperacion = valor.first)
                      : null,
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                    child: qr == null
                        ? const _EstadoLista(
                            icono: Icons.qr_code_2,
                            titulo: 'QR no generado',
                            detalle:
                                'Genera un codigo cuando estes frente al guardia.',
                          )
                        : _QrTemporal(
                            token: qr.token,
                            segundosRestantes: segundosRestantes,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ChipEstado(
                  texto: qr == null
                      ? 'Sin QR activo'
                      : segundosRestantes > 0
                          ? 'Expira en $segundosRestantes s'
                          : 'QR expirado',
                  color: qr != null && segundosRestantes > 0
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                const SizedBox(height: 16),
                _FilaDato(
                  etiqueta: 'Operacion',
                  valor: tipoOperacion == 'INGRESO' ? 'Ingreso' : 'Retiro',
                ),
                _FilaDato(
                  etiqueta: 'Bicicleta activa',
                  valor: qr?.bicicleta.descripcion ?? 'No seleccionada',
                ),
                const _FilaDato(etiqueta: 'Duracion', valor: '15 segundos'),
                if (qr != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresUbb.azulOscuro.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            ColoresUbb.azulInstitucional.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Token para prueba local',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: ColoresUbb.textoSecundario,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          qr.token,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: generando ? null : _generarQr,
                  icon: generando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    qr == null || segundosRestantes == 0
                        ? 'Generar QR'
                        : 'Regenerar QR',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generarQr() async {
    setState(() => generando = true);

    try {
      final qr = await qrApi.generar(tipo: tipoOperacion);

      if (mounted) {
        setState(() => qrActual = qr);
        _programarActualizacion();
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => generando = false);
      }
    }
  }

  void _programarActualizacion() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || qrActual == null) {
        return;
      }

      setState(() {});

      if (qrActual!.expiraEn.isAfter(DateTime.now())) {
        _programarActualizacion();
      }
    });
  }
}

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
          const SnackBar(content: Text('Solicitud enviada a central')),
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
      children: [
        const _EncabezadoSeccion(
          titulo: 'Guardia',
          detalle:
              'Solicita apoyo si el guardia no esta visible o necesitas atencion.',
          icono: Icons.support_agent,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cargando)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<BicicleteroApp>(
                    initialValue: bicicleteroSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Bicicletero',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: bicicleteros
                        .map(
                          (bicicletero) => DropdownMenuItem(
                            value: bicicletero,
                            child: Text(bicicletero.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setState(() => bicicleteroSeleccionado = valor);
                    },
                  ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'REQUIERE_SERVICIO',
                      label: Text('Requiere servicio'),
                      icon: Icon(Icons.notifications_active_outlined),
                    ),
                    ButtonSegment(
                      value: 'GUARDIA_AUSENTE',
                      label: Text('Guardia ausente'),
                      icon: Icon(Icons.person_off_outlined),
                    ),
                  ],
                  selected: {tipoSolicitud},
                  onSelectionChanged: (valor) =>
                      setState(() => tipoSolicitud = valor.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: mensajeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje opcional',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      bicicleteroSeleccionado == null ? null : _enviarSolicitud,
                  icon: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    enviando ? 'Enviando...' : 'Enviar solicitud a central',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                      child: _TarjetaSolicitudGuardia(solicitud: solicitud),
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

class VistaInicioGuardia extends StatelessWidget {
  const VistaInicioGuardia({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _EncabezadoSeccion(
          titulo: 'Inicio guardia',
          detalle: 'Turno activo, bicicletero asignado y accesos recientes.',
          icono: Icons.verified_user_outlined,
        ),
        SizedBox(height: 16),
        TarjetaAccion(
          icono: Icons.location_on_outlined,
          titulo: 'Bicicletero Central',
          detalle: 'Turno 08:00 - 16:00 | 68% ocupacion',
        ),
        SizedBox(height: 10),
        TarjetaAccion(
          icono: Icons.qr_code_scanner,
          titulo: 'Escanear QR temporal',
          detalle:
              'Lee el codigo del usuario para confirmar o denegar ingreso/retiro.',
          color: ColoresUbb.exito,
        ),
        SizedBox(height: 10),
        TarjetaAccion(
          icono: Icons.edit_note_outlined,
          titulo: 'Gestion manual',
          detalle:
              'Registra ingreso o retiro usando correo institucional y RUT.',
          color: ColoresUbb.amarilloInstitucional,
        ),
      ],
    );
  }
}

class VistaEscanerQrGuardia extends StatefulWidget {
  const VistaEscanerQrGuardia({super.key});

  @override
  State<VistaEscanerQrGuardia> createState() => _VistaEscanerQrGuardiaState();
}

class _VistaEscanerQrGuardiaState extends State<VistaEscanerQrGuardia> {
  final accesoApi = AccesoApi();
  final tokenController = TextEditingController();
  QrValidadoApp? qrLeido;
  bool cargando = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrLeido;

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Escanear QR',
          detalle:
              'Despues de leer el QR, confirma o deniega indicando motivo.',
          icono: Icons.qr_code_scanner,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulOscuro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 88),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tokenController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Token QR escaneado',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: cargando ? null : _validarQr,
                  icon: cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(cargando ? 'Validando...' : 'Validar QR'),
                ),
              ],
            ),
          ),
        ),
        if (qr != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ChipEstado(texto: 'QR valido', color: ColoresUbb.exito),
                  const SizedBox(height: 16),
                  _FilaDato(etiqueta: 'Usuario', valor: qr.usuarioNombre),
                  _FilaDato(etiqueta: 'RUT', valor: qr.usuarioRut ?? 'Sin RUT'),
                  _FilaDato(etiqueta: 'Correo', valor: qr.usuarioCorreo),
                  _FilaDato(
                    etiqueta: 'Operacion',
                    valor: qr.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro',
                  ),
                  _FilaDato(
                    etiqueta: 'Bicicleta',
                    valor: qr.bicicletaDescripcion,
                  ),
                  _FilaDato(
                    etiqueta: 'Bicicletero',
                    valor: qr.bicicleteroNombre ?? 'Asignacion del guardia',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _confirmarQr(qr),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      qr.tipo == 'INGRESO'
                          ? 'Confirmar ingreso'
                          : 'Confirmar retiro',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarDenegacion(context, qr),
                    icon: const Icon(Icons.block_outlined),
                    label: Text(
                      qr.tipo == 'INGRESO'
                          ? 'Denegar ingreso'
                          : 'Denegar retiro',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _validarQr() async {
    if (tokenController.text.trim().isEmpty) {
      return;
    }

    setState(() => cargando = true);

    try {
      final qr = await accesoApi.validarQr(tokenController.text.trim());
      if (mounted) {
        setState(() => qrLeido = qr);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() => qrLeido = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _confirmarQr(QrValidadoApp qr) async {
    try {
      final movimiento = await accesoApi.confirmarQr(qr.token);
      if (mounted) {
        setState(() => qrLeido = null);
        tokenController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} confirmado',
            ),
          ),
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

  void _mostrarDenegacion(BuildContext context, QrValidadoApp qr) {
    final motivoController = TextEditingController();
    final mensajero = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (contextoHoja) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(contextoHoja).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Motivo de denegacion',
                style: Theme.of(contextoHoja)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Indica el motivo',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await accesoApi.denegarQr(
                      token: qr.token,
                      motivo: motivoController.text.trim(),
                    );
                    if (contextoHoja.mounted) {
                      Navigator.pop(contextoHoja);
                    }
                    if (mounted) {
                      setState(() => qrLeido = null);
                      tokenController.clear();
                      mensajero.showSnackBar(
                        const SnackBar(content: Text('Operacion denegada')),
                      );
                    }
                  } on ExcepcionApi catch (error) {
                    if (contextoHoja.mounted) {
                      ScaffoldMessenger.of(contextoHoja).showSnackBar(
                        SnackBar(content: Text(error.mensaje)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Registrar denegacion'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VistaGestionManualGuardia extends StatefulWidget {
  const VistaGestionManualGuardia({super.key});

  @override
  State<VistaGestionManualGuardia> createState() =>
      _VistaGestionManualGuardiaState();
}

class _VistaGestionManualGuardiaState extends State<VistaGestionManualGuardia> {
  final accesoApi = AccesoApi();
  final correoController = TextEditingController();
  final rutController = TextEditingController();
  String operacion = 'INGRESO';
  bool registrando = false;

  @override
  void dispose() {
    correoController.dispose();
    rutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Gestion manual',
          detalle: 'Registra ingreso o retiro cuando el QR no pueda usarse.',
          icono: Icons.edit_note_outlined,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'INGRESO',
                        label: Text('Ingreso'),
                        icon: Icon(Icons.login)),
                    ButtonSegment(
                        value: 'SALIDA',
                        label: Text('Retiro'),
                        icon: Icon(Icons.logout)),
                  ],
                  selected: {operacion},
                  onSelectionChanged: (valor) =>
                      setState(() => operacion = valor.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rutController,
                  decoration: const InputDecoration(
                    labelText: 'RUT',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulOscuro.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: ColoresUbb.azulInstitucional),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Se usara la bicicleta activa del usuario. Si tiene mas de una, debe activarla desde su perfil.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: registrando ? null : _registrarManual,
                  icon: registrando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    registrando
                        ? 'Registrando...'
                        : 'Registrar ${operacion == 'INGRESO' ? 'ingreso' : 'retiro'}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _registrarManual() async {
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();

    if (correo.isEmpty && rut.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo institucional o RUT del usuario'),
        ),
      );
      return;
    }

    setState(() => registrando = true);

    try {
      final movimiento = await accesoApi.registrarManual(
        correo: correo,
        rut: rut,
        tipo: operacion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} registrado para ${movimiento.usuarioNombre}',
            ),
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
        setState(() => registrando = false);
      }
    }
  }
}

class VistaAlertasGuardia extends StatefulWidget {
  const VistaAlertasGuardia({super.key});

  @override
  State<VistaAlertasGuardia> createState() => _VistaAlertasGuardiaState();
}

class _VistaAlertasGuardiaState extends State<VistaAlertasGuardia> {
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

class VistaDashboardCentral extends StatefulWidget {
  const VistaDashboardCentral({super.key});

  @override
  State<VistaDashboardCentral> createState() => _VistaDashboardCentralState();
}

class _VistaDashboardCentralState extends State<VistaDashboardCentral> {
  final historialApi = HistorialApi();
  late Future<ResumenHistorialApp> futuroResumen;

  @override
  void initState() {
    super.initState();
    futuroResumen = historialApi.resumen();
  }

  void _recargar() {
    setState(() => futuroResumen = historialApi.resumen());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Dashboard central',
          detalle: 'Resumen operacional basado en historial de movimientos.',
          icono: Icons.dashboard_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<ResumenHistorialApp>(
          future: futuroResumen,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GridIndicadoresCentral(
                indicadores: [
                  _IndicadorCentral(
                      valor: '...', etiqueta: 'Movimientos semana'),
                  _IndicadorCentral(
                      valor: '...', etiqueta: 'Denegaciones semana'),
                  _IndicadorCentral(
                      valor: '2', etiqueta: 'Bicicleteros activos'),
                ],
              );
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el resumen',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final resumen = snapshot.data!;
            return _GridIndicadoresCentral(
              indicadores: [
                _IndicadorCentral(
                  valor: resumen.movimientosSemana.toString(),
                  etiqueta: 'Movimientos semana',
                ),
                _IndicadorCentral(
                  valor: resumen.denegacionesSemana.toString(),
                  etiqueta: 'Denegaciones semana',
                ),
                _IndicadorCentral(
                  valor: resumen.operacionesPorGuardia.length.toString(),
                  etiqueta: 'Guardias con operaciones',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ...bicicleterosDemo.map(
          (bicicletero) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TarjetaBicicletero(bicicletero: bicicletero),
          ),
        ),
      ],
    );
  }
}

class VistaMovimientosCentral extends StatefulWidget {
  const VistaMovimientosCentral({super.key});

  @override
  State<VistaMovimientosCentral> createState() =>
      _VistaMovimientosCentralState();
}

class _VistaMovimientosCentralState extends State<VistaMovimientosCentral> {
  final historialApi = HistorialApi();
  final filtroController = TextEditingController();
  String periodo = 'SEMANA';
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
  }

  @override
  void dispose() {
    filtroController.dispose();
    super.dispose();
  }

  Future<List<MovimientoApp>> _obtenerMovimientos() {
    return historialApi.listar(
      filtro: filtroController.text,
      periodo: periodo,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Movimientos',
          detalle: 'Filtra historial por RUT, correo institucional o nombre.',
          icono: Icons.manage_search_outlined,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Dia')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
          ],
          selected: {periodo},
          onSelectionChanged: (valor) {
            periodo = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: filtroController,
          decoration: const InputDecoration(
            labelText: 'Buscar por RUT o correo',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => _recargar(),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MovimientoApp>>(
          future: futuroMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el historial',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final movimientos = snapshot.data ?? [];

            if (movimientos.isEmpty) {
              return const _EstadoLista(
                icono: Icons.manage_search_outlined,
                titulo: 'Sin movimientos',
                detalle: 'No hay registros para los filtros seleccionados.',
              );
            }

            return Column(
              children: movimientos
                  .map(
                    (movimiento) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaMovimientoCentral(movimiento: movimiento),
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

class _TarjetaMovimientoCentral extends StatelessWidget {
  const _TarjetaMovimientoCentral({required this.movimiento});

  final MovimientoApp movimiento;

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esIngreso ? Icons.login : Icons.logout,
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${esIngreso ? 'Ingreso' : 'Retiro'} | ${movimiento.usuarioNombre}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: confirmado ? 'Confirmado' : 'Denegado',
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _FilaDato(
              etiqueta: 'Correo',
              valor: movimiento.usuarioCorreo,
            ),
            _FilaDato(
              etiqueta: 'RUT',
              valor: movimiento.usuarioRut ?? 'Sin RUT',
            ),
            _FilaDato(
              etiqueta: 'Bicicleta',
              valor: movimiento.bicicletaDescripcion,
            ),
            _FilaDato(
              etiqueta: 'Bicicletero',
              valor: movimiento.bicicleteroNombre,
            ),
            _FilaDato(
              etiqueta: 'Guardia',
              valor: movimiento.guardiaNombre,
            ),
            _FilaDato(
              etiqueta: 'Fecha',
              valor: _formatearFecha(movimiento.creadoEn),
            ),
            if (movimiento.motivoDenegacion != null) ...[
              const SizedBox(height: 8),
              Text(
                'Motivo: ${movimiento.motivoDenegacion}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.rojoInstitucional,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year} $hora:$minuto';
}

class _ResumenGuardia {
  int total = 0;
  int denegaciones = 0;
  final bicicleteros = <String>{};
}

Map<String, _ResumenGuardia> _agruparPorGuardia(
  List<MovimientoApp> movimientos,
) {
  final resumen = <String, _ResumenGuardia>{};

  for (final movimiento in movimientos) {
    final guardia = resumen.putIfAbsent(
      movimiento.guardiaNombre,
      _ResumenGuardia.new,
    );

    guardia.total += 1;
    if (movimiento.estado == 'DENEGADO') {
      guardia.denegaciones += 1;
    }
    guardia.bicicleteros.add(movimiento.bicicleteroNombre);
  }

  return resumen;
}

class VistaOperacionesGuardiasCentral extends StatefulWidget {
  const VistaOperacionesGuardiasCentral({super.key});

  @override
  State<VistaOperacionesGuardiasCentral> createState() =>
      _VistaOperacionesGuardiasCentralState();
}

class _VistaOperacionesGuardiasCentralState
    extends State<VistaOperacionesGuardiasCentral> {
  final historialApi = HistorialApi();
  String periodo = 'DIA';
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    futuroMovimientos = historialApi.listar(periodo: periodo);
  }

  void _recargar() {
    setState(() => futuroMovimientos = historialApi.listar(periodo: periodo));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Operaciones por guardia',
          detalle: 'Consulta rendimiento operacional por dia, semana o mes.',
          icono: Icons.security_outlined,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Dia')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
          ],
          selected: {periodo},
          onSelectionChanged: (valor) {
            periodo = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MovimientoApp>>(
          future: futuroMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar operaciones',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final resumen = _agruparPorGuardia(snapshot.data ?? []);
            final entradas = resumen.entries.toList()
              ..sort((a, b) => b.value.total.compareTo(a.value.total));

            if (entradas.isEmpty) {
              return const _EstadoLista(
                icono: Icons.security_outlined,
                titulo: 'Sin operaciones',
                detalle: 'No hay validaciones para el periodo seleccionado.',
              );
            }

            return Column(
              children: entradas
                  .map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaAccion(
                        icono: Icons.verified_user_outlined,
                        titulo: entrada.key,
                        detalle:
                            '${entrada.value.total} validaciones | ${entrada.value.denegaciones} denegaciones | ${entrada.value.bicicleteros.join(', ')}',
                        color: entrada.value.denegaciones == 0
                            ? ColoresUbb.exito
                            : ColoresUbb.amarilloInstitucional,
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

class VistaPerfil extends StatelessWidget {
  const VistaPerfil({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context) {
    final usuarioSesion = SesionActual.usuario;
    final nombre = switch (rol) {
      RolUsuario.guardia => 'Guardia M. Salazar',
      RolUsuario.adminCentral => 'Admin Central Seguridad',
      RolUsuario.administrador => 'Administrador UBBike',
      RolUsuario.funcionario => 'Funcionario UBB',
      RolUsuario.estudiante => 'Sebastian Pinto',
    };
    final correo = switch (rol) {
      RolUsuario.estudiante => 'sebastian.pinto@alumnos.ubiobio.cl',
      RolUsuario.funcionario => 'funcionario@ubiobio.cl',
      RolUsuario.guardia => 'guardia.salazar@ubiobio.cl',
      RolUsuario.adminCentral => 'admin.central@ubiobio.cl',
      RolUsuario.administrador => 'administrador@ubiobio.cl',
    };
    final nombrePerfil = usuarioSesion?.nombre ?? nombre;
    final correoPerfil = usuarioSesion?.correo ?? correo;
    final rutPerfil = usuarioSesion?.rut ?? '20.123.456-7';

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Perfil',
          detalle: 'Datos de cuenta, seguridad y rol asignado.',
          icono: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: ColoresUbb.azulInstitucional,
                  child: Text(
                    nombrePerfil.characters.first,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    nombrePerfil,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                    child: ChipEstado(
                        texto: rol.etiqueta,
                        color: ColoresUbb.azulInstitucional)),
                const SizedBox(height: 18),
                _FilaDato(etiqueta: 'Correo', valor: correoPerfil),
                _FilaDato(etiqueta: 'RUT', valor: rutPerfil),
                const _FilaDato(etiqueta: 'Estado', valor: 'Correo verificado'),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final mensaje = await AutenticacionApi()
                          .solicitarCambioContrasena(correoPerfil);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(mensaje)),
                        );
                      }
                    } on ExcepcionApi catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.mensaje)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  label: const Text('Enviar correo para cambiar contrasena'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaBicicletaUsuario extends StatelessWidget {
  const _TarjetaBicicletaUsuario({
    required this.bicicleta,
    required this.onEditar,
    required this.onEliminar,
    required this.onActivar,
  });

  final BicicletaApp bicicleta;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onActivar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pedal_bike,
                  color: ColoresUbb.azulInstitucional,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bicicleta.descripcion,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: bicicleta.activa ? 'Activa' : 'Registrada',
                  color: bicicleta.activa
                      ? ColoresUbb.exito
                      : ColoresUbb.azulInstitucional,
                ),
              ],
            ),
            if (bicicleta.fotoUrl != null) ...[
              const SizedBox(height: 6),
              Text(
                bicicleta.fotoUrl!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresUbb.textoSecundario,
                    ),
              ),
            ],
            const SizedBox(height: 12),
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
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
                ElevatedButton.icon(
                  onPressed: onActivar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(bicicleta.activa ? 'En uso' : 'Activar'),
                ),
              ],
            ),
          ],
        ),
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

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: expirado ? 0.24 : 1,
          child: QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 260,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Expirado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: ColoresUbb.azulInstitucional, size: 42),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
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

class _TarjetaBicicletero extends StatelessWidget {
  const _TarjetaBicicletero({required this.bicicletero});

  final BicicleteroDemo bicicletero;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: ColoresUbb.azulInstitucional),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bicicletero.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                    texto: '${bicicletero.ocupacion}%',
                    color: ColoresUbb.exito),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bicicletero.ubicacion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: bicicletero.ocupacion / 100,
              backgroundColor:
                  ColoresUbb.grisInstitucional.withValues(alpha: 0.35),
              color: ColoresUbb.azulInstitucional,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
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
    this.onActualizar,
  });

  final SolicitudGuardiaApp solicitud;
  final bool mostrarSolicitante;
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
                const Icon(Icons.support_agent,
                    color: ColoresUbb.azulInstitucional),
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
                  OutlinedButton.icon(
                    onPressed: solicitud.estado == 'VISTA'
                        ? null
                        : () => _actualizar(context, 'VISTA'),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Vista'),
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

String _etiquetaEstadoSolicitud(String estado) {
  return switch (estado) {
    'PENDIENTE' => 'Pendiente',
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
    'VISTA' => ColoresUbb.amarilloInstitucional,
    'EN_CAMINO' => ColoresUbb.azulInstitucional,
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
                    color: ColoresUbb.azulInstitucional,
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
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
      color: ColoresUbb.azulInstitucional,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: ColoresUbb.amarilloInstitucional),
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
                          color: Colors.white.withValues(alpha: 0.86),
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
