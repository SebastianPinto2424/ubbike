// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<String> descargarReporteTexto({
  required String nombreArchivo,
  required String contenido,
  String tipoMime = 'text/plain;charset=utf-8',
}) async {
  final blob = html.Blob([contenido], tipoMime);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = nombreArchivo
    ..click();

  html.Url.revokeObjectUrl(url);
  return 'Reporte descargado';
}
