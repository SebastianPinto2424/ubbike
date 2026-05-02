# Diseno de interfaces MVP - UBBike

## Enfoque seleccionado

Se aplica un prototipo MVP por roles con pantallas clave. Esta opcion permite mostrar el flujo real del sistema sin sobrecargar la primera entrega.

Roles considerados:

- Estudiante.
- Funcionario.
- Guardia.
- Central.

El rol no se selecciona como parte normal del inicio de sesion. En produccion, el backend identifica el rol desde la cuenta registrada. El selector visible en el login se mantiene solo como modo de presentacion para navegar el prototipo.

## Paleta institucional

Se usa la paleta institucional UBB indicada en el Manual de Normas Graficas UBB 2025:

- Azul institucional: `#014898`.
- Gris institucional: `#B9BBBB`.
- Rojo institucional: `#E41B1A`.
- Amarillo institucional: `#F9B214`.

Fuente: https://dgce.ubiobio.cl/img/manual/Manual_de_Normas_Graficas_UBB2025.pdf

## Pantallas implementadas

### Autenticacion

- Login.
- Solicitud de registro.
- Verificacion de cuenta por correo institucional.
- Recuperacion o cambio de contrasena mediante correo.
- Modo de presentacion para simular perfil estudiante, funcionario, guardia o central.

### Usuario estudiante o funcionario

- Inicio con estado actual.
- Listado de bicicleteros.
- Mis bicicletas.
- Generacion de QR.
- Solicitud de guardia a central.
- Perfil.

### Guardia

- Turno activo.
- Bicicletero asignado.
- Escaneo de QR.
- Confirmacion de ingreso o retiro desde QR temporal.
- Denegacion de ingreso o retiro con motivo obligatorio.
- Gestion manual por correo institucional y RUT.
- Alertas asignadas.
- Perfil.

### Central

- Panel operativo.
- Solicitudes pendientes.
- Dashboard basado en historial.
- Filtro de movimientos por RUT, correo institucional o nombre.
- Operaciones por guardia filtrables por dia, semana y mes.
- Perfil.

## Flujo principal de uso

1. El usuario inicia sesion.
2. El sistema identifica su rol desde la cuenta.
3. El usuario selecciona su bicicleta y genera QR temporal.
4. El guardia escanea el QR.
5. El guardia confirma o deniega el movimiento indicando motivo.
6. Si no hay QR, el guardia usa gestion manual con correo institucional y RUT.
7. El sistema registra el historial.
8. Si el guardia no esta visible, el usuario solicita asistencia.
9. Central recibe la solicitud y coordina al guardia asignado.

## Criterios de diseno aplicados

- Interfaz limpia e institucional.
- Pantallas no sobrecargadas.
- Navegacion inferior con apartados estables.
- Navegacion diferenciada por rol.
- Estados visuales para solicitudes y validaciones.
- Botones claros para acciones criticas.
- Diseno adaptable a pantalla movil y vista web de presentacion.
