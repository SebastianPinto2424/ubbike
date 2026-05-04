import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class SolicitudGuardiaApp {
  const SolicitudGuardiaApp({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.bicicletero,
    required this.solicitante,
    required this.creadaEn,
    required this.puedeNotificarGuardia,
    this.guardiaAsignado,
    this.mensaje,
    this.notificadaGuardiaEn,
    this.acuseReciboEn,
    this.resueltaEn,
    this.segundosParaNotificarGuardia,
    this.guardiasAsignados = const [],
  });

  final String id;
  final String tipo;
  final String estado;
  final String? mensaje;
  final BicicleteroApp bicicletero;
  final UsuarioApp solicitante;
  final UsuarioApp? guardiaAsignado;
  final List<UsuarioApp> guardiasAsignados;
  final DateTime creadaEn;
  final DateTime? notificadaGuardiaEn;
  final DateTime? acuseReciboEn;
  final DateTime? resueltaEn;
  final bool puedeNotificarGuardia;
  final int? segundosParaNotificarGuardia;

  factory SolicitudGuardiaApp.desdeJson(Map<String, dynamic> json) {
    final guardia = json['guardiaAsignado'] as Map<String, dynamic>?;
    final guardias = json['guardiasAsignados'] as List<dynamic>? ?? const [];

    return SolicitudGuardiaApp(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      estado: json['estado'] as String,
      mensaje: json['mensaje'] as String?,
      bicicletero: BicicleteroApp.desdeJson(
        json['bicicletero'] as Map<String, dynamic>,
      ),
      solicitante: UsuarioApp.desdeJson(
        json['solicitante'] as Map<String, dynamic>,
      ),
      guardiaAsignado: guardia == null ? null : UsuarioApp.desdeJson(guardia),
      guardiasAsignados: guardias
          .whereType<Map<String, dynamic>>()
          .map(UsuarioApp.desdeJson)
          .toList(),
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      notificadaGuardiaEn: json['notificadaGuardiaEn'] == null
          ? null
          : DateTime.parse(json['notificadaGuardiaEn'] as String),
      acuseReciboEn: json['acuseReciboEn'] == null
          ? null
          : DateTime.parse(json['acuseReciboEn'] as String),
      resueltaEn: json['resueltaEn'] == null
          ? null
          : DateTime.parse(json['resueltaEn'] as String),
      puedeNotificarGuardia: json['puedeNotificarGuardia'] as bool? ?? false,
      segundosParaNotificarGuardia:
          json['segundosParaNotificarGuardia'] as int?,
    );
  }
}

class SolicitudGuardiaApi {
  SolicitudGuardiaApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<BicicleteroApp>> listarBicicleteros() async {
    final respuesta = await cliente.get('/bicicleteros');
    final datos = respuesta['bicicleteros'] as List<dynamic>;
    return datos
        .map((item) => BicicleteroApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BicicleteroApp?> obtenerBicicleteroGestionado() async {
    final respuesta = await cliente.get('/guardias/me/bicicletero');
    final datos = respuesta['bicicletero'] as Map<String, dynamic>?;

    return datos == null ? null : BicicleteroApp.desdeJson(datos);
  }

  Future<BicicleteroApp> seleccionarBicicleteroGestionado(
    String bicicleteroId,
  ) async {
    final respuesta = await cliente.patch(
      '/guardias/me/bicicletero',
      body: {'bicicleteroId': bicicleteroId},
    );

    return BicicleteroApp.desdeJson(
      respuesta['bicicletero'] as Map<String, dynamic>,
    );
  }

  Future<void> crearSolicitud({
    required String bicicleteroId,
    required String tipo,
    String? mensaje,
  }) async {
    await cliente.post(
      '/solicitudes-guardia',
      body: {
        'bicicleteroId': bicicleteroId,
        'tipo': tipo,
        'mensaje': mensaje,
      },
    );
  }

  Future<List<SolicitudGuardiaApp>> listarSolicitudes() async {
    final respuesta = await cliente.get('/solicitudes-guardia');
    final datos = respuesta['solicitudes'] as List<dynamic>;
    return datos
        .map((item) =>
            SolicitudGuardiaApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SolicitudGuardiaApp> actualizarEstado({
    required String solicitudId,
    required String estado,
  }) async {
    final respuesta = await cliente.patch(
      '/solicitudes-guardia/$solicitudId/estado',
      body: {'estado': estado},
    );

    return SolicitudGuardiaApp.desdeJson(
      respuesta['solicitud'] as Map<String, dynamic>,
    );
  }
}
