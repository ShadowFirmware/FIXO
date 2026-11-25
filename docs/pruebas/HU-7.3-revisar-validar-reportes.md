# Plan de pruebas — HU 7.3 Revisar y validar reportes de conducta

| Dato | Valor |
|---|---|
| Módulo | 7. Reportes de conducta |
| Historia de usuario | HU 7.3 Revisar y validar reportes de conducta |
| Tarea | T 7.3.2 Diseño de las pruebas para revisar y validar reportes de conducta |
| Rama | `feature/HU-7.3-Revisar-y-validar-reportes-de-conducta` |
| Fecha | 25/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda consultar todos los reportes de conducta registrados por residentes (HU 7.1) y técnicos (HU 7.2), que cada reporte muestre su estado (Pendiente de revisión, Validado o Rechazado) y como mínimo su identificador, quién reportó, a quién, la incidencia relacionada, el motivo, la descripción y la fecha. También, que pueda ver las fotografías, videos y capturas del chat adjuntas, y marcar un reporte pendiente como Validado o Rechazado. La revisión es definitiva: un reporte ya revisado no se puede volver a revisar.

## 2. Alcance

**Incluye**

| Apartado | Qué se prueba |
|---|---|
| Consulta | Sección "Reportes de conducta" en el menú del administrador, con todos los reportes del más reciente al más antiguo; tarjetas en el teléfono y tabla en la web; se actualiza sola cuando llega o se revisa un reporte |
| Datos de la revisión | Datos de la revisión en el documento de `reportesConducta`: `estado`, `fechaRevision`, `revisadoPorId` y `revisadoPorNombre` |
| Detalle y evidencias | Detalle del reporte con identificador, reportado por, usuario reportado, incidencia relacionada, motivo, descripción, fecha y galería de evidencias (fotos y capturas en pantalla completa, videos con reproductor) |
| Estados | Estado de cada reporte con su color, y filtro por estado con el número de reportes de cada uno |
| Validar y rechazar | Validar y Rechazar con confirmación, en una transacción que revisa con los datos actuales que quien revisa sea un administrador activo y que el reporte siga Pendiente de revisión |
| Aviso | Al tocar el aviso "Nuevo reporte de conducta" (HU 6.1) se abre el detalle de ese reporte |

**No incluye**

- El registro de los reportes (HU 7.1 y HU 7.2).
- El contador de reportes validados, el estado de conducta, las suspensiones y el aviso de advertencia al usuario reportado (HU 7.4). Validar un reporte solo cambia su estado; no modifica el perfil del usuario reportado.
- Reglas de seguridad de Firestore (entorno de desarrollo): las reglas actuales permiten leer y escribir a cualquier usuario con sesión, así que la restricción se hace en la app y en la transacción.

La consulta y la revisión viven en el módulo del administrador (`ConductReviewRepository`), separadas del repositorio de las HU 7.1 y 7.2, que no cambió. A la entidad `ConductReport` solo se le agregaron los datos opcionales de la revisión. La prueba PU-632 (HU 6.1) se actualizó porque el aviso del reporte ahora sí abre una pantalla, y la PU-591 incluye la nueva sección del menú.

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | El administrador puede consultar todos los reportes de conducta registrados | PU-692, PU-694, PU-695, PU-701, PU-703, PU-704, PU-709, PM-01, PM-02, PM-12, PM-13 |
| CA-2 | Cada reporte se identifica con su estado: Pendiente de revisión, Validado o Rechazado | PU-687, PU-694, PU-701, PU-702, PM-02, PM-03 |
| CA-3 | Cada reporte muestra identificador, quién reportó, usuario reportado, incidencia relacionada, motivo, descripción y fecha | PU-688, PU-701, PU-705, PU-709, PM-02, PM-04 |
| CA-4 | El administrador puede visualizar las fotografías, videos o capturas del chat, cuando existan | PU-705, PU-708, PM-05, PM-06 |
| CA-5 | El administrador puede marcar un reporte como Validado o Rechazado | PU-689 a PU-691, PU-693, PU-696 a PU-700, PU-706 a PU-708, PM-07 a PM-11 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.5 / Dart 3.13.4
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. Evidencias en Cloudinary.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador A | Administrador activo, con sesión en un navegador |
| Administrador B | Otro administrador activo, con sesión en otro dispositivo (para la revisión simultánea) |
| Reporte de residente | Reporte levantado con la HU 7.1 contra un técnico, con una foto, un video y una captura del chat |
| Reporte de técnico | Reporte levantado con la HU 7.2 contra un residente, sin evidencias |
| Reportes revisados | Al menos un reporte Validado y uno Rechazado (se pueden obtener con los casos PM-07 y PM-08) |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/conduct_review_test.dart test/unitarias/admin/conduct_review_screen_test.dart
```

### 7.1 Datos, reglas y ViewModel — `conduct_review_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-687 | Estados de revisión | `pendiente_revision`, `validado` y `rechazado` con sus etiquetas "Pendiente de revisión", "Validado" y "Rechazado"; solo el primero se puede revisar |
| PU-688 | Leer un reporte revisado y uno pendiente | Lee identificador "RC-0004", incidencia "INC-0007", fecha de revisión y quién lo revisó; los reportes de las HU 7.1 y 7.2 se leen sin revisión; un estado no válido lanza `FormatException` |
| PU-689 | Administrador activo con reporte pendiente | Se permite validar y rechazar |
| PU-690 | Decisión "pendiente", sin usuario, residente, administrador suspendido, reporte inexistente, ya validado o ya rechazado | No se revisa; cada caso tiene su mensaje |
| PU-691 | Cambios que se guardan | Estado nuevo, fecha del servidor, UID y nombre de quien revisó; ningún otro campo (el perfil del reportado no cambia) |
| PU-692 | Repositorio al consultar | Entrega los reportes; sin conexión: "No se pudieron cargar los reportes de conducta. Inténtalo de nuevo."; sin permiso: mensaje de administrador |
| PU-693 | Repositorio al revisar | Guarda la decisión con el administrador; ya revisado, sin conexión, reporte inexistente y otros errores tienen su mensaje |
| PU-694 | Cargar los reportes | Los tres reportes, del más reciente al más antiguo; un reporte por estado; el filtro Validado deja solo `RC-0002` |
| PU-695 | Error al cargar | Lista vacía y el mensaje de error |
| PU-696 | Validar `RC-0001` | Se guarda Validado con el UID del administrador; "Reporte RC-0001 marcado como Validado."; la lista se actualiza |
| PU-697 | Rechazar `RC-0001` | Se guarda Rechazado; "Reporte RC-0001 marcado como Rechazado." |
| PU-698 | Rechazar `RC-0002`, ya validado | No se envía; "Este reporte ya fue revisado…" |
| PU-699 | Otro administrador lo validó y a esta sesión aún no le llega | La transacción lo rechaza y se muestra que ya fue revisado |
| PU-700 | Sin conexión al validar; sin sesión | No se guarda, el reporte sigue pendiente y se muestra el mensaje |

### 7.2 Pantalla — `conduct_review_screen_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-701 | Abrir el menú y ver la lista en el teléfono | "Reportes de conducta" aparece marcada en el menú; la tarjeta de `RC-0001` muestra estado, motivo, "Reportó: María López Hernández (Residente)", "Reportado: Juan Pérez Ramírez (Técnico)", "INC-0007 · Fuga en baño", la fecha, "3 evidencias", Validar y Rechazar; los revisados no tienen botones |
| PU-702 | Filtros | "Todos (3)", "Pendiente de revisión (1)", "Validado (1)" y "Rechazado (1)"; Rechazado deja solo `RC-0003` |
| PU-703 | Filtro sin reportes; sin reportes registrados | "No hay reportes de conducta con estado Validado" y "No hay reportes de conducta registrados" |
| PU-704 | Error al cargar | Indicador de carga y después el mensaje de error |
| PU-705 | Tocar `RC-0001` | Detalle con identificador, reportado por, usuario reportado, incidencia relacionada, motivo, descripción y fecha; galería con la foto, el video y la captura; Rechazar y Validar |
| PU-706 | Validar desde el detalle | Pide confirmación avisando que contará como antecedente; al confirmar muestra el mensaje, la tarjeta pasa a Validado sin botones y el filtro dice "Validado (2)" |
| PU-707 | Rechazar desde la tarjeta: cancelar y luego confirmar | Al cancelar no cambia nada; al confirmar se guarda Rechazado y se muestra el mensaje |
| PU-708 | Detalle de `RC-0002`, ya validado | Muestra la fecha de revisión, "Revisado por: Ana Admin" y "No se adjuntaron evidencias."; solo ofrece Cerrar |
| PU-709 | Vista web | Tabla con Identificador, Estado, Reportó, Reportado, Incidencia, Motivo, Descripción, Evidencias, Fecha y Opciones; Validar y Rechazar solo en el pendiente, Ver en los revisados |
| PU-710 | Abrir la pantalla desde el aviso de `RC-0003` | Se abre su detalle; al cerrarlo queda la lista |
| PU-711 | Aviso de un reporte que ya no existe | "El reporte de conducta ya no existe." |
| PU-632 | Destino de cada aviso (HU 6.1, actualizada) | Para el administrador, el aviso `reporte_conducta` abre "Reportes de conducta" con el ID del reporte |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso | Como administrador A, abrir el menú (teléfono) o la barra lateral (web) y elegir "Reportes de conducta" | Se abre la pantalla con la sección marcada en el menú |
| PM-02 | Consultar reportes | Revisar la lista con los reportes de prueba | Aparecen todos, del más reciente al más antiguo, con su estado en color, identificador `RC-…`, motivo, quién reportó y a quién (con su rol), la incidencia, la fecha y el número de evidencias. En la web se ven como tabla |
| PM-03 | Filtrar por estado | Tocar cada filtro | Cada uno deja solo los reportes de ese estado y su número coincide |
| PM-04 | Ver detalle | Tocar el reporte del residente | Se muestran identificador, reportado por, usuario reportado, incidencia relacionada, motivo, descripción y fecha, igual que en `reportesConducta` |
| PM-05 | Ver evidencias | En el detalle, tocar la foto, la captura del chat y el video | La foto y la captura se abren en pantalla completa y se pueden acercar; el video se reproduce y se pausa al tocarlo |
| PM-06 | Sin evidencias | Abrir el detalle del reporte del técnico | Se muestra "No se adjuntaron evidencias." |
| PM-07 | Validar | En un reporte pendiente tocar "Validar" y confirmar; revisar el documento en Firestore | Aparece "Reporte RC-… marcado como Validado.", el reporte pasa a Validado y ya no ofrece Validar ni Rechazar. El documento tiene `estado: validado`, `fechaRevision`, `revisadoPorId` y `revisadoPorNombre` |
| PM-08 | Rechazar | En otro reporte pendiente tocar "Rechazar" y confirmar | Aparece "Reporte RC-… marcado como Rechazado." y el reporte pasa a Rechazado |
| PM-09 | Cancelar | Tocar "Validar" y luego "Cancelar" | El reporte sigue Pendiente de revisión |
| PM-10 | Revisado | Abrir el detalle de un reporte ya revisado | Muestra la fecha de revisión y quién lo revisó; solo ofrece "Cerrar" |
| PM-11 | Revisión simultánea | Con el mismo reporte pendiente abierto en los administradores A y B, validarlo en A y, sin que B reciba el cambio (por ejemplo, con el detalle ya abierto), rechazarlo en B | B muestra "Este reporte ya fue revisado…" y el reporte queda Validado. En la lista de B el estado se actualiza solo |
| PM-12 | Reporte nuevo y aviso | Con la pantalla abierta, levantar un reporte nuevo con la HU 7.1; luego tocar el aviso "Nuevo reporte de conducta" en "Avisos" | El reporte aparece en la lista sin recargar; el aviso abre la pantalla con el detalle de ese reporte |
| PM-13 | Sin conexión | Desactivar la conexión e intentar validar un reporte | Se avisa "No hay conexión a internet. La revisión no se guardó." y el reporte sigue pendiente |
| PM-14 | Usuario reportado sin cambios | Revisar el documento del usuario reportado en `usuarios` antes y después de validar | `estadoConducta`, `reportesValidados` y `estadoCuenta` no cambian (corresponden a la HU 7.4) |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-14 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 25/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 7.3 (PU-687 a PU-711) | 25 | Aprobadas |
| HU 6.1 y navegación del administrador (PU-632 y PU-591, actualizadas) | 2 | Aprobadas |
| Proyecto completo (`flutter test`) | 417 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Pendiente | | | |
| PM-02 | Pendiente | | | |
| PM-03 | Pendiente | | | |
| PM-04 | Pendiente | | | |
| PM-05 | Pendiente | | | |
| PM-06 | Pendiente | | | |
| PM-07 | Pendiente | | | |
| PM-08 | Pendiente | | | |
| PM-09 | Pendiente | | | |
| PM-10 | Pendiente | | | |
| PM-11 | Pendiente | | | |
| PM-12 | Pendiente | | | |
| PM-13 | Pendiente | | | |
| PM-14 | Pendiente | | | |
