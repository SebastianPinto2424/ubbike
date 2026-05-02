class NotificacionApp {
  const NotificacionApp({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.creadaEn,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime creadaEn;

  factory NotificacionApp.desdeJson(Map<String, dynamic> json) {
    return NotificacionApp(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leida: json['leida'] as bool? ?? false,
      creadaEn: DateTime.parse(json['creadaEn'] as String),
    );
  }
}
