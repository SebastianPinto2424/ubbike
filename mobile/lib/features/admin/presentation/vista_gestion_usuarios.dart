import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../data/usuarios_admin_api.dart';

class VistaGestionUsuarios extends StatefulWidget {
  const VistaGestionUsuarios({super.key});

  @override
  State<VistaGestionUsuarios> createState() => _VistaGestionUsuariosState();
}

class _VistaGestionUsuariosState extends State<VistaGestionUsuarios> {
  final usuariosApi = UsuariosAdminApi();
  late Future<List<UsuarioApp>> futuroUsuarios;

  @override
  void initState() {
    super.initState();
    futuroUsuarios = usuariosApi.listarUsuarios();
  }

  void _recargar() {
    setState(() {
      futuroUsuarios = usuariosApi.listarUsuarios();
    });
  }

  Future<void> _actualizar(
    UsuarioApp usuario, {
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    try {
      await usuariosApi.actualizarPermisos(
        usuarioId: usuario.id,
        nombre: nombre,
        correo: correo,
        rut: rut,
        rol: rol,
        cuentaActiva: cuentaActiva,
        correoVerificado: correoVerificado,
      );
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos actualizados')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoAdminUsuarios(),
        const SizedBox(height: 16),
        FutureBuilder<List<UsuarioApp>>(
          future: futuroUsuarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const _EstadoUsuarios(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar usuarios',
                detalle: 'Revisa la conexion con el backend.',
              );
            }

            final usuarios = snapshot.data ?? [];

            if (usuarios.isEmpty) {
              return const _EstadoUsuarios(
                icono: Icons.people_outline,
                titulo: 'Sin usuarios',
                detalle: 'Los registros apareceran aqui.',
              );
            }

            return Column(
              children: usuarios
                  .map(
                    (usuario) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaUsuarioAdmin(
                        usuario: usuario,
                        onActualizar: _actualizar,
                        onEditarCredenciales: _editarCredenciales,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _editarCredenciales(UsuarioApp usuario) async {
    final nombreController = TextEditingController(text: usuario.nombre);
    final correoController = TextEditingController(text: usuario.correo);
    final rutController = TextEditingController(text: usuario.rut ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar credenciales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rutController,
              decoration: const InputDecoration(labelText: 'RUT'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true) {
      await _actualizar(
        usuario,
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim(),
        rut: rutController.text.trim(),
      );
    }

    nombreController.dispose();
    correoController.dispose();
    rutController.dispose();
  }
}

class _EncabezadoAdminUsuarios extends StatelessWidget {
  const _EncabezadoAdminUsuarios();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColoresUbb.azulNoche,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: ColoresUbb.turquesa,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuarios y permisos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra roles, accesos y verificacion de cuentas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaUsuarioAdmin extends StatelessWidget {
  const _TarjetaUsuarioAdmin({
    required this.usuario,
    required this.onActualizar,
    required this.onEditarCredenciales,
  });

  final UsuarioApp usuario;
  final Future<void> Function(
    UsuarioApp usuario, {
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) onActualizar;
  final Future<void> Function(UsuarioApp usuario) onEditarCredenciales;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: ColoresUbb.azulApp,
                  child: Text(
                    usuario.nombre.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usuario.correo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<RolUsuario>(
                  tooltip: 'Cambiar rol',
                  onSelected: (rol) => onActualizar(usuario, rol: rol),
                  itemBuilder: (context) => RolUsuario.values
                      .map(
                        (rol) => PopupMenuItem(
                          value: rol,
                          child: Text(rol.etiqueta),
                        ),
                      )
                      .toList(),
                  icon: const Icon(Icons.manage_accounts_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChipEstado(
                  texto: usuario.rol.etiqueta,
                  color: ColoresUbb.azulApp,
                ),
                ChipEstado(
                  texto: usuario.cuentaActiva ? 'Activo' : 'Acceso denegado',
                  color: usuario.cuentaActiva
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                ChipEstado(
                  texto: usuario.correoVerificado
                      ? 'Correo verificado'
                      : 'Correo pendiente',
                  color: usuario.correoVerificado
                      ? ColoresUbb.exito
                      : ColoresUbb.amarilloInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onActualizar(
                      usuario,
                      cuentaActiva: !usuario.cuentaActiva,
                    ),
                    icon: Icon(
                      usuario.cuentaActiva
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      usuario.cuentaActiva ? 'Denegar' : 'Habilitar',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: usuario.correoVerificado
                        ? null
                        : () => onActualizar(
                              usuario,
                              correoVerificado: true,
                            ),
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: const Text('Verificar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onEditarCredenciales(usuario),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar datos de cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoUsuarios extends StatelessWidget {
  const _EstadoUsuarios({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icono, color: ColoresUbb.azulApp, size: 44),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(detalle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
