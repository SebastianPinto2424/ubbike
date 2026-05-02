import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class QrValidadoApp {
  const QrValidadoApp({
    required this.token,
    required this.tipo,
    required this.expiraEn,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.usuarioRut,
    required this.bicicletaDescripcion,
    this.bicicleteroNombre,
  });

  final String token;
  final String tipo;
  final DateTime expiraEn;
  final String usuarioNombre;
  final String usuarioCorreo;
  final String? usuarioRut;
  final String bicicletaDescripcion;
  final String? bicicleteroNombre;

  factory QrValidadoApp.desdeJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;
    final bicicleta = json['bicicleta'] as Map<String, dynamic>;
    final bicicletero = json['bicicletero'] as Map<String, dynamic>?;

    return QrValidadoApp(
      token: json['token'] as String,
      tipo: json['tipo'] as String,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
      usuarioNombre: usuario['nombre'] as String,
      usuarioCorreo: usuario['correo'] as String,
      usuarioRut: usuario['rut'] as String?,
      bicicletaDescripcion: bicicleta['descripcion'] as String,
      bicicleteroNombre: bicicletero?['nombre'] as String?,
    );
  }
}

class AccesoApi {
  AccesoApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<QrValidadoApp> validarQr(String token) async {
    final respuesta = await cliente.post('/qr/validar', body: {'token': token});
    return QrValidadoApp.desdeJson(respuesta['qr'] as Map<String, dynamic>);
  }

  Future<MovimientoApp> confirmarQr(String token) async {
    final respuesta = await cliente.post(
      '/accesos/qr/confirmar',
      body: {'token': token},
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }

  Future<MovimientoApp> denegarQr({
    required String token,
    required String motivo,
  }) async {
    final respuesta = await cliente.post(
      '/accesos/qr/denegar',
      body: {
        'token': token,
        'motivo': motivo,
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }

  Future<MovimientoApp> registrarManual({
    String? correo,
    String? rut,
    required String tipo,
    bool denegar = false,
    String? motivo,
  }) async {
    final respuesta = await cliente.post(
      '/accesos/manual',
      body: {
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        if (rut != null && rut.isNotEmpty) 'rut': rut,
        'tipo': tipo,
        'denegar': denegar,
        'motivo': motivo,
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }
}
