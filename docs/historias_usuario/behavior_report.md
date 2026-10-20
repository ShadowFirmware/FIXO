# Módulo 7. Reportes de Conducta

## 7.1 Reportar la conducta de un técnico

**Prioridad:** Media

Como residente, quiero reportar la conducta del técnico que atendió mi incidencia una vez que ésta haya sido resuelta, para informar al administrador sobre algún comportamiento o situación inapropiada ocurrida durante la atención.

### Criterios de aceptación

- La opción “Reportar técnico” solo deberá habilitarse cuando la incidencia tenga el estado Resuelta.
- El residente no deberá poder generar un reporte de conducta mientras la incidencia se encuentre en estado Pendiente, Asignada o En proceso.
- El residente deberá poder reportar únicamente al técnico que atendió la incidencia.
- El reporte de conducta deberá estar relacionado con la incidencia resuelta correspondiente.
- El sistema deberá solicitar un motivo del reporte.
- El motivo deberá seleccionarse de una lista de opciones, como retraso, mala actitud, trabajo mal realizado u otros motivos definidos por el sistema.
- El residente deberá poder ingresar una descripción de lo ocurrido.
- El residente podrá adjuntar evidencias de manera opcional, como fotografías, videos o capturas de chat.
- Al enviar el reporte, el sistema deberá generar automáticamente un identificador único.
- El administrador deberá recibir una notificación indicando que existe un nuevo reporte de conducta.
- Al enviar el reporte de conducta, este deberá registrarse con estado “Pendiente de revisión”.
- El envío de un reporte de conducta no deberá modificar inmediatamente el estado de conducta ni el estado de la cuenta del técnico reportado.
- El reporte únicamente contará como antecedente de conducta cuando haya sido validado por el administrador.
- Cada usuario podrá generar como máximo un reporte de conducta contra la contraparte por cada incidencia resuelta.

## 7.2 Reportar la conducta de un residente

**Prioridad:** Media

Como técnico, quiero reportar la conducta del residente una vez que la incidencia que atendí haya sido resuelta, para informar al administrador sobre algún comportamiento o situación inapropiada ocurrida durante la atención.

### Criterios de aceptación

- La opción “Reportar residente” solo deberá habilitarse cuando la incidencia tenga el estado Resuelta.
- El técnico no deberá poder generar un reporte de conducta mientras la incidencia se encuentre en estado Pendiente, Asignada o En proceso.
- El técnico deberá poder reportar únicamente al residente específico que registró o interactuó en la incidencia atendida.
- El reporte de conducta deberá estar relacionado con la incidencia resuelta correspondiente.
- El sistema deberá solicitar un motivo del reporte.
- El motivo deberá seleccionarse de una lista de opciones, como insultos, groserías, falta de cooperación u otros motivos definidos por el sistema.
- El técnico deberá poder ingresar una descripción detallada de lo ocurrido.
- El técnico podrá adjuntar evidencias de manera opcional, como fotografías, videos o capturas de chat.
- Al enviar el reporte de conducta, este deberá registrarse con estado “Pendiente de revisión”.
- El envío del reporte no deberá modificar automáticamente el estado de conducta ni bloquear la cuenta del residente.
- El reporte solo deberá contabilizarse como antecedente cuando el administrador lo marque como Validado.
- El administrador deberá recibir una notificación sobre el nuevo reporte pendiente de revisión.
- Cada usuario podrá generar como máximo un reporte de conducta contra la contraparte por cada incidencia resuelta.

## 7.3 Revisar y validar reportes de conducta

**Prioridad:** Alta

Como administrador, quiero revisar los reportes de conducta y sus evidencias para determinar si el comportamiento reportado es válido antes de que el sistema aplique consecuencias al usuario.

### Criterios de aceptación

- El administrador debe poder consultar todos los reportes de conducta registrados.
- El sistema debe identificar cada reporte con uno de los siguientes estados:
  - Pendiente de revisión.
  - Validado.
  - Rechazado.
- Cada reporte debe mostrar como mínimo:
  - Identificador.
  - Usuario que realizó el reporte.
  - Usuario reportado.
  - Incidencia relacionada.
  - Motivo.
  - Descripción de lo ocurrido.
  - Fecha.
  - Fotografías, videos o capturas del chat asociadas como evidencia, cuando existan.
- El administrador debe poder visualizar las evidencias proporcionadas.
- El administrador debe poder marcar el reporte como Validado o Rechazado.

## 7.4 Gestionar estado de conducta y sanciones

**Prioridad:** Alta

Como administrador, quiero que el sistema lleve el historial de reportes de conducta validados y aplique progresivamente las medidas correspondientes, para controlar reincidencias de residentes y técnicos.

### Criterios de aceptación

- Todo residente y técnico nuevo debe iniciar con estado de conducta Bueno.
- Únicamente los reportes de conducta validados por un administrador deberán contabilizarse para determinar el estado de conducta del usuario.
- El sistema debe mantener un contador histórico de reportes de conducta validados para cada residente y técnico.
- Al recibir el primer reporte validado:
  - El estado de conducta deberá permanecer en Bueno.
  - El usuario deberá recibir una llamada de atención mediante notificación.
- Al recibir el segundo reporte validado:
  - El estado de conducta deberá cambiar a Medio.
  - La cuenta deberá suspenderse automáticamente durante 5 días.
  - El usuario deberá recibir una notificación indicando la sanción y las consecuencias de nuevas reincidencias.
- Al recibir el tercer reporte validado:
  - El estado de conducta deberá permanecer en Medio.
  - La cuenta deberá suspenderse automáticamente durante 10 días.
  - El usuario deberá recibir una nueva advertencia.
- Al recibir el cuarto reporte validado:
  - El estado de conducta deberá cambiar a Malo.
  - La cuenta deberá suspenderse automáticamente durante 20 días.
  - El usuario deberá recibir una advertencia indicando el riesgo de baja indefinida.
- Al recibir el quinto reporte validado:
  - El estado de conducta deberá permanecer en Malo.
  - La cuenta deberá quedar deshabilitada de forma indefinida.
  - El usuario deberá recibir una notificación indicando que su cuenta ha sido deshabilitada.
- Una vez cumplido el periodo de una suspensión temporal de 5, 10 o 20 días, el sistema deberá reactivar automáticamente la cuenta.
- Una cuenta deshabilitada indefinidamente sólo podrá ser reactivada mediante una acción explícita del administrador.
- Si una cuenta reactivada después de una deshabilitación indefinida recibe posteriormente otro reporte de conducta validado, deberá volver a quedar deshabilitada de forma automática.
- Si una sanción temporal debe aplicarse a un técnico que tiene una incidencia en estado Asignada o En proceso, el sistema deberá impedir inmediatamente que reciba nuevas asignaciones y notificará al administrador sobre las incidencias activas asociadas al técnico.
- El administrador deberá poder reasignar dichas incidencias a otro técnico disponible.
- Una vez que el técnico no tenga incidencias activas asignadas, deberá aplicarse la suspensión correspondiente.
