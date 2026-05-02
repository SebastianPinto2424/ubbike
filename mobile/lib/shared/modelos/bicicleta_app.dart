class BicicletaApp {
  const BicicletaApp({
    required this.id,
    required this.descripcion,
    required this.activa,
    this.fotoUrl,
  });

  final String id;
  final String descripcion;
  final String? fotoUrl;
  final bool activa;

  factory BicicletaApp.desdeJson(Map<String, dynamic> json) {
    return BicicletaApp(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      fotoUrl: json['fotoUrl'] as String?,
      activa: json['activa'] as bool? ?? false,
    );
  }
}
