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
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final rutController = TextEditingController();
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
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
      appBar: AppBar(title: const Text('Registro')),
      body: ContenedorResponsivo(
        anchoMaximo: 560,
        child: ListView(
          children: [
            const MarcaUbbike(compacta: true),
            const SizedBox(height: 22),
            Text(
              'Solicitar cuenta',
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
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio.';
                          }
                          if (value.trim().length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: rutController,
                        decoration: const InputDecoration(
                          labelText: 'RUT',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El RUT es obligatorio.';
                          }
                          final rutRegex = RegExp(r'^\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]$');
                          if (!rutRegex.hasMatch(value)) {
                            return 'Formato incorrecto. Ej: 12.345.678-9 o 12345678-9';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo institucional',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio.';
                          }
                          if (!value.endsWith('@ubiobio.cl') && !value.endsWith('@alumnos.ubiobio.cl')) {
                            return 'Debe ser @ubiobio.cl o @alumnos.ubiobio.cl';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contrasenaController,
                        decoration: const InputDecoration(
                          labelText: 'Contrasena',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contrasena es obligatoria.';
                          }
                          if (value.length < 8) {
                            return 'La contrasena debe tener al menos 8 caracteres.';
                          }
                          return null;
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
                          cargando ? 'Enviando...' : 'Enviar solicitud',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrar() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => cargando = true);

    try {
      final correo = correoController.text.trim();
      final rolDeterminado = correo.endsWith('@alumnos.ubiobio.cl')
          ? RolUsuario.estudiante
          : RolUsuario.funcionario;

      final mensaje = await autenticacionApi.registrar(
        nombre: nombreController.text.trim(),
        rut: rutController.text.trim(),
        correo: correo,
        contrasena: contrasenaController.text,
        rol: rolDeterminado,
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
