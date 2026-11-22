# Plan de pruebas — HU 7.1 Reportar la conducta de un técnico

| Dato | Valor |
|---|---|
| Módulo | 7. Reportes de conducta |
| Historia de usuario | HU 7.1 Reportar la conducta de un técnico (#313) |
| Tarea | T 7.1.9 Probar el reporte de conducta del técnico (#322) |
| Rama | `feature/HU-7.1-Reportar-la-conducta-de-un-tecnico` |
| Fecha | 21/11/2026 |

## 1. Objetivo

Verificar que el residente pueda reportar la conducta del técnico que atendió su incidencia, solo cuando la incidencia esté Resuelta. El reporte debe tener un motivo de la lista, una descripción y evidencias opcionales. Debe registrarse con un identificador único y el estado Pendiente de revisión, y cada administrador debe recibir un aviso. El reporte no debe cambiar la cuenta del técnico, y el residente solo puede enviar uno por incidencia.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 7.1.1 | Sección "Conducta del técnico" con el botón "Reportar técnico" en el detalle de la incidencia del residente, solo cuando está Resuelta y tuvo técnico; si ya se reportó, muestra el reporte en lugar del botón |
| T 7.1.2 | Pantalla "Reportar técnico": técnico e incidencia de solo lectura, motivo, descripción, evidencias, aviso de revisión y confirmación con el folio |
| T 7.1.3 | Motivos: Retraso, Mala actitud, Trabajo mal realizado, Lenguaje inapropiado y Otro motivo, cada uno con su explicación |
| T 7.1.4 | Descripción obligatoria (10 a 500 caracteres) y hasta 5 evidencias opcionales (fotos o capturas de hasta 10 MB y videos de hasta 50 MB y 1 minuto), subidas a `fixo/reportesConducta/{id}` |
| T 7.1.5 | Condiciones: residente con la cuenta activa, incidencia de su vivienda, en estado Resuelta, y el técnico reportado es el que la atendió. Se revisan en la app y de nuevo en la transacción con los datos actuales |
| T 7.1.6 | Un reporte por residente e incidencia: el documento se llama `{incidenciaId}_{residenteId}`. Se revisa antes de subir las evidencias y otra vez en la transacción |
| T 7.1.7 | Documento `reportesConducta/{id}` con folio consecutivo (`RC-0001`, contador `contadores/reportesConducta`), incidencia relacionada, reportante, reportado, motivo, descripción, evidencias, estado `pendiente_revision` y fecha del servidor |
| T 7.1.8 | Aviso "Nuevo reporte de conducta" a cada administrador activo, guardado en la misma transacción que el reporte |

**No incluye**

- La consulta, validación o rechazo de los reportes por el administrador (HU 7.3), ni el estado de conducta y las sanciones (HU 7.4). Al tocar el aviso del reporte todavía no se abre ninguna pantalla.
- El reporte del técnico contra el residente (HU 7.2).
- Reglas de seguridad de Firestore (entorno de desarrollo): las reglas actuales permiten leer y escribir a cualquier usuario con sesión, así que la restricción se hace en la app.

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | La opción "Reportar técnico" solo se habilita cuando la incidencia está Resuelta | PU-651, PU-662, PU-667, PM-01 |
| CA-2 | No se puede reportar mientras la incidencia esté Pendiente, Asignada o En proceso | PU-651, PU-652, PU-662, PM-01 |
| CA-3 | Solo se puede reportar al técnico que atendió la incidencia | PU-651, PU-652, PU-665, PM-02 |
| CA-4 | El reporte queda relacionado con la incidencia resuelta | PU-649, PU-653, PM-05 |
| CA-5 | Se solicita un motivo, elegido de una lista | PU-648, PU-659, PU-665, PM-03 |
| CA-6 | El residente puede describir lo ocurrido | PU-650, PU-659, PU-665, PM-03 |
| CA-7 | El residente puede adjuntar evidencias opcionales (fotos, videos o capturas del chat) | PU-656, PU-660, PM-04 |
| CA-8 | Al enviarlo se genera un identificador único | PU-649, PU-653, PU-665, PM-05 |
| CA-9 | El administrador recibe una notificación del reporte nuevo | PU-654, PU-656, PM-06 |
| CA-10 | El reporte se registra Pendiente de revisión | PU-653, PU-665, PM-05 |
| CA-11 | El envío no cambia el estado de conducta ni la cuenta del técnico | PU-653, PM-07 |
| CA-12 | Solo cuenta como antecedente cuando el administrador lo valida | PU-649, PU-653 |
| CA-13 | Como máximo un reporte por usuario e incidencia resuelta | PU-652, PU-657, PU-663, PM-08 |

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
| Residente | Residente activo de una vivienda |
| Incidencias | Del mismo residente: una Resuelta con técnico, y otras Pendiente, Asignada y En proceso |
| Técnico | El técnico que resolvió la incidencia, con `estadoConducta: bueno` y `estadoCuenta: activa` |
| Administrador | Administrador activo, con sesión en otro dispositivo o navegador |
| Evidencias | Una foto, una captura de pantalla del chat y un video corto en el dispositivo |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/conduct_reports/
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-648 | T 7.1.3 | Motivos disponibles | Retraso, Mala actitud, Trabajo mal realizado, Lenguaje inapropiado y Otro motivo, cada uno con su valor y su explicación |
| PU-649 | T 7.1.7 | Leer y crear documentos de reportes | Se guardan y leen todos los campos; el folio se muestra como "RC-0003"; sin fecha la pone el servidor; motivo, estado o rol inválidos se rechazan; solo uno Validado cuenta como antecedente; el ID es `{incidencia}_{residente}` |
| PU-650 | T 7.1.4 | Descripción vacía, corta, de 500 y de 501 caracteres | Se pide "Describe lo que ocurrió", al menos 10 caracteres y máximo 500; los espacios de los extremos no cuentan |
| PU-651 | T 7.1.5 | Condiciones en la app con cada estado, otra vivienda, sin técnico, otro rol, cuenta suspendida y otro técnico | Solo se permite con la incidencia Resuelta de su vivienda, con técnico, siendo residente activo y contra el técnico que la atendió; cada caso tiene su mensaje |
| PU-652 | T 7.1.5, T 7.1.6 | Condiciones en la transacción con los datos actuales | Rechaza el duplicado, otro técnico, estados no resueltos, sin técnico, incidencia inexistente, cambio de vivienda, cuenta suspendida y otro rol |
| PU-653 | T 7.1.7 | Armar el reporte nuevo | Pendiente de revisión, con el folio, la incidencia, los nombres y roles y la descripción sin espacios en los extremos; no lleva cambios para la cuenta ni la conducta del técnico |
| PU-654 | T 7.1.8 | Avisos a los administradores | Un aviso por administrador, sin repetir, de tipo `reporte_conducta`, con el técnico, el motivo y el folio de la incidencia, y que apunta al reporte |
| PU-655 | T 7.1.4, T 7.1.5 | Caso de uso con otro rol, sin sesión, cuenta deshabilitada, descripción corta y 6 evidencias | No se envía; con datos válidos se envía con el UID del residente y la descripción limpia |
| PU-656 | T 7.1.4, T 7.1.6, T 7.1.8 | Repositorio con evidencias y sin ellas | Revisa primero que no exista el reporte, sube las evidencias a la carpeta del reporte y guarda las URLs junto con los administradores a avisar |
| PU-657 | T 7.1.6 | Errores del repositorio | Si ya existe no sube las evidencias; un duplicado detectado en la transacción se informa; sin conexión, error de subida, permiso denegado y otros tienen su mensaje |
| PU-658 | T 7.1.6 | Consultar el reporte propio | Escucha el documento `{incidencia}_{residente}`; los errores se traducen a un mensaje |
| PU-659 | T 7.1.2 a T 7.1.4 | Enviar sin motivo, sin descripción y completo | Pide el motivo y la descripción; completo se envía y devuelve el folio |
| PU-660 | T 7.1.4 | Agregar fotos y videos, pesados y de más | Acepta hasta 5; rechaza los pesados con su aviso; al quitar uno se puede volver a agregar; se envían con el reporte |
| PU-661 | T 7.1.4 | Doble envío, reporte duplicado y cuenta suspendida | Mientras se envía no se manda otro ni se agregan evidencias; los errores se muestran |
| PU-662 | T 7.1.1 | Detalle Pendiente, Asignada, En proceso, Rechazada y Resuelta | La opción solo aparece Resuelta y con técnico; antes ni siquiera se consulta el reporte; lleva al técnico que la atendió |
| PU-663 | T 7.1.1, T 7.1.6 | Detalle con el reporte ya enviado | Se muestra el reporte y la opción ya no está disponible, también justo después de enviarlo |
| PU-664 | T 7.1.5 | Error al consultar y cuenta no activa | No se permite reportar y se muestra el motivo |
| PU-665 | T 7.1.2 | Pantalla del formulario | Muestra el técnico y la incidencia fijos, los motivos y el aviso de revisión; sin datos marca los errores; completo muestra "Reporte enviado" con "RC-0003" y "Pendiente de revisión" y regresa al detalle |
| PU-666 | T 7.1.2 | Envío fallido | Se muestra el motivo y se conserva lo escrito |
| PU-667 | T 7.1.1 | "Reportar técnico" en el detalle | En proceso no aparece; Resuelta abre el formulario del técnico que la atendió; al enviarlo, se cambia por "Ya reportaste al técnico" con el folio y el estado |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Opción solo en Resuelta | Como residente, abrir el detalle de incidencias Pendiente, Asignada, En proceso y Resuelta | Solo la Resuelta muestra la sección "Conducta del técnico" con "Reportar técnico" |
| PM-02 | Técnico fijo | Tocar "Reportar técnico" | Se abre "Reportar técnico" con el nombre del técnico que atendió la incidencia y su folio, sin forma de elegir otro |
| PM-03 | Motivo y descripción | Tocar "Enviar reporte" sin datos; luego elegir un motivo y escribir la descripción | Primero se marcan los errores del motivo y la descripción; al elegir el motivo se ve su explicación |
| PM-04 | Evidencias | Agregar una foto con la cámara, una captura del chat desde la galería y un video; quitar una; intentar agregar más de 5 | Se ven las miniaturas y se pueden abrir y quitar; no se aceptan más de 5. También se puede enviar sin evidencias |
| PM-05 | Registro | Enviar el reporte; revisar `reportesConducta` en Firestore | Aparece "Reporte enviado" con el folio `RC-…` y "Pendiente de revisión". El documento `{incidenciaId}_{residenteId}` tiene la incidencia, ambos usuarios, el motivo, la descripción, las URLs de las evidencias, `estado: pendiente_revision` y la fecha |
| PM-06 | Aviso al administrador | Revisar "Avisos" del administrador | Llega "Nuevo reporte de conducta" con el nombre del técnico, el motivo y el folio de la incidencia |
| PM-07 | Técnico sin cambios | Revisar el documento del técnico en `usuarios` antes y después del reporte | `estadoConducta`, `reportesValidados` y `estadoCuenta` no cambian; el técnico sigue entrando normalmente |
| PM-08 | Duplicado | Volver al detalle de la incidencia; intentar enviar otro reporte desde otro dispositivo con el formulario ya abierto | El detalle muestra "Ya reportaste al técnico" con el folio y el estado. |
| PM-09 | Sin conexión | Desactivar la conexión y enviar | Se avisa que no hay conexión y lo escrito se conserva |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-09 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 21/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 7.1 (PU-648 a PU-667) | 20 | Aprobadas |
| Proyecto completo (`flutter test`) | 373 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-02 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-03 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-01 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-04 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-05 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-06 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-07 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-08 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-09 | Aprobada | 21/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
