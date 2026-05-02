import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class UsuariosAdminApi {
  UsuariosAdminApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<UsuarioApp>> listarUsuarios() async {
    final respuesta = await cliente.get('/usuarios');
    final datos = respuesta['usuarios'] as List<dynamic>;
    return datos
        .map((item) => UsuarioApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioApp> actualizarPermisos({
    required String usuarioId,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    final respuesta = await cliente.patch(
      '/usuarios/$usuarioId/permisos',
      body: {
        if (rol != null) 'rol': rol.valorApi,
        if (cuentaActiva != null) 'cuentaActiva': cuentaActiva,
        if (correoVerificado != null) 'correoVerificado': correoVerificado,
      },
    );

    return UsuarioApp.desdeJson(respuesta['usuario'] as Map<String, dynamic>);
  }
}
