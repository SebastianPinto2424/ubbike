part of 'pantalla_principal.dart';

class VistaPerfil extends StatelessWidget {
  const VistaPerfil({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context) {
    final usuarioSesion = SesionActual.usuario;
    final nombre = switch (rol) {
      RolUsuario.guardia => 'Guardia M. Salazar',
      RolUsuario.adminCentral => 'Admin Central Seguridad',
      RolUsuario.administrador => 'Administrador UBBike',
      RolUsuario.funcionario => 'Funcionario UBB',
      RolUsuario.estudiante => 'Sebastian Pinto',
    };
    final correo = switch (rol) {
      RolUsuario.estudiante => 'sebastian.pinto@alumnos.ubiobio.cl',
      RolUsuario.funcionario => 'funcionario@ubiobio.cl',
      RolUsuario.guardia => 'guardia.salazar@ubiobio.cl',
      RolUsuario.adminCentral => 'admin.central@ubiobio.cl',
      RolUsuario.administrador => 'administrador@ubiobio.cl',
    };
    final nombrePerfil = _textoNoVacio(usuarioSesion?.nombre, nombre);
    final correoPerfil = _textoNoVacio(usuarioSesion?.correo, correo);
    final rutPerfil = _textoNoVacio(usuarioSesion?.rut, '20.123.456-7');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _EncabezadoSeccion(
          titulo: 'Mi Cuenta',
          detalle:
              'Gestiona tu informacion personal y configuracion de seguridad.',
          icono: Icons.person_outline,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColoresUbb.azulApp.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: ColoresUbb.azulApp.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: ColoresUbb.azulApp,
                      child: Text(
                        _inicialSegura(nombrePerfil),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    nombrePerfil,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: ColoresUbb.azulNoche,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColoresUbb.azulApp.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      rol.etiqueta,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ColoresUbb.azulApp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _DatoPerfilBox(
                    etiqueta: 'Correo',
                    valor: correoPerfil,
                    icono: Icons.email_outlined),
                const SizedBox(height: 12),
                _DatoPerfilBox(
                    etiqueta: 'RUT',
                    valor: rutPerfil,
                    icono: Icons.badge_outlined),
                const SizedBox(height: 12),
                _DatoPerfilBox(
                    etiqueta: 'Estado',
                    valor: 'Correo verificado',
                    icono: Icons.verified_user_outlined),
                if (rol == RolUsuario.guardia) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  const _SelectorBicicleteroGuardiaPerfil(),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: ColoresUbb.azulApp.withOpacity(0.1),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    try {
                      final mensaje = await AutenticacionApi()
                          .solicitarCambioContrasena(correoPerfil);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(mensaje)),
                        );
                      }
                    } on ExcepcionApi catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.mensaje)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.mark_email_unread_outlined,
                      color: ColoresUbb.azulApp),
                  label: const Text(
                    'Cambiar contrasena',
                    style: TextStyle(
                        color: ColoresUbb.azulApp,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Se enviara un correo electronico con un enlace seguro para cambiar tu contrasena.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                      ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        ColoresUbb.rojoInstitucional.withOpacity(0.1),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    SesionActual.cerrar();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const PantallaLogin()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout,
                      color: ColoresUbb.rojoInstitucional),
                  label: const Text(
                    'Cerrar sesion',
                    style: TextStyle(
                        color: ColoresUbb.rojoInstitucional,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DatoPerfilBox extends StatelessWidget {
  const _DatoPerfilBox({
    required this.etiqueta,
    required this.valor,
    required this.icono,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave, // Fondo de componente
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: ColoresUbb.azulApp.withOpacity(0.08)), // Borde sutil
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    spreadRadius: 1),
              ],
            ),
            child: Icon(icono, color: ColoresUbb.azulApp, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ColoresUbb.azulNoche,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorBicicleteroGuardiaPerfil extends StatefulWidget {
  const _SelectorBicicleteroGuardiaPerfil();

  @override
  State<_SelectorBicicleteroGuardiaPerfil> createState() =>
      _SelectorBicicleteroGuardiaPerfilState();
}

class _SelectorBicicleteroGuardiaPerfilState
    extends State<_SelectorBicicleteroGuardiaPerfil> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  List<BicicleteroApp> bicicleteros = [];
  BicicleteroApp? bicicleteroSeleccionado;
  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);

    try {
      final resultados = await Future.wait([
        solicitudGuardiaApi.listarBicicleteros(),
        solicitudGuardiaApi.obtenerBicicleteroGestionado(),
      ]);
      final lista = resultados[0] as List<BicicleteroApp>;
      final actual = resultados[1] as BicicleteroApp?;
      final seleccionado = actual == null
          ? (lista.isEmpty ? null : lista.first)
          : lista.cast<BicicleteroApp?>().firstWhere(
                (item) => item?.id == actual.id,
                orElse: () => lista.isEmpty ? null : lista.first,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteros = lista;
        bicicleteroSeleccionado = seleccionado;
        cargando = false;
      });
    } on ExcepcionApi catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.mensaje)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el backend')),
      );
    }
  }

  Future<void> _guardar() async {
    final seleccionado = bicicleteroSeleccionado;
    if (seleccionado == null || guardando) {
      return;
    }

    setState(() => guardando = true);

    try {
      final actualizado = await solicitudGuardiaApi
          .seleccionarBicicleteroGestionado(seleccionado.id);

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteros = bicicleteros
            .map((item) => item.id == actualizado.id ? actualizado : item)
            .toList();
        bicicleteroSeleccionado = bicicleteros.firstWhere(
          (item) => item.id == actualizado.id,
        );
        guardando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ahora gestionas ${actualizado.nombre}')),
      );
    } on ExcepcionApi catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.mensaje)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el backend')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bicicleteros.isEmpty) {
      return const _EstadoLista(
        icono: Icons.location_off_outlined,
        titulo: 'Sin bicicleteros activos',
        detalle: 'Central debe habilitar al menos un bicicletero.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bicicletero de turno',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<BicicleteroApp>(
          initialValue: bicicleteroSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Bicicletero que gestionaras',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: bicicleteros
              .map(
                (bicicletero) => DropdownMenuItem(
                  value: bicicletero,
                  child: Text(
                    '${bicicletero.nombre} (${bicicletero.cuposDisponibles} cupos)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: guardando
              ? null
              : (valor) => setState(() => bicicleteroSeleccionado = valor),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed:
              guardando || bicicleteroSeleccionado == null ? null : _guardar,
          icon: guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar bicicletero de turno'),
        ),
      ],
    );
  }
}
