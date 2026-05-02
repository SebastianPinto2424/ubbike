import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final nombreController = TextEditingController();
  final rutController = TextEditingController();
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  RolUsuario rolSolicitado = RolUsuario.estudiante;
  bool cargando = false;

  @override
  void dispose() {
    nombreController.dispose();
    rutController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar registro')),
      body: ContenedorResponsivo(
        anchoMaximo: 560,
        child: ListView(
          children: [
            const MarcaUbbike(compacta: true),
            const SizedBox(height: 22),
            Text(
              'Registro con verificacion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColoresUbb.azulOscuro,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se enviara un correo de activacion. La cuenta no queda habilitada hasta confirmar el enlace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rutController,
                      decoration: const InputDecoration(
                        labelText: 'RUT',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(
                        labelText: 'Correo institucional',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contrasenaController,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RolUsuario>(
                      initialValue: rolSolicitado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de cuenta solicitada',
                        prefixIcon: Icon(Icons.manage_accounts_outlined),
                      ),
                      items: RolUsuario.values
                          .where((rol) => rol != RolUsuario.administrador)
                          .map(
                            (rol) => DropdownMenuItem(
                              value: rol,
                              child: Text(rol.etiqueta),
                            ),
                          )
                          .toList(),
                      onChanged: (rol) {
                        if (rol != null) {
                          setState(() => rolSolicitado = rol);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: cargando ? null : _registrar,
                      icon: cargando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_read_outlined),
                      label: Text(
                        cargando
                            ? 'Enviando...'
                            : 'Enviar correo de verificacion',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrar() async {
    if (nombreController.text.trim().isEmpty ||
        rutController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        contrasenaController.text.isEmpty) {
      _mostrarMensaje('Completa todos los campos');
      return;
    }

    setState(() => cargando = true);

    try {
      final mensaje = await autenticacionApi.registrar(
        nombre: nombreController.text.trim(),
        rut: rutController.text.trim(),
        correo: correoController.text.trim(),
        contrasena: contrasenaController.text,
        rol: rolSolicitado,
      );

      if (mounted) {
        _mostrarConfirmacion(context, mensaje);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _mostrarMensaje(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensaje('No se pudo conectar con el backend');
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _mostrarConfirmacion(BuildContext context, String mensaje) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Correo enviado'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Volver al ingreso'),
            ),
          ],
        );
      },
    );
  }
}
