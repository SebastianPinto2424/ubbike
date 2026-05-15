import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/tema/colores_ubb.dart';
import '../../../core/servicios/excepcion_api.dart';
import '../../../features/acceso/data/solicitud_guardia_api.dart';
import '../../../features/admin/presentation/vista_gestion_usuarios.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../features/auth/presentation/pantalla_login.dart';
import '../../../features/bicicletas/data/bicicleta_api.dart';
import '../../../features/acceso/data/acceso_api.dart';
import '../../../features/historial/data/historial_api.dart';
import '../../../features/inicio/application/controlador_notificaciones_inicio.dart';
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

part 'usuario/vista_inicio_usuario.dart';
part 'usuario/vista_bicicletas_usuario.dart';
part 'usuario/formulario_bicicleta_usuario.dart';
part 'usuario/vista_movimientos_usuario.dart';
part 'usuario/vista_qr_usuario.dart';
part 'usuario/vista_solicitar_guardia.dart';
part 'guardia/vista_inicio_guardia.dart';
part 'guardia/vista_escaner_qr_guardia.dart';
part 'guardia/vista_gestion_manual_guardia.dart';
part 'guardia/vista_alertas_guardia.dart';
part 'central/vista_dashboard_central.dart';
part 'central/vista_movimientos_central.dart';
part 'central/vista_operaciones_guardias_central.dart';
part 'central/vista_solicitudes_central.dart';
part 'perfil/pantalla_principal_perfil.dart';
part 'widgets/bicicletas_widgets.dart';
part 'widgets/qr_widgets.dart';
part 'widgets/estado_widgets.dart';
part 'widgets/bicicletero_widgets.dart';
part 'widgets/solicitud_guardia_widgets.dart';
part 'widgets/central_widgets.dart';
part 'widgets/encabezado_widgets.dart';
part 'widgets/qr_demostracion.dart';

const int _maxFotoDataUrlLength = 1400000;
const Set<String> _mimesFotoPermitidos = {
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
};

String _normalizarMimeFoto(String? mime, String nombreArchivo) {
  final normalizado = mime?.toLowerCase().trim();
  if (_mimesFotoPermitidos.contains(normalizado)) {
    return normalizado!;
  }

  final nombre = nombreArchivo.toLowerCase();
  if (nombre.endsWith('.jpg') || nombre.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (nombre.endsWith('.png')) {
    return 'image/png';
  }
  if (nombre.endsWith('.webp')) {
    return 'image/webp';
  }

  return normalizado ?? 'image/jpeg';
}

Uint8List? _decodificarFotoDataUrl(String? fotoDataUrl) {
  if (fotoDataUrl == null || !fotoDataUrl.startsWith('data:image')) {
    return null;
  }

  final partes = fotoDataUrl.split(',');
  if (partes.length < 2) {
    return null;
  }

  try {
    return base64Decode(partes.last);
  } on FormatException {
    return null;
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, required this.rol});

  final RolUsuario rol;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int indice = 0;
  final controladorNotificaciones = ControladorNotificacionesInicio();

  @override
  void initState() {
    super.initState();
    controladorNotificaciones.addListener(_sincronizarNotificaciones);
    controladorNotificaciones.iniciar();
  }

  @override
  void dispose() {
    controladorNotificaciones.removeListener(_sincronizarNotificaciones);
    controladorNotificaciones.dispose();
    super.dispose();
  }

  Future<void> _abrirNotificaciones() async {
    controladorNotificaciones.marcarTodasLeidas();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PantallaNotificaciones(),
      ),
    );

    if (mounted) {
      await controladorNotificaciones.actualizar();
    }
  }

  void _sincronizarNotificaciones() {
    if (!mounted) {
      return;
    }

    setState(() {});
    final nueva = controladorNotificaciones.nuevaNotificacion;
    if (nueva == null) {
      return;
    }

    controladorNotificaciones.marcarNuevaNotificacionMostrada();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nueva notificacion: ${nueva.titulo}'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: _abrirNotificaciones,
        ),
      ),
    );
  }

  Widget _iconoNotificaciones() {
    final cantidad = controladorNotificaciones.noLeidas;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),
        if (cantidad > 0)
          Positioned(
            right: -4,
            top: -6,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ColoresUbb.rojoInstitucional,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  cantidad > 9 ? '9+' : '$cantidad',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

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
            onPressed: _abrirNotificaciones,
            icon: _iconoNotificaciones(),
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
      return [
        const NavigationDestination(
            icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            decoration: BoxDecoration(
              color: ColoresUbb.azulApp,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ColoresUbb.azulApp.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner,
                color: Colors.white, size: 28),
          ),
          label: 'QR',
        ),
        const NavigationDestination(icon: Icon(Icons.history), label: 'Movs.'),
        const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined), label: 'Manual'),
        const NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined), label: 'Alertas'),
        const NavigationDestination(
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

    return [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined), label: 'Inicio'),
      const NavigationDestination(
          icon: Icon(Icons.pedal_bike), label: 'Bicicletas'),
      NavigationDestination(
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: ColoresUbb.azulApp,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ColoresUbb.azulApp.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_2, color: Colors.white, size: 30),
        ),
        label: 'QR',
      ),
      const NavigationDestination(
          icon: Icon(Icons.support_agent), label: 'Guardia'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline), label: 'Perfil'),
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
  return _textoNoVacio(SesionActual.usuario?.nombre, respaldo);
}

String _textoNoVacio(String? valor, String respaldo) {
  final texto = valor?.trim();
  if (texto == null || texto.isEmpty) {
    return respaldo;
  }
  return texto;
}

String _inicialSegura(String valor) {
  final texto = valor.trim();
  if (texto.isEmpty) {
    return '?';
  }
  return texto.characters.first.toUpperCase();
}
