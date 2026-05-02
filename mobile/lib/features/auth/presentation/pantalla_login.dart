import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../features/auth/presentation/pantalla_registro.dart';
import '../../../features/inicio/presentation/pantalla_principal.dart';
import '../../../shared/servicios/sesion_actual.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresUbb.azulNoche,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const _CabeceraIngreso(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 222,
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: ColoresUbb.fondo,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: ContenedorResponsivo(
                        anchoMaximo: 520,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FormularioIngreso(
                              correoController: correoController,
                              contrasenaController: contrasenaController,
                              cargando: cargando,
                              onIngresar: _iniciarSesion,
                              onRegistro: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PantallaRegistro(),
                                  ),
                                );
                              },
                              onRecuperar: () => _mostrarRecuperacion(context),
                            ),
                            const SizedBox(height: 14),
                            const _AvisoSeguridad(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _iniciarSesion() {
    if (cargando) {
      return;
    }

    _iniciarSesionAsync();
  }

  Future<void> _iniciarSesionAsync() async {
    final correo = correoController.text.trim().toLowerCase();
    final contrasena = contrasenaController.text;

    if (correo.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo y contrasena'),
        ),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final resultado = await autenticacionApi.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );

      SesionActual.iniciar(
        nuevoToken: resultado.token,
        nuevoUsuario: resultado.usuario,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PantallaPrincipal(rol: resultado.usuario.rol),
        ),
      );
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _mostrarMensajeCorreo(context, error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensajeCorreo(context, 'No se pudo conectar con el backend');
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void _mostrarRecuperacion(BuildContext context) {
    final contextoPantalla = this.context;
    final correoRecuperacionController = TextEditingController(
      text: correoController.text.trim(),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recuperar contrasena',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enviaremos un enlace seguro al correo institucional registrado.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: correoRecuperacionController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final mensaje =
                        await autenticacionApi.solicitarCambioContrasena(
                      correoRecuperacionController.text.trim(),
                    );
                    if (contextoPantalla.mounted) {
                      _mostrarMensajeCorreo(contextoPantalla, mensaje);
                    }
                  } on ExcepcionApi catch (error) {
                    if (contextoPantalla.mounted) {
                      _mostrarMensajeCorreo(contextoPantalla, error.mensaje);
                    }
                  }
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Enviar correo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarMensajeCorreo(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

class _CabeceraIngreso extends StatelessWidget {
  const _CabeceraIngreso();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ContenedorResponsivo(
        anchoMaximo: 520,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MarcaUbbike(compacta: true, sobreAzul: true),
            const SizedBox(height: 22),
            Text(
              'UBBike',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acceso institucional para registrar, validar y revisar movimientos de bicicletas.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InsigniaCabecera(
                  icono: Icons.qr_code_2,
                  texto: 'QR temporal',
                ),
                _InsigniaCabecera(
                  icono: Icons.verified_user_outlined,
                  texto: 'Validacion',
                ),
                _InsigniaCabecera(
                  icono: Icons.history,
                  texto: 'Historial',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsigniaCabecera extends StatelessWidget {
  const _InsigniaCabecera({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 17, color: ColoresUbb.turquesa),
            const SizedBox(width: 6),
            Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioIngreso extends StatelessWidget {
  const _FormularioIngreso({
    required this.correoController,
    required this.contrasenaController,
    required this.cargando,
    required this.onIngresar,
    required this.onRegistro,
    required this.onRecuperar,
  });

  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final bool cargando;
  final VoidCallback onIngresar;
  final VoidCallback onRegistro;
  final VoidCallback onRecuperar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ColoresUbb.azulApp,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acceso institucional',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Usa tu correo UBB para continuar.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contrasenaController,
              decoration: const InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onIngresar(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRecuperar,
                child: const Text('Olvide mi contrasena'),
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: cargando ? null : onIngresar,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(cargando ? 'Ingresando...' : 'Ingresar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRegistro,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Solicitar registro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoSeguridad extends StatelessWidget {
  const _AvisoSeguridad();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUbb.turquesa.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.turquesa.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security_outlined, color: ColoresUbb.azulApp),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Registro y cambio de contrasena se validan mediante correo para mantener seguridad institucional.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.azulOscuro,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
