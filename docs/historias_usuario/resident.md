# Módulo 2. Residente

## 2.1 Consultar perfil

**Prioridad:** Media

Como residente, quiero consultar la información de mi perfil para verificar los datos personales registrados en el sistema.

### Criterios de aceptación

- El residente debe poder acceder a la sección de su perfil después de iniciar sesión.
- El sistema debe mostrar únicamente la información correspondiente al residente autenticado.
- La información mostrada debe corresponder a los datos almacenados en el sistema.
- Desde la consulta del perfil, el residente debe tener disponible la opción para modificar su información.

## 2.2 Modificar perfil

**Prioridad:** Media

Como residente, quiero modificar la información de mi perfil para mantener actualizados mis datos personales y de contacto.

### Criterios de aceptación

- El residente debe poder acceder a la opción de modificar perfil desde la consulta de su perfil.
- El residente deberá poder modificar únicamente los datos personales permitidos, como nombre y teléfono.
- El lugar de residencia asignado deberá mostrarse en su perfil como información de solo lectura.
- El cambio de vivienda únicamente podrá ser realizado por un administrador.
- El sistema debe validar que los campos contienen información válida antes de guardar los cambios.
- Si la información es válida, el sistema debe guardar las modificaciones realizadas.
- Después de guardar, el sistema debe mostrar la información actualizada.
- Si existe algún dato inválido el sistema debe informar al residente y no guardar los cambios incorrectos.

## 2.3 Registrar incidencia

**Prioridad:** Alta

Como residente, quiero registrar una incidencia proporcionando la información y evidencias del problema para solicitar que sea atendido por un técnico.

### Criterios de aceptación

- El residente debe poder acceder a la opción para crear una nueva incidencia.
- El sistema debe permitir ingresar un nombre o título para la incidencia.
- El residente debe seleccionar el tipo de incidencia correspondiente.
- Los tipos de incidencia disponibles deben incluir como mínimo: Luz, Agua, Estructura y Otros.
- El residente debe poder ingresar una descripción detallada del problema.
- El residente debe poder adjuntar fotografías y videos como evidencia de la incidencia.
- El sistema debe validar que los campos obligatorios estén completos antes de permitir el registro.
- Al registrar correctamente la incidencia, el sistema debe generar automáticamente un número único de reporte.
- La incidencia se asocia automáticamente al departamento del residente que la registra.
- Toda incidencia debe registrarse inicialmente con estado Pendiente.
- Después del registro exitoso, el sistema debe permitir al residente consultar la incidencia generada.
- El administrador debe ser notificado de la existencia de una nueva incidencia pendiente de asignación.

## 2.4 Consultar detalles de la incidencia

**Prioridad:** Alta

Como residente, quiero consultar los detalles de una incidencia que he registrado para conocer su información, estado actual y seguimiento.

### Criterios de aceptación

- El residente debe poder seleccionar una de sus incidencias para consultar su información detallada.
- El residente únicamente debe poder consultar incidencias de su departamento.
- El sistema debe mostrar como mínimo:
  - Número del reporte.
  - Nombre de la incidencia.
  - Tipo de incidencia.
  - Descripción.
  - Fotografías y videos registrados.
  - Fecha de creación.
  - Estado actual.
  - Departamento.
- El estado mostrado debe corresponder al estado actual de la incidencia: Pendiente, Asignada, Rechazada, En proceso o Resuelta.
- Si la incidencia se encuentra en estado Asignada o posterior, el sistema debe mostrar la información del técnico asignado.
- Cuando exista una hora estimada de llegada, esta debe mostrarse al residente.
- Cuando la incidencia se encuentre Resuelta, el sistema debe mostrar la información registrada sobre la solución.
- La información mostrada debe actualizarse conforme cambie el estado de la incidencia.
- Cuando la incidencia se encuentre en estado Rechazada, el sistema deberá mostrar el comentario con el motivo registrado por el administrador y la fecha en que se realizó el rechazo.
- Una incidencia rechazada no deberá mostrar información de técnico asignado ni hora estimada de llegada.

## 2.5 Consultar historial de incidencias

**Prioridad:** Media

Como residente, quiero consultar el historial de mis incidencias para revisar los reportes que he realizado y conocer su estado y resultado.

### Criterios de aceptación

- El residente debe poder acceder a una sección con el historial de sus incidencias.
- El sistema debe mostrar únicamente las incidencias del departamento del residente autenticado (ej. si un nuevo residente entra al Depto 4B, ve el historial del 4B, no solo lo que él reportó).
- Cada elemento del historial debe mostrar información suficiente para identificar el reporte, como:
  - Número del reporte.
  - Nombre de la incidencia.
  - Tipo de incidencia.
  - Fecha de creación.
  - Estado.
- El residente debe poder seleccionar una incidencia del historial para consultar su detalle completo.
- El historial debe incluir incidencias en cualquiera de los estados: Pendiente, Asignada, Rechazada, En proceso y Resuelta.
- Para incidencias resueltas, el residente debe poder acceder a la información de resolución y evidencias correspondientes y, si es rechazada, mostrar el comentario del administrador y la fecha.
- El historial debe permitir aplicar filtros para facilitar la búsqueda de incidencias.
- Cuando no existan incidencias que coincidan con el filtro seleccionado, el sistema debe indicar que no se encontraron resultados.
