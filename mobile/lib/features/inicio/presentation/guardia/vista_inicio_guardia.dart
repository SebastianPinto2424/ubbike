part of '../pantalla_principal.dart';

class VistaInicioGuardia extends StatefulWidget {
  const VistaInicioGuardia({super.key});

  @override
  State<VistaInicioGuardia> createState() => _VistaInicioGuardiaState();
}

class _VistaInicioGuardiaState extends State<VistaInicioGuardia> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  late Future<BicicleteroApp?> futuroBicicletero;

  @override
  void initState() {
    super.initState();
    futuroBicicletero = solicitudGuardiaApi.obtenerBicicleteroGestionado();
  }

  void _recargar() {
    setState(() =>
        futuroBicicletero = solicitudGuardiaApi.obtenerBicicleteroGestionado());
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
        FutureBuilder<BicicleteroApp?>(
          future: futuroBicicletero,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return TarjetaAccion(
                icono: Icons.location_off_outlined,
                titulo: 'Selecciona tu bicicletero',
                detalle: 'Ve a Perfil para definir el bicicletero de tu turno.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }
            return _TarjetaBicicleteroApp(bicicletero: snapshot.data!);
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
