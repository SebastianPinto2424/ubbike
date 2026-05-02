class BicicleteroApp {
  const BicicleteroApp({
    required this.id,
    required this.nombre,
    required this.ubicacion,
  });

  final String id;
  final String nombre;
  final String ubicacion;

  factory BicicleteroApp.desdeJson(Map<String, dynamic> json) {
    return BicicleteroApp(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      ubicacion: json['ubicacion'] as String,
    );
  }
}
