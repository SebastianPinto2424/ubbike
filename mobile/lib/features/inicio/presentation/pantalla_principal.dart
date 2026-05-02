import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
        NavigationDestination(icon: Icon(Icons.history), label: 'Movs.'),
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
            icon: Icon(Icons.manage_search_outlined), label: 'Movs.'),
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
        VistaMovimientosCentral(),
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
        VistaMovimientosCentral(),
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

String _saludoActual() {
  final hora = DateTime.now().hour;
  if (hora < 12) {
    return 'Buenos dias';
  }
  if (hora < 20) {
    return 'Buenas tardes';
  }
  return 'Buenas noches';
}

String _nombreSesion(String respaldo) {
  final nombre = SesionActual.usuario?.nombre.trim();
  if (nombre == null || nombre.isEmpty) {
    return respaldo;
  }
  return nombre;
}

class VistaInicioUsuario extends StatefulWidget {
  const VistaInicioUsuario({super.key});

  @override
  State<VistaInicioUsuario> createState() => _VistaInicioUsuarioState();
}

class _VistaInicioUsuarioState extends State<VistaInicioUsuario> {
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<BicicletaApp?> futuroBicicletaActiva;
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroBicicletaActiva = bicicletaApi.obtenerActiva();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroBicicletaActiva = bicicletaApi.obtenerActiva();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Usuario UBB')}',
          detalle: 'Estado de tus bicicletas y bicicleteros disponibles.',
          icono: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<BicicletaApp?>(
          future: futuroBicicletaActiva,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _EstadoLista(
                icono: Icons.pedal_bike,
                titulo: 'Cargando estado',
                detalle: 'Consultando tu bicicleta activa.',
              );
            }
            return _EstadoActualUsuario(bicicleta: snapshot.data);
          },
        ),
        const SizedBox(height: 16),
        _TituloApartado(titulo: 'Uso de bicicleteros', onRefresh: _recargar),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicleteroApp>>(
          future: futuroBicicleteros,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar bicicleteros',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            final bicicleteros = snapshot.data ?? [];
            if (bicicleteros.isEmpty) {
              return const _EstadoLista(
                icono: Icons.location_off_outlined,
                titulo: 'Sin bicicleteros activos',
                detalle: 'Cuando existan bicicleteros activos apareceran aqui.',
              );
            }
            return Column(
              children: bicicleteros
                  .map(
                    (bicicletero) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicleteroApp(bicicletero: bicicletero),
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

class _EstadoActualUsuario extends StatelessWidget {
  const _EstadoActualUsuario({required this.bicicleta});

  final BicicletaApp? bicicleta;

  @override
  Widget build(BuildContext context) {
    final bicicleta = this.bicicleta;
    final dentro = bicicleta?.dentroBicicletero ?? false;

    return Card(
      color: ColoresUbb.azulApp,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              dentro ? Icons.lock_outline : Icons.lock_open_outlined,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              bicicleta == null
                  ? 'Sin bicicleta activa'
                  : dentro
                      ? 'Bicicleta dentro'
                      : 'Sin bicicleta dentro',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              bicicleta == null
                  ? 'Registra una bicicleta y marcala como activa para generar QR.'
                  : dentro
                      ? '${bicicleta.descripcion} esta en ${bicicleta.bicicleteroActualNombre ?? 'un bicicletero'}. El siguiente QR sera de retiro.'
                      : '${bicicleta.descripcion} esta lista. El siguiente QR sera de ingreso.',
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
        const _TituloApartado(titulo: 'Mis bicicletas'),
        const SizedBox(height: 10),
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
              return SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pedal_bike,
                        size: 64,
                        color: ColoresUbb.textoSecundario,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin bicicletas',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: ColoresUbb.textoSecundario),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca abajo para registrar tu primera bicicleta',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: ColoresUbb.textoSecundario),
                      ),
                    ],
                  ),
                ),
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
        const SizedBox(height: 18),
        const VistaMovimientosUsuario(),
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
    final marcaController = TextEditingController(text: bicicleta?.marca ?? '');
    final modeloController =
        TextEditingController(text: bicicleta?.modelo ?? '');
    final colorController = TextEditingController(text: bicicleta?.color ?? '');
    final aroController = TextEditingController(text: bicicleta?.aro ?? '');
    final numeroSerieController =
        TextEditingController(text: bicicleta?.numeroSerie ?? '');
    String? fotoSeleccionada = bicicleta?.fotoUrl;
    bool activar = bicicleta?.activa ?? false;

    Future<void> seleccionarFoto(
      ImageSource source,
      void Function(void Function()) setModalState,
    ) async {
      final imagen = await ImagePicker().pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1200,
      );

      if (imagen == null) {
        return;
      }

      final bytes = await imagen.readAsBytes();
      final mime = imagen.mimeType ?? 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      setModalState(() => fotoSeleccionada = dataUrl);
    }

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
              child: SingleChildScrollView(
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: modeloController,
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color',
                              prefixIcon: Icon(Icons.palette_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: aroController,
                            decoration: const InputDecoration(
                              labelText: 'Aro',
                              prefixIcon: Icon(Icons.circle_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numeroSerieController,
                      decoration: const InputDecoration(
                        labelText: 'Numero de serie',
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 12),
                    _SelectorFotoBicicleta(
                      fotoDataUrl: fotoSeleccionada,
                      onCamara: () => seleccionarFoto(
                        ImageSource.camera,
                        setModalState,
                      ),
                      onGaleria: () => seleccionarFoto(
                        ImageSource.gallery,
                        setModalState,
                      ),
                      onQuitar: fotoSeleccionada == null
                          ? null
                          : () => setModalState(() => fotoSeleccionada = null),
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
                              marca: marcaController.text.trim(),
                              modelo: modeloController.text.trim(),
                              color: colorController.text.trim(),
                              aro: aroController.text.trim(),
                              numeroSerie: numeroSerieController.text.trim(),
                              fotoUrl: fotoSeleccionada,
                              activar: activar,
                            );
                          } else {
                            await bicicletaApi.actualizar(
                              bicicletaId: bicicleta.id,
                              descripcion: descripcionController.text.trim(),
                              marca: marcaController.text.trim(),
                              modelo: modeloController.text.trim(),
                              color: colorController.text.trim(),
                              aro: aroController.text.trim(),
                              numeroSerie: numeroSerieController.text.trim(),
                              fotoUrl: fotoSeleccionada,
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
              ),
            );
          },
        );
      },
    );

    descripcionController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    aroController.dispose();
    numeroSerieController.dispose();

    if (guardo == true) {
      _recargar();
    }
  }
}

class _SelectorFotoBicicleta extends StatelessWidget {
  const _SelectorFotoBicicleta({
    required this.fotoDataUrl,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
  });

  final String? fotoDataUrl;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    final foto = fotoDataUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (foto != null && foto.startsWith('data:image')) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(foto.split(',').last),
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamara,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
                OutlinedButton.icon(
                  onPressed: onGaleria,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Subir foto'),
                ),
                if (onQuitar != null)
                  TextButton.icon(
                    onPressed: onQuitar,
                    icon: const Icon(Icons.close),
                    label: const Text('Quitar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VistaMovimientosUsuario extends StatefulWidget {
  const VistaMovimientosUsuario({super.key});

  @override
  State<VistaMovimientosUsuario> createState() =>
      _VistaMovimientosUsuarioState();
}

class _VistaMovimientosUsuarioState extends State<VistaMovimientosUsuario> {
  final historialApi = HistorialApi();
  final filtroController = TextEditingController();
  String periodo = 'MES';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TituloApartado(titulo: 'Mis movimientos', onRefresh: _recargar),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Dia')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
            ButtonSegment(value: 'ANIO', label: Text('Ano')),
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
            labelText: 'Filtrar por bicicleta',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => _recargar(),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MovimientoApp>>(
          future: futuroMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar movimientos',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            final movimientos = snapshot.data ?? [];
            if (movimientos.isEmpty) {
              return const _EstadoLista(
                icono: Icons.history,
                titulo: 'Sin movimientos',
                detalle: 'Tus ingresos y retiros apareceran aqui.',
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

class VistaQrUsuario extends StatefulWidget {
  const VistaQrUsuario({super.key});

  @override
  State<VistaQrUsuario> createState() => _VistaQrUsuarioState();
}

class _VistaQrUsuarioState extends State<VistaQrUsuario> {
  final qrApi = QrApi();
  final bicicletaApi = BicicletaApi();
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  QrTemporalApp? qrActual;
  BicicletaApp? bicicletaActiva;
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  bool cargandoDatos = true;
  bool generando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final resultados = await Future.wait([
        bicicletaApi.obtenerActiva(),
        solicitudGuardiaApi.listarBicicleteros(),
      ]);

      if (mounted) {
        final bicicleta = resultados[0] as BicicletaApp?;
        final listaBicicleteros = resultados[1] as List<BicicleteroApp>;
        setState(() {
          bicicletaActiva = bicicleta;
          bicicleteros = listaBicicleteros;
          bicicleteroSeleccionado = listaBicicleteros.isEmpty
              ? null
              : listaBicicleteros.firstWhere(
                  (item) => item.cuposDisponibles > 0,
                  orElse: () => listaBicicleteros.first,
                );
          cargandoDatos = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => cargandoDatos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrActual;
    final segundosRestantes = qr == null
        ? 0
        : qr.expiraEn.difference(DateTime.now()).inSeconds.clamp(0, 15);
    final bicicleta = bicicletaActiva;
    final tipoOperacion =
        bicicleta?.dentroBicicletero == true ? 'SALIDA' : 'INGRESO';
    final debeSeleccionarBicicletero = tipoOperacion == 'INGRESO';

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'QR temporal',
          detalle:
              'La app detecta automaticamente si corresponde ingreso o retiro.',
          icono: Icons.qr_code_2,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cargandoDatos)
                  const Center(child: CircularProgressIndicator())
                else if (bicicleta == null)
                  const _EstadoLista(
                    icono: Icons.pedal_bike,
                    titulo: 'Sin bicicleta activa',
                    detalle: 'Activa una bicicleta antes de generar QR.',
                  )
                else ...[
                  ChipEstado(
                    texto: tipoOperacion == 'INGRESO'
                        ? 'Operacion detectada: ingreso'
                        : 'Operacion detectada: retiro',
                    color: tipoOperacion == 'INGRESO'
                        ? ColoresUbb.azulApp
                        : ColoresUbb.turquesa,
                  ),
                  const SizedBox(height: 12),
                  _FilaDato(
                    etiqueta: 'Bicicleta activa',
                    valor: bicicleta.descripcion,
                  ),
                  if (bicicleta.dentroBicicletero)
                    _FilaDato(
                      etiqueta: 'Bicicletero actual',
                      valor: bicicleta.bicicleteroActualNombre ?? 'Registrado',
                    ),
                  if (debeSeleccionarBicicletero) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BicicleteroApp>(
                      initialValue: bicicleteroSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Bicicletero a usar',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: bicicleteros
                          .map(
                            (bicicletero) => DropdownMenuItem(
                              value: bicicletero,
                              child: Text(
                                '${bicicletero.nombre} (${bicicletero.cuposDisponibles} cupos)',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) =>
                          setState(() => bicicleteroSeleccionado = valor),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                if (qr == null)
                  const _EstadoLista(
                    icono: Icons.qr_code_2,
                    titulo: 'QR no generado',
                    detalle: 'Selecciona el bicicletero y genera el codigo.',
                  )
                else
                  _QrTemporal(
                    token: qr.token,
                    segundosRestantes: segundosRestantes,
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
                const _FilaDato(etiqueta: 'Duracion', valor: '15 segundos'),
                if (qr?.bicicletero != null)
                  _FilaDato(
                    etiqueta: 'Bicicletero',
                    valor: qr!.bicicletero!.nombre,
                  ),
                if (qr != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresUbb.superficieAzulSuave,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColoresUbb.bordeFuerte.withValues(alpha: 0.55),
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
                  onPressed: generando ||
                          cargandoDatos ||
                          bicicleta == null ||
                          (debeSeleccionarBicicletero &&
                              bicicleteroSeleccionado == null)
                      ? null
                      : _generarQr,
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
      final tipo =
          bicicletaActiva?.dentroBicicletero == true ? 'SALIDA' : 'INGRESO';
      final qr = await qrApi.generar(
        bicicleteroId: tipo == 'INGRESO' ? bicicleteroSeleccionado?.id : null,
      );

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

class VistaInicioGuardia extends StatefulWidget {
  const VistaInicioGuardia({super.key});

  @override
  State<VistaInicioGuardia> createState() => _VistaInicioGuardiaState();
}

class _VistaInicioGuardiaState extends State<VistaInicioGuardia> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(
        () => futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Guardia')}',
          detalle: 'Turno activo, bicicletero asignado y accesos recientes.',
          icono: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<BicicleteroApp>>(
          future: futuroBicicleteros,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
              return TarjetaAccion(
                icono: Icons.location_off_outlined,
                titulo: 'Sin bicicletero asignado',
                detalle: 'Toca para actualizar informacion de cupos.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            return _TarjetaBicicleteroApp(bicicletero: snapshot.data!.first);
          },
        ),
        const SizedBox(height: 10),
        const TarjetaAccion(
          icono: Icons.qr_code_scanner,
          titulo: 'Escanear QR temporal',
          detalle:
              'Lee el codigo del usuario para confirmar o denegar ingreso/retiro.',
          color: ColoresUbb.exito,
        ),
        const SizedBox(height: 10),
        const TarjetaAccion(
          icono: Icons.edit_note_outlined,
          titulo: 'Gestion manual',
          detalle:
              'Registra ingreso o retiro usando correo institucional y RUT.',
          color: ColoresUbb.azulInstitucional,
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
                  const SizedBox(height: 14),
                  _FichaVerificacionBicicleta(qr: qr),
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

class _FichaVerificacionBicicleta extends StatelessWidget {
  const _FichaVerificacionBicicleta({required this.qr});

  final QrValidadoApp qr;

  @override
  Widget build(BuildContext context) {
    final foto = qr.bicicletaFotoUrl;
    final tieneFoto = foto != null && foto.startsWith('data:image');
    final detalles = <Widget>[
      if (qr.bicicletaMarca?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaMarca!, color: ColoresUbb.azulApp),
      if (qr.bicicletaModelo?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaModelo!, color: ColoresUbb.azulMedio),
      if (qr.bicicletaColor?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaColor!, color: ColoresUbb.turquesa),
      if (qr.bicicletaAro?.isNotEmpty == true)
        ChipEstado(texto: 'Aro ${qr.bicicletaAro}', color: ColoresUbb.exito),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verificacion de bicicleta',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final contenido = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qr.bicicletaDescripcion,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (detalles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: detalles),
                  ],
                  if (qr.bicicletaNumeroSerie?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _FilaDato(
                      etiqueta: 'Serie',
                      valor: qr.bicicletaNumeroSerie!,
                    ),
                  ],
                ],
              );

              final fotoWidget = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: tieneFoto
                      ? Image.memory(
                          base64Decode(foto.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: ColoresUbb.superficie,
                          child: const Icon(
                            Icons.pedal_bike_outlined,
                            color: ColoresUbb.azulApp,
                            size: 48,
                          ),
                        ),
                ),
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: fotoWidget),
                    const SizedBox(height: 12),
                    contenido,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fotoWidget,
                  const SizedBox(width: 14),
                  Expanded(child: contenido),
                ],
              );
            },
          ),
        ],
      ),
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
                    color: ColoresUbb.superficieAzulSuave,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColoresUbb.borde),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: ColoresUbb.azulApp),
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
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<ResumenHistorialApp> futuroResumen;
  late Future<List<BicicleteroApp>> futuroBicicleteros;

  @override
  void initState() {
    super.initState();
    futuroResumen = historialApi.resumen();
    futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
  }

  void _recargar() {
    setState(() {
      futuroResumen = historialApi.resumen();
      futuroBicicleteros = solicitudGuardiaApi.listarBicicleteros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _EncabezadoSeccion(
          titulo: '${_saludoActual()}, ${_nombreSesion('Central')}',
          detalle: 'Dashboard de movimientos y cupos disponibles.',
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
        _TituloApartado(titulo: 'Cupos por bicicletero', onRefresh: _recargar),
        const SizedBox(height: 10),
        FutureBuilder<List<BicicleteroApp>>(
          future: futuroBicicleteros,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar cupos',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            return Column(
              children: (snapshot.data ?? [])
                  .map(
                    (bicicletero) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaBicicleteroApp(bicicletero: bicicletero),
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
  String tipoMovimiento = 'TODOS';
  String estadoMovimiento = 'TODOS';
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
      tipo: tipoMovimiento,
      estado: estadoMovimiento,
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
          detalle:
              'Filtra historial por fecha, usuario, bicicleta, tipo y estado.',
          icono: Icons.manage_search_outlined,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Dia')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
            ButtonSegment(value: 'ANIO', label: Text('Ano')),
          ],
          selected: {periodo},
          onSelectionChanged: (valor) {
            periodo = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todos')),
            ButtonSegment(value: 'INGRESO', label: Text('Ingresos')),
            ButtonSegment(value: 'SALIDA', label: Text('Retiros')),
          ],
          selected: {tipoMovimiento},
          onSelectionChanged: (valor) {
            tipoMovimiento = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todo')),
            ButtonSegment(value: 'CONFIRMADO', label: Text('Exitosos')),
            ButtonSegment(value: 'DENEGADO', label: Text('Denegados')),
          ],
          selected: {estadoMovimiento},
          onSelectionChanged: (valor) {
            estadoMovimiento = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: filtroController,
          decoration: const InputDecoration(
            labelText: 'Buscar RUT, correo, bicicleta, guardia o bicicletero',
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
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  String periodo = 'DIA';
  String estadoMovimiento = 'TODOS';
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
    _cargarBicicleteros();
  }

  Future<void> _cargarBicicleteros() async {
    final datos = await solicitudGuardiaApi.listarBicicleteros();
    if (mounted) {
      setState(() => bicicleteros = datos);
    }
  }

  Future<List<MovimientoApp>> _obtenerMovimientos() {
    return historialApi.listar(
      periodo: periodo,
      estado: estadoMovimiento,
      bicicleteroId: bicicleteroSeleccionado?.id,
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
          titulo: 'Operaciones por guardia',
          detalle: 'Filtra guardias por bicicletero, periodo y resultado.',
          icono: Icons.security_outlined,
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Dia')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
            ButtonSegment(value: 'ANIO', label: Text('Ano')),
          ],
          selected: {periodo},
          onSelectionChanged: (valor) {
            periodo = valor.first;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BicicleteroApp?>(
          initialValue: bicicleteroSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Bicicletero',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: [
            const DropdownMenuItem<BicicleteroApp?>(
              value: null,
              child: Text('Todos los bicicleteros'),
            ),
            ...bicicleteros.map(
              (bicicletero) => DropdownMenuItem<BicicleteroApp?>(
                value: bicicletero,
                child: Text(bicicletero.nombre),
              ),
            ),
          ],
          onChanged: (valor) {
            bicicleteroSeleccionado = valor;
            _recargar();
          },
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todo')),
            ButtonSegment(value: 'CONFIRMADO', label: Text('Exitosos')),
            ButtonSegment(value: 'DENEGADO', label: Text('Denegados')),
          ],
          selected: {estadoMovimiento},
          onSelectionChanged: (valor) {
            estadoMovimiento = valor.first;
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
                  backgroundColor: ColoresUbb.azulApp,
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
                        texto: rol.etiqueta, color: ColoresUbb.azulApp)),
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
                  label: const Text('Cambiar contrasena'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se enviara un correo electronico con un enlace seguro para cambiar tu contrasena.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                      ),
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
                  color: ColoresUbb.azulApp,
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
            if (bicicleta.fotoUrl != null &&
                bicicleta.fotoUrl!.startsWith('data:image')) ...[
              const SizedBox(height: 12),
              _ImagenBicicleta(fotoDataUrl: bicicleta.fotoUrl!),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (bicicleta.marca?.isNotEmpty == true)
                  ChipEstado(
                      texto: bicicleta.marca!, color: ColoresUbb.azulApp),
                if (bicicleta.modelo?.isNotEmpty == true)
                  ChipEstado(
                    texto: bicicleta.modelo!,
                    color: ColoresUbb.azulInstitucional,
                  ),
                if (bicicleta.color?.isNotEmpty == true)
                  ChipEstado(
                      texto: bicicleta.color!, color: ColoresUbb.turquesa),
                if (bicicleta.aro?.isNotEmpty == true)
                  ChipEstado(
                      texto: 'Aro ${bicicleta.aro}', color: ColoresUbb.exito),
                ChipEstado(
                  texto: bicicleta.dentroBicicletero
                      ? 'Dentro: ${bicicleta.bicicleteroActualNombre ?? 'bicicletero'}'
                      : 'Fuera',
                  color: bicicleta.dentroBicicletero
                      ? ColoresUbb.turquesa
                      : ColoresUbb.textoSecundario,
                ),
              ],
            ),
            if (bicicleta.numeroSerie?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _FilaDato(etiqueta: 'Serie', valor: bicicleta.numeroSerie!),
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

class _ImagenBicicleta extends StatelessWidget {
  const _ImagenBicicleta({required this.fotoDataUrl});

  final String fotoDataUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(fotoDataUrl.split(',').last),
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
                size: 240,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ),
      ),
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
            Icon(icono, color: ColoresUbb.azulApp, size: 42),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: ColoresUbb.azulApp),
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
                  texto: '${bicicletero.porcentajeUso}%',
                  color: uso >= 0.9
                      ? ColoresUbb.rojoInstitucional
                      : ColoresUbb.exito,
                ),
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
              value: uso,
              backgroundColor: ColoresUbb.superficieAzul,
              color: uso >= 0.9
                  ? ColoresUbb.rojoInstitucional
                  : ColoresUbb.azulApp,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DatoCompacto(
                    etiqueta: 'Ocupados',
                    valor: '${bicicletero.ocupados}/${bicicletero.capacidad}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatoCompacto(
                    etiqueta: 'Disponibles',
                    valor: '${bicicletero.cuposDisponibles}',
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
      color: ColoresUbb.azulNoche,
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
              child: Icon(icono, color: ColoresUbb.turquesa),
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
