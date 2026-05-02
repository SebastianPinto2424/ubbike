import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class ResumenHistorialApp {
  const ResumenHistorialApp({
    required this.movimientosSemana,
    required this.denegacionesSemana,
    required this.operacionesPorGuardia,
  });

  final int movimientosSemana;
  final int denegacionesSemana;
  final Map<String, int> operacionesPorGuardia;

  factory ResumenHistorialApp.desdeJson(Map<String, dynamic> json) {
    final operaciones = json['operacionesPorGuardia'] as Map<String, dynamic>;

    return ResumenHistorialApp(
      movimientosSemana: json['movimientosSemana'] as int,
      denegacionesSemana: json['denegacionesSemana'] as int,
      operacionesPorGuardia: operaciones.map(
        (clave, valor) => MapEntry(clave, valor as int),
      ),
    );
  }
}

class HistorialApi {
  HistorialApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<MovimientoApp>> listar({
    String? filtro,
    String? periodo,
    String? tipo,
    String? estado,
    String? bicicleteroId,
  }) async {
    final parametros = <String>[];

    if (filtro != null && filtro.trim().isNotEmpty) {
      parametros.add('q=${Uri.encodeQueryComponent(filtro.trim())}');
    }

    if (periodo != null && periodo.isNotEmpty) {
      parametros.add('periodo=$periodo');
    }

    if (tipo != null && tipo.isNotEmpty && tipo != 'TODOS') {
      parametros.add('tipo=$tipo');
    }

    if (estado != null && estado.isNotEmpty && estado != 'TODOS') {
      parametros.add('estado=$estado');
    }

    if (bicicleteroId != null && bicicleteroId.isNotEmpty) {
      parametros.add('bicicleteroId=$bicicleteroId');
    }

    final query = parametros.isEmpty ? '' : '?${parametros.join('&')}';
    final respuesta = await cliente.get('/historial$query');
    final datos =
        (respuesta['movimientos'] ?? respuesta['datos']) as List<dynamic>;
    return datos
        .map((item) => MovimientoApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ResumenHistorialApp> resumen() async {
    final respuesta = await cliente.get('/historial/resumen');
    return ResumenHistorialApp.desdeJson(
      respuesta['resumen'] as Map<String, dynamic>,
    );
  }
}
