# Módulo 3. Técnico

## 3.1 Consultar perfil

**Prioridad:** Alta

Como técnico, quiero consultar la información de mi perfil para verificar los datos personales registrados en el sistema.

### Criterios de aceptación

- El técnico debe poder acceder a la sección de su perfil después de iniciar sesión.
- El sistema debe mostrar únicamente la información correspondiente al técnico autenticado.
- La información mostrada debe corresponder a los datos almacenados en el sistema.
- Desde la consulta del perfil, el técnico debe tener disponible la opción para modificar su información.

## 3.2 Modificar perfil

**Prioridad:** Sin definir

Como técnico, quiero modificar la información de mi perfil, para mantener actualizados mis datos personales y de contacto.

### Criterios de aceptación

- El técnico debe poder acceder a la opción de modificar perfil desde la vista de su propio perfil en la aplicación.
- El técnico deberá poder modificar únicamente sus datos de contacto y personales permitidos, como número de teléfono y correo electrónico.
- La especialidad del técnico (ej. Luz, Agua, Estructura) y la zona o edificio asignado deberán mostrarse en su perfil como información de solo lectura.
- Los cambios de especialidad únicamente podrán ser realizados por el administrador desde su módulo de gestión de perfiles.
- El sistema debe validar que los campos (como el formato del teléfono o correo) contienen información válida antes de guardar los cambios.
- Si la información es válida, el sistema debe guardar las modificaciones realizadas en la base de datos.
- Después de guardar, el sistema debe mostrar un mensaje de éxito y reflejar la información actualizada en el perfil.
- Si existe algún dato inválido, el sistema debe informar al técnico con un mensaje de error claro y no guardar los cambios incorrectos.

## 3.3 Consultar incidencias asignadas

**Prioridad:** Sin definir

Como técnico, quiero consultar la lista de incidencias que me han sido asignadas, para identificar los trabajos que debo atender.

### Criterios de aceptación

- El técnico debe poder acceder a una sección donde se muestran las incidencias que tiene asignadas.
- El sistema debe mostrar únicamente las incidencias asignadas al técnico autenticado.
- Cada incidencia debe mostrar información básica para identificarla, como:
  - Número de reporte.
  - Nombre de la incidencia.
  - Tipo de incidencia.
  - Fecha de creación.
  - Estado actual.
- La sección debe mostrar las incidencias activas que se encuentren en estado Asignada o En proceso.
- El técnico debe poder seleccionar una incidencia para consultar su información detallada.
- Las incidencias que sean marcadas como Resueltas deben dejar de aparecer entre las incidencias activas y quedar disponibles en el historial del técnico.
- Si el técnico no tiene incidencias asignadas, el sistema debe mostrar un mensaje indicando que no existen incidencias pendientes de atención.

## 3.4 Consultar detalles y evidencias de una incidencia

**Prioridad:** Alta

Como técnico, quiero ver los detalles completos y las evidencias (fotos/videos) de una incidencia asignada, para entender el problema a fondo antes de atenderlo.

### Criterios de aceptación

- Al seleccionar un reporte de la lista, el sistema debe abrir una vista de detalle.
- El sistema debe mostrar como mínimo:
  - Número de reporte.
  - Nombre de la incidencia.
  - Tipo de incidencia.
  - Descripción del problema.
  - Fotografías y videos registrados por el residente.
  - Fecha de creación.
  - Estado actual.
  - Hora estimada de llegada establecida por el administrador.
  - Nombre del residente que registró la incidencia.
  - Número de departamento.
- El sistema debe renderizar correctamente las evidencias multimedia (imágenes y videos) adjuntas por el residente.
- La información mostrada debe corresponder con los datos registrados por el residente y el administrador.
- Si la incidencia se encuentra en estado Asignada, debe estar disponible la opción “Comenzar atención”.

## 3.5 Comenzar la atención de una incidencia

**Prioridad:** Alta

Como técnico, quiero comenzar la atención de una incidencia asignada para indicar que he iniciado el trabajo correspondiente.

### Criterios de aceptación

- El técnico debe poder comenzar únicamente incidencias que estén asignadas a él.
- La opción “Comenzar atención” debe estar disponible cuando la incidencia se encuentre en estado Asignada.
- Al seleccionar “Comenzar atención”, el sistema debe cambiar el estado de la incidencia de Asignada a En proceso.
- El nuevo estado debe reflejarse tanto para el técnico como para el residente y el administrador.
- Después de comenzar la atención, el técnico debe poder continuar con el proceso de resolución de la incidencia.

## 3.6 Registrar la solución y evidencias de una incidencia

**Prioridad:** Alta

Como técnico, quiero adjuntar fotografías o videos de la reparación realizada, para dejar constancia visual del trabajo terminado y la solución aplicada.

### Criterios de aceptación

- El técnico debe poder ingresar una descripción de la solución aplicada.
- La incidencia debe encontrarse en estado En proceso para registrar la solución.
- El técnico debe poder adjuntar evidencias de la reparación.
- El técnico debe poder revisar la información ingresada antes de finalizar la incidencia.
- Si falta información obligatoria, el sistema debe informar al técnico y evitar que se complete incorrectamente el registro.
- La información registrada debe quedar disponible posteriormente para consulta del residente, técnico y administrador.

## 3.7 Finalizar una incidencia como resuelta

**Prioridad:** Alta

Como técnico, quiero finalizar una incidencia que ya he atendido para indicar que el problema ha sido solucionado.

### Criterios de aceptación

- El técnico debe poder finalizar únicamente incidencias que estén asignadas a él.
- La incidencia debe encontrarse en estado En proceso.
- Antes de finalizarla, el sistema debe verificar que se haya registrado la información correspondiente a la solución.
- Al finalizar correctamente la incidencia, su estado debe cambiar de En proceso a Resuelto.
- Al cerrar el reporte, el sistema debe enviar una notificación al residente indicando que su incidencia ha sido resuelta y mostrándole las evidencias finales.
- Al completar el reporte, el sistema debe marcar automáticamente al técnico con estado "Disponible" para nuevos reportes.
- El chat directo entre el técnico y el residente debe cerrarse (bloquearse) automáticamente, ya que su tiempo de vida termina al cerrar el reporte.
- La fecha de resolución debe registrarse automáticamente.

## 3.8 Consultar historial de incidencias atendidas

**Prioridad:** Media

Como técnico, quiero consultar el historial de las incidencias que he atendido en el pasado, para tener un registro de mi trabajo, desempeño y las soluciones que he aplicado.

### Criterios de aceptación

- El sistema debe contar con una sección o pestaña específica llamada "Historial" o "Reportes atendidos".
- Esta sección solo debe mostrar los reportes que el técnico ha finalizado con el estado "Resuelto".
- Debe permitir consultar los detalles finales, las evidencias de reparación y la fecha de resolución de cada incidencia.
- El sistema debe permitir filtrar o buscar en el historial por tipo de incidencia o por rango de fechas.
- Si no existen incidencias que coincidan con los filtros aplicados, el sistema debe mostrar un mensaje indicando que no se encontraron resultados.
