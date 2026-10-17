# Módulo 4. Administrador

## 4.1 Consultar perfil

**Prioridad:** Alta

Como administrador, quiero consultar la información de mi perfil para verificar los datos personales registrados en el sistema.

### Criterios de aceptación

- El administrador debe poder acceder a la sección de su perfil después de iniciar sesión.
- El sistema debe mostrar únicamente la información correspondiente al administrador autenticado.
- La información mostrada debe corresponder a los datos almacenados en el sistema.
- Desde la consulta del perfil, el administrador debe tener disponible la opción para modificar su información.

## 4.2 Modificar perfil

**Prioridad:** Sin definir

Como administrador, quiero modificar la información de mi perfil, para mantener actualizados mis datos personales y de contacto dentro del sistema.

### Criterios de aceptación

- El administrador debe poder acceder a la opción de modificar perfil desde la consulta de su propio perfil en la aplicación web.
- El administrador deberá poder modificar únicamente sus datos personales y de contacto permitidos, como nombre, correo electrónico y teléfono.
- Si se edita el correo electrónico, el sistema debe validar que el nuevo correo no esté ya registrado por otro usuario en el sistema (validación de correo único).
- El sistema debe validar que los campos (formato de correo, longitud/formato de teléfono) contienen información válida antes de guardar los cambios.
- Si la información es válida, el sistema debe guardar las modificaciones realizadas en la base de datos.
- Después de guardar, el sistema debe mostrar un mensaje de éxito y reflejar la información actualizada en el perfil.
- Si existe algún dato inválido o duplicado, el sistema debe informar al administrador con un mensaje de error claro y no guardar los cambios incorrectos.

## 4.3 Registrar residente

**Prioridad:** Sin definir

Como administrador, quiero registrar nuevos residentes en el sistema con sus datos básicos y asignarles una vivienda previamente registrada en el sistema, para que puedan reportar incidencias y el sistema sepa exactamente en dónde vive cada residente para atender sus reportes.

### Criterios de aceptación

- El formulario de registro solicita los datos básicos: nombre completo, correo electrónico, teléfono y contraseña.
- El lugar de residencia (departamento, casa, edificio, etc.) no lo ingresa el residente: es un campo que solo el administrador puede asignar al momento del registro.
- El administrador debe asignar el lugar de residencia de forma obligatoria; el registro no se puede completar sin él.
- El correo electrónico debe ser único en el sistema.
- La contraseña debe tener mínimo 8 caracteres.
- Un mismo lugar de residencia (ej. "Depto 4B") no puede estar asignado a dos residentes activos al mismo tiempo (validación de duplicados).
- Al completar el registro, el residente aparece en la lista de usuarios con rol "Residente" y con su lugar de residencia asignado.
- El residente puede iniciar sesión con su correo y contraseña, y su perfil ya muestra su lugar de residencia.
- Al registrar correctamente al residente, su estado de conducta deberá establecerse automáticamente como “Bueno” y su cuenta como “Activa”.

## 4.4 Registrar técnico

**Prioridad:** Alta

Como administrador, quiero registrar nuevos técnicos en el sistema, para contar con personal disponible que pueda ser asignado a las incidencias reportadas por los residentes.

### Criterios de aceptación

- El formulario de registro solicita nombre completo, correo electrónico, teléfono, especialidad y contraseña.
- El correo electrónico debe ser único en el sistema.
- La contraseña debe tener mínimo 8 caracteres.
- Al completar el registro, el técnico aparece en la lista de usuarios con rol "Técnico".
- Al registrar correctamente al técnico, su estado de conducta deberá establecerse automáticamente como “Bueno” y su cuenta como “Activa”.

## 4.5 Editar información de residentes y técnicos

**Prioridad:** Media

Como administrador, quiero editar la información de los perfiles de residentes y técnicos, para mantener los datos actualizados y corregir errores de registro.

### Criterios de aceptación

- El administrador puede editar nombre, correo, teléfono y departamento (residentes) o especialidad (técnicos).
- Si se edita el correo, el sistema valida que el nuevo correo no exista ya en el sistema.
- Los cambios se reflejan de inmediato en la lista de usuarios.
- Si se cambia el departamento de un residente, las incidencias (abiertas o históricas) se quedan asociadas al departamento original, no se transfieren con el usuario.
- Si el administrador modifica la vivienda asignada a un residente, el sistema únicamente deberá permitir seleccionar una vivienda activa y disponible.
- Una vivienda que ya tenga otro residente activo no podrá ser asignada.
- Al realizar correctamente el cambio, la vivienda anterior deberá quedar disponible para ser asignada a otro residente.
- Las incidencias creadas antes del cambio deberán permanecer asociadas a la vivienda en la que fueron registradas y no deberán trasladarse a la nueva vivienda del residente.

## 4.6 Dar de baja perfiles de residentes y técnicos

**Prioridad:** Media

Como administrador, quiero dar de baja las cuentas de residentes y técnicos que ya no pertenecen a la residencia o al equipo, para impedir su acceso al sistema sin perder la información histórica asociada.

### Criterios de aceptación

- Antes de dar de baja una cuenta, el sistema debe solicitar confirmación.
- Una cuenta dada de baja no podrá iniciar sesión.
- El sistema deberá conservar las incidencias, reportes de conducta, sanciones y demás registros históricos asociados al usuario.
- La información histórica deberá conservar la referencia al usuario que realizó cada acción.
- Cuando un residente sea dado de baja, su vivienda deberá quedar disponible para ser asignada a un nuevo residente.

## 4.7 Gestionar lugares de residencia

**Prioridad:** Alta

Como administrador, quiero gestionar los lugares de residencia disponibles en el sistema para poder asignarlos correctamente a los residentes registrados.

### Criterios de aceptación

- El administrador debe poder consultar los lugares de residencia registrados.
- El administrador debe poder registrar un nuevo lugar de residencia.
- Cada lugar debe contener la información necesaria para identificarlo, por ejemplo:
  - Tipo de residencia: departamento o casa.
  - Edificio, torre o sección, cuando corresponda.
  - Número o identificador de la vivienda.
- El sistema no debe permitir registrar dos lugares de residencia con la misma identificación dentro del mismo edificio o sección.
- El administrador debe poder modificar la información de un lugar de residencia.
- El administrador debe poder marcar un lugar como activo o inactivo.
- Si un lugar de residencia se marca como inactivo mientras tiene incidencias abiertas, el sistema debe permitir que dichas incidencias continúen su flujo normal de atención, pero se bloqueará la creación de nuevas incidencias para ese lugar.
- Al registrar o modificar un residente, el administrador debe poder seleccionar su lugar de residencia de entre los lugares disponibles registrados en el sistema.

## 4.8 Consultar incidencias pendientes de asignación

**Prioridad:** Media

Como administrador, quiero consultar las incidencias pendientes de asignación, para identificar rápidamente los reportes que aún no tienen técnico asignado y evitar que queden sin atención.

### Criterios de aceptación

- El sistema muestra una lista de todas las incidencias con estado "Pendiente".
- Cada incidencia muestra: número de reporte, nombre, tipo (luz, agua, estructura, etc.), detalles, evidencias, departamento, el usuario que registró la incidencia y fecha de creación.
- La lista se puede ordenar por fecha de creación (más antiguas primero, por defecto).
- El administrador puede filtrar por tipo de incidencia.

## 4.9 Asignar un técnico y establecer hora estimada

**Prioridad:** Media

Como administrador, quiero asignar un técnico a una incidencia y establecer una hora estimada de llegada, para que el residente sepa quién y cuándo atenderá su problema.

### Criterios de aceptación

- Al realizar una asignación, el sistema solo deberá mostrar técnicos con estado "Disponible" y estado de cuenta “Activa”.
- El administrador debe establecer obligatoriamente una hora estimada de llegada (selector de hora, no texto libre).
- Al confirmar la asignación, el estado de la incidencia cambia de "Pendiente" a "Asignada".
- El residente recibe una notificación con el nombre del técnico y la hora estimada de llegada.
- El técnico recibe una notificación con los detalles de la incidencia asignada.
- El técnico asignado cambia automáticamente a estado "No disponible" hasta que complete el reporte.
- Los técnicos con cuenta suspendida, dada de baja o deshabilitada indefinidamente no deberán estar disponibles para nuevas asignaciones.

## 4.10 Rechazar reporte

**Prioridad:** Media

Como administrador, quiero rechazar una incidencia pendiente indicando el motivo del rechazo en un comentario, para informar al residente por qué su reporte no procede y mantener un registro del rechazo.

### Criterios de aceptación

- Al seleccionar "Rechazar incidencia", el sistema debe solicitar un comentario obligatorio con el motivo del rechazo.
- El sistema no debe permitir rechazar si el comentario está vacío.
- El sistema debe pedir confirmación antes de rechazar.
- Al confirmar, el estado cambia de "Pendiente" a "Rechazado".
- El residente recibe una notificación indicando que su incidencia fue rechazada, con el comentario.
- No se asigna técnico, ni se crea chat.
- Una incidencia rechazada es un estado final: no puede asignarse después.

## 4.11 Consultar historial de incidencias

**Prioridad:** Baja

Como administrador, quiero consultar el historial completo de incidencias, para dar seguimiento a todos los reportes generados, su resolución y las evidencias del antes y después.

### Criterios de aceptación

- El administrador puede ver todas las incidencias, sin importar su estado (Pendiente, Asignada, En proceso, Resuelta o Rechazada).
- Cada incidencia muestra: número de reporte, nombre, tipo, detalles, evidencias, departamento, el usuario que registró la incidencia, técnico asignado, fecha de creación y fecha de resolución.
- Se puede filtrar por estado, tipo de incidencia, técnico, departamento y rango de fechas.
- Al abrir una incidencia, el administrador puede ver las evidencias del residente (antes) y del técnico (después).
- El historial se puede exportar a PDF.

## 4.12 Consultar estadísticas de incidencias por periodo

**Prioridad:** Baja

Como administrador, quiero consultar estadísticas de incidencias por periodo, para tomar decisiones informadas sobre mantenimiento, recursos y desempeño del equipo técnico.

### Criterios de aceptación

- El administrador puede seleccionar el periodo: semanal, mensual o rango personalizado.
- El dashboard muestra gráficas de:
  - Incidencias por tipo (luz, agua, estructura, etc.).
  - Incidencias por estado (pendientes, resueltas, en proceso o rechazadas).
  - Número de incidencias asignadas por técnico.
- Las estadísticas se actualizan en tiempo real con base en los datos del sistema.
