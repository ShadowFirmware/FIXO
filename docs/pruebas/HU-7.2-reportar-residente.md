# Plan de pruebas — HU 7.2 Reportar la conducta de un residente

| Dato | Valor |
|---|---|
| Módulo | 7. Reportes de conducta |
| Historia de usuario | HU 7.2 Reportar la conducta de un residente (#323) |
| Tarea | T 7.2.9 Probar el reporte de conducta del residente (#332) |
| Rama | `feature/HU-7.2-Reportar-la-conducta-de-un-residente` |
| Fecha | 21/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda reportar la conducta del residente de una incidencia que atendió, solo cuando la incidencia esté Resuelta. Puede reportar al residente que la registró o a quien participó en su chat. El reporte debe tener un motivo de la lista, una descripción y evidencias opcionales. Debe registrarse con estado Pendiente de revisión, y cada administrador debe recibir un aviso. El reporte no debe cambiar el estado de conducta ni la cuenta del residente, y el técnico solo puede enviar uno por residente en cada incidencia.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 7.2.1 | Sección "Conducta del residente" con el botón "Reportar residente" en el detalle de la incidencia del técnico (también desde su historial), solo cuando está Resuelta. Muestra los reportes ya enviados y deja de ofrecer a los residentes ya reportados |
| T 7.2.2 | Pantalla "Reportar residente": residente fijo si solo hay uno, o lista para elegir si hay varios; motivo, descripción, evidencias, aviso de revisión y confirmación con el folio |
| T 7.2.3 | Motivos: Insultos, Groserías, Falta de cooperación y Otro motivo, cada uno con su explicación |
| T 7.2.4 | Descripción obligatoria (10 a 500 caracteres) y hasta 5 evidencias opcionales (fotos o capturas de hasta 10 MB y videos de hasta 50 MB y 1 minuto), subidas a `fixo/reportesConducta/{id}` |
| T 7.2.5 | Condiciones: técnico con la cuenta activa, que atendió la incidencia, en estado Resuelta; el reportado es un residente que la registró o escribió en su chat. Se revisan en la app y de nuevo en la transacción con los datos actuales |
| T 7.2.6 | Un reporte por técnico, residente e incidencia: el documento se llama `{incidenciaId}_{tecnicoId}_{residenteId}`. Se revisa antes de subir las evidencias y otra vez en la transacción |
| T 7.2.7 | Documento en `reportesConducta` con folio consecutivo (`RC-…`, el mismo contador que la HU 7.1), incidencia relacionada, reportante (técnico), reportado (residente), motivo, descripción, evidencias, estado `pendiente_revision` y fecha del servidor |
| T 7.2.8 | Aviso "Nuevo reporte de conducta" a cada administrador activo, guardado en la misma transacción que el reporte |

**No incluye**

- La consulta, validación o rechazo de los reportes por el administrador (HU 7.3), ni el estado de conducta y las sanciones (HU 7.4). Al tocar el aviso del reporte todavía no se abre ninguna pantalla.
- Reglas de seguridad de Firestore (entorno de desarrollo): las reglas actuales permiten leer y escribir a cualquier usuario con sesión, así que la restricción se hace en la app.

Para compartir el formulario con la HU 7.1, el motivo, la descripción, las evidencias y el envío pasaron a una clase común (`ConductReportFormViewModel`). Las pruebas de la HU 7.1 (PU-648 a PU-667) siguen pasando sin cambios.

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | La opción "Reportar residente" solo se habilita cuando la incidencia está Resuelta | PU-670, PU-681, PU-686, PM-01 |
| CA-2 | No se puede reportar mientras la incidencia esté Pendiente, Asignada o En proceso | PU-670, PU-671, PU-681, PM-01 |
| CA-3 | Solo se puede reportar al residente que registró la incidencia o participó en ella | PU-671, PU-672, PU-679, PU-685, PM-02, PM-03 |
| CA-4 | El reporte queda relacionado con la incidencia resuelta | PU-673, PM-06 |
| CA-5 | Se solicita un motivo elegido de una lista (insultos, groserías, falta de cooperación u otros) | PU-668, PU-678, PU-684, PM-04 |
| CA-6 | El técnico puede describir con detalle lo ocurrido | PU-675, PU-678, PU-684, PM-04 |
| CA-7 | El técnico puede adjuntar evidencias opcionales (fotos, videos o capturas del chat) | PU-676, PU-678, PM-05 |
| CA-8 | El reporte se registra Pendiente de revisión | PU-673, PU-684, PM-06 |
| CA-9 | El envío no cambia el estado de conducta ni bloquea la cuenta del residente | PU-673, PM-08 |
| CA-10 | Solo cuenta como antecedente cuando el administrador lo marca como Validado | PU-673 |
| CA-11 | El administrador recibe una notificación del reporte pendiente de revisión | PU-674, PU-676, PM-07 |
| CA-12 | Como máximo un reporte por usuario contra su contraparte en cada incidencia resuelta | PU-669, PU-671, PU-676, PU-682, PM-09 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/conduct_reports/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. Evidencias en Cloudinary.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnico | Técnico activo con incidencias Asignada, En proceso y Resuelta |
| Residente | El que registró la incidencia Resuelta, con `estadoConducta: bueno` y `estadoCuenta: activa` |
| Otro residente | Residente al que se le asignó la vivienda y que escribió en el chat de la misma incidencia antes de resolverse (para el caso con varios residentes) |
| Administrador | Administrador activo, con sesión en otro dispositivo o navegador |
| Evidencias | Una foto, una captura de pantalla del chat y un video corto en el dispositivo |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/conduct_reports/report_resident_test.dart
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-668 | T 7.2.3 | Motivos disponibles | Insultos, Groserías, Falta de cooperación y Otro motivo, con su valor y su explicación; los motivos para reportar técnicos no cambian |
| PU-669 | T 7.2.6 | Identificador del reporte | `{incidencia}_{técnico}_{residente}`, distinto para cada residente; el de la HU 7.1 sigue igual |
| PU-670 | T 7.2.5 | Condiciones en la app con cada estado, otro técnico, otro rol y cuenta suspendida | Solo se permite con la incidencia Resuelta que atendió el técnico en sesión, con la cuenta activa; cada caso tiene su mensaje |
| PU-671 | T 7.2.5, T 7.2.6 | Condiciones en la transacción | Acepta al que la registró y a quien escribió en el chat; rechaza a otro residente, a un usuario que no es residente, el duplicado, estados no resueltos, la reasignación a otro técnico, la incidencia inexistente, la cuenta suspendida y otro rol |
| PU-672 | T 7.2.5 | Residentes que se pueden reportar | El que la registró y los autores residentes del chat, sin repetir, con su participación y "Residente" si no tienen nombre; sin los ya reportados |
| PU-673 | T 7.2.7 | Armar el reporte nuevo | Pendiente de revisión, con folio, incidencia, nombres y roles (técnico y residente) y la descripción limpia; no lleva cambios para la cuenta ni la conducta del residente; se lee igual que los de la HU 7.1 |
| PU-674 | T 7.2.8 | Avisos a los administradores | Un aviso por administrador, sin repetir, de tipo `reporte_conducta`, con el residente, su rol, el motivo y el folio de la incidencia |
| PU-675 | T 7.2.4, T 7.2.5 | Caso de uso con otro rol, sin sesión, sin residente, descripción corta y 6 evidencias | No se envía; con datos válidos se envía con el UID del técnico y la descripción limpia |
| PU-676 | T 7.2.4, T 7.2.6, T 7.2.8 | Repositorio al reportar | Revisa que no exista, consulta el chat actual, sube las evidencias a la carpeta del reporte y guarda con los administradores a avisar; el duplicado no sube evidencias; los errores tienen su mensaje |
| PU-677 | T 7.2.5, T 7.2.6 | Consultar a quién reportar y los reportes enviados | Arma la lista con los nombres; sin conexión y otros errores tienen su mensaje |
| PU-678 | T 7.2.2 a T 7.2.4 | Formulario con un residente | Queda elegido; pide el motivo y la descripción; completo se envía con el residente, el motivo y las evidencias |
| PU-679 | T 7.2.2, T 7.2.5 | Formulario con varios residentes | Pide elegir a quién reportar; no acepta a alguien fuera de la lista; se envía con el elegido |
| PU-680 | T 7.2.4 | Doble envío, duplicado y sesión de residente | No se manda otro mientras se envía; los errores se muestran |
| PU-681 | T 7.2.1 | Detalle Asignada, En proceso y Resuelta | La opción solo aparece Resuelta; antes ni siquiera se consulta; con la lista cargada se puede reportar a los dos residentes; no se vuelve a consultar |
| PU-682 | T 7.2.1, T 7.2.6 | Residentes ya reportados | Dejan de ofrecerse; al reportar al último ya no se puede y se explica; el recién enviado se conserva aunque Firestore aún no lo traiga |
| PU-683 | T 7.2.1 | Sin residentes y error al consultar | No se permite reportar y se muestra el motivo |
| PU-684 | T 7.2.2 | Pantalla con un residente | Muestra al residente y la incidencia fijos, los motivos y el aviso de revisión; sin datos marca los errores; completo muestra "Reporte enviado" con el folio, el residente y "Pendiente de revisión" |
| PU-685 | T 7.2.2 | Pantalla con varios residentes | Muestra "¿A quién reportas?" con la participación de cada uno; sin elegir marca el error; se envía con el elegido |
| PU-686 | T 7.2.1 | "Reportar residente" en el detalle | En proceso no aparece; Resuelta abre el formulario; al enviarlo se muestra "Reportaste a …" con el folio y el estado, y la opción desaparece |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Opción solo en Resuelta | Como técnico, abrir el detalle de incidencias Asignada, En proceso y una Resuelta desde el historial | Solo la Resuelta muestra la sección "Conducta del residente" con "Reportar residente" |
| PM-02 | Un residente | En una incidencia cuyo chat solo usó el residente que la registró, tocar "Reportar residente" | Se abre "Reportar residente" con su nombre fijo y el folio de la incidencia |
| PM-03 | Varios residentes | En la incidencia donde escribió el otro residente, tocar "Reportar residente" | Aparece "¿A quién reportas?" con los dos, uno con "Registró la incidencia" y otro con "Participó en el chat" |
| PM-04 | Motivo y descripción | Tocar "Enviar reporte" sin datos; luego elegir un motivo y escribir la descripción | Primero se marcan los errores; al elegir el motivo se ve su explicación |
| PM-05 | Evidencias | Agregar una foto, una captura del chat y un video; quitar una; intentar agregar más de 5 | Se ven las miniaturas y se pueden abrir y quitar; no se aceptan más de 5. También se puede enviar sin evidencias |
| PM-06 | Registro | Enviar el reporte; revisar `reportesConducta` en Firestore | Aparece "Reporte enviado" con el folio `RC-…`, el residente y "Pendiente de revisión". El documento `{incidenciaId}_{tecnicoId}_{residenteId}` tiene la incidencia, `reportanteRol: tecnico`, `reportadoRol: residente`, el motivo, la descripción, las URLs y `estado: pendiente_revision` |
| PM-07 | Aviso al administrador | Revisar "Avisos" del administrador | Llega "Nuevo reporte de conducta" con el nombre del residente, "(Residente)", el motivo y el folio de la incidencia |
| PM-08 | Residente sin cambios | Revisar el documento del residente en `usuarios` antes y después del reporte; iniciar sesión como el residente | `estadoConducta`, `reportesValidados` y `estadoCuenta` no cambian; el residente entra normalmente |
| PM-09 | Duplicado | Volver al detalle de la incidencia; intentar reportar otra vez al mismo residente desde otro dispositivo con el formulario ya abierto | El detalle muestra "Reportaste a …" y ya no ofrece a ese residente; el segundo envío se rechaza con "Ya enviaste un reporte de conducta contra este residente para esta incidencia." |
| PM-10 | Sin conexión | Desactivar la conexión y enviar | Se avisa que no hay conexión y lo escrito se conserva |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 21/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 7.2 (PU-668 a PU-686) | 19 | Aprobadas |
| HU 7.1 (PU-648 a PU-667) | 20 | Aprobadas |
| Proyecto completo (`flutter test`) | 392 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-02 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-03 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-04 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-05 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | No se adjuntan los videos que pasen de 50mb |
| PM-06 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-07 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-08 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-09 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-10 | Aprobada | 22/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
