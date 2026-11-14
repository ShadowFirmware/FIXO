# Plan de pruebas — HU 6.1 Recibir notificaciones sobre incidencias y reportes de conducta

| Dato | Valor |
|---|---|
| Módulo | 6. Notificaciones |
| Historia de usuario | HU 6.1 Recibir notificaciones sobre incidencias y reportes de conducta (#295) |
| Tarea | T 6.1.15 Probar el funcionamiento de las notificaciones (#310) |
| Rama | `feature/HU-6.1-Recibir-notificaciones-sobre-incidencias-y-reportes-de-conducta` |
| Fecha | 14/11/2026 |

## 1. Objetivo

Verificar que cada usuario reciba los avisos de las incidencias y de los reportes de conducta que le corresponden, que pueda consultarlos y abrirlos, y que nunca reciba ni vea avisos de otra persona.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 6.1.1 | Estructura de `notificaciones`: `usuarioId`, `tipo`, `titulo`, `mensaje`, `refId`, `leida` y `fecha` del servidor; tipos de aviso |
| T 6.1.2 | Servicio de avisos: todos se arman con `NotificationModel.newNotice` y se guardan en la misma transacción o lote que el cambio que los provoca |
| T 6.1.3 | Pestaña "Avisos" del residente y del técnico, y sección "Avisos" del administrador |
| T 6.1.4 | Consulta en tiempo real, del más reciente al más antiguo; marcar como leído al abrir y "Marcar todo como leído"; número de avisos sin leer en la barra; abrir la pantalla que corresponde |
| T 6.1.5 | Aviso a los administradores activos de una incidencia nueva, con su tipo |
| T 6.1.6 | Aviso de asignación al residente (con el técnico y la hora estimada) y al técnico (con el folio) |
| T 6.1.7 | Avisos de atención y de resolución |
| T 6.1.8 | Aviso de rechazo con el motivo |
| T 6.1.9 a T 6.1.13 | Avisos de reporte de conducta, advertencia, suspensión (con su duración), reactivación y deshabilitación indefinida |
| T 6.1.14 | Destinatarios: el residente que registró la incidencia y el residente activo de la vivienda, sin repetir y sin cuentas dadas de baja; cada usuario solo ve sus avisos |
| Permisos del teléfono | La primera vez que el usuario entra se explica para qué sirven las notificaciones y se pide el permiso, sin volver a insistir; en Avisos se ofrece activarlas, o se abren los ajustes si el sistema ya no pregunta. Mientras la app está abierta o en segundo plano, cada aviso nuevo aparece como notificación del teléfono y al tocarla se abre. La cámara pide permiso la primera vez que se usa para las evidencias |

**No incluye**

- El registro, la validación y las sanciones de los reportes de conducta (HU 7.x). Los avisos de T 6.1.9 a T 6.1.13 quedan listos en `NotificationNotices` para que esa HU solo los guarde. Lo único que ya se dispara es la reactivación al terminar una suspensión temporal, que se detecta al iniciar sesión.
- Notificaciones con la app cerrada (push con Firebase Cloud Messaging): el plan Spark no incluye Cloud Functions para enviarlas. Con la app cerrada, los avisos se ven al abrirla.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 6.1 | Pruebas |
|---|---|---|
| CA-1 | El residente que registró la incidencia, o el residente activo del departamento, recibe una notificación cuando su incidencia es asignada a un técnico | PU-623, PU-624, PM-02 |
| CA-2 | El residente recibe información de la atención, con el nombre del técnico y la hora estimada de llegada | PU-623, PM-02 |
| CA-3 | El residente correspondiente recibe una notificación cuando su incidencia es marcada como Resuelta | PU-623, PU-624, PM-03 |
| CA-4 | El técnico recibe una notificación cuando se le asigna una nueva incidencia, identificando el reporte | PU-623, PM-02 |
| CA-5 | El administrador recibe una notificación cuando se registra una nueva incidencia pendiente de asignación | PU-623, PU-637, PM-01 |
| CA-6 | El administrador recibe una notificación cuando se genera un reporte de conducta contra un residente o técnico | PU-625 |
| CA-7 | Cuando un reporte de conducta es validado, el usuario reportado recibe una advertencia | PU-626 |
| CA-8 | Cuando una cuenta es suspendida, la notificación indica la duración de la suspensión | PU-627 |
| CA-9 | Cuando finaliza una suspensión temporal, el usuario recibe una notificación de que su cuenta fue reactivada | PU-628, PU-629, PM-06 |
| CA-10 | Cuando se valida el quinto reporte, el usuario recibe una notificación de deshabilitación indefinida | PU-626 |
| CA-11 | Si el administrador reactiva una cuenta deshabilitada indefinidamente, el usuario recibe una notificación de reactivación | PU-628 |
| CA-12 | El residente recibe una notificación cuando su incidencia es rechazada, con el comentario del motivo | PU-623, PM-04 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/notifications/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente | Residente activo de una vivienda |
| Técnico | Técnico activo y Disponible |
| Administrador | Administrador activo, con sesión en otro dispositivo o navegador |
| Cambio de residente | Una incidencia registrada por un residente cuya vivienda después se asignó a otro |
| Suspensión | Un usuario con `estadoCuenta: suspendida` y `suspendidaHasta` en el pasado |
| Teléfono | Android 13 o más reciente, con FIXO recién instalada (sin permisos concedidos) |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/notifications/
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-619 | T 6.1.1 | Leer documentos válidos, de tipo desconocido e inválidos; crear uno nuevo | Se leen todos los campos; el tipo desconocido se muestra igual; sin destinatario o título se rechaza; el nuevo queda sin leer con la fecha del servidor |
| PU-620 | T 6.1.1 | Tipos de aviso y a qué llevan | Cada tipo tiene su valor; solo los avisos de incidencias llevan a una incidencia |
| PU-621 | T 6.1.4 | Orden de los avisos | Primero los que todavía no tienen fecha, después del más reciente al más antiguo |
| PU-622 | T 6.1.2, T 6.1.4 | Errores de Firestore al consultar y al marcar como leídos | Sin conexión se muestra el aviso de conexión; los demás, un mensaje general; sin avisos por marcar no se escribe nada |
| PU-623 | T 6.1.5 a T 6.1.8 | Avisos de incidencia nueva, asignación (residente y técnico), atención, resolución y rechazo | Cada uno con su tipo, título con el folio y datos clave: tipo de incidencia, técnico y hora estimada, motivo del rechazo |
| PU-624 | T 6.1.14 | Residentes que se avisan y cuentas que pueden recibir avisos | El que registró y el residente activo, sin repetir ni vacíos; las cuentas dadas de baja o inexistentes no reciben; las suspendidas o deshabilitadas sí |
| PU-625 | T 6.1.9 | Reporte de conducta contra un residente y un técnico | Un aviso por administrador, sin repetir, con el nombre, el rol y el motivo recortado |
| PU-626 | T 6.1.10, T 6.1.13 | Validar el tercer y el quinto reporte | Con el tercero, solo la advertencia con la cuenta de reportes; con el quinto, además, la deshabilitación indefinida |
| PU-627 | T 6.1.11 | Suspensión de 7 días y duraciones | El aviso dice "por 7 días, hasta el …"; la duración se redondea hacia arriba en minutos, horas o días |
| PU-628 | T 6.1.12 | Reactivación al terminar la suspensión y por el administrador | Cada caso tiene su mensaje |
| PU-629 | T 6.1.12 | Iniciar sesión con la suspensión vencida, vigente y con la cuenta activa | Con la suspensión vencida entra y la cuenta se reactiva con el aviso; con la vigente no entra; activa no cambia nada |
| PU-630 | T 6.1.4, T 6.1.14 | Consultar los avisos, con error, reintentar y sin sesión | Se muestran solo los del usuario y cuántos no ha leído; el error permite reintentar; sin sesión no se consulta |
| PU-631 | T 6.1.4 | Abrir un aviso, marcar todos y errores | Al abrirlo se marca como leído; "Marcar todo" solo envía los pendientes; si falla, se avisa |
| PU-632 | T 6.1.4 | Pantalla que abre cada aviso según el rol | Residente y técnico abren el detalle de la incidencia; el administrador, los reportes pendientes o el historial; los avisos de cuenta no abren otra pantalla |
| PU-633 | T 6.1.3 | Cuándo llegó cada aviso | "Ahora", "Hace un momento", "Hace 5 min", "Hoy, …", "Ayer, …" o la fecha |
| PU-634 | T 6.1.3, T 6.1.4 | Pantalla de avisos del residente | Muestra los avisos con el punto de los no leídos; al tocar uno se marca y abre la incidencia |
| PU-635 | T 6.1.4 | "Marcar todo como leído" | Se marcan todos, se confirma y desaparecen los puntos y el botón |
| PU-636 | T 6.1.3 | Sin avisos y con error | Mensaje de que no hay avisos; con error, "Reintentar" vuelve a consultar |
| PU-637 | T 6.1.3, T 6.1.5 | Sección "Avisos" del administrador | Muestra el aviso de la incidencia nueva y lleva a los reportes pendientes |
| PU-638 | T 6.1.4 | Número de avisos sin leer en la barra | Muestra el número, "9+" con más de nueve y nada con cero |
| PU-639 | Permisos | Cuándo se pide el permiso de notificaciones y cuándo se ofrece activarlo | Solo la primera vez y si el sistema todavía pregunta; el aviso en Avisos aparece si están desactivadas |
| PU-640 | Permisos | Primer ingreso: "Activar" | Se explica para qué sirven, se pide el permiso del sistema y no se vuelve a preguntar |
| PU-641 | Permisos | Primer ingreso: "Ahora no", permiso ya concedido o sin poder consultarlo | No se pide y no se insiste; sin poder consultarlo, la app sigue igual |
| PU-642 | Permisos | Aviso en Avisos con las notificaciones desactivadas | "Activar" pide el permiso; si el sistema ya no pregunta, abre los ajustes; concedido, el aviso desaparece |
| PU-643 | Permisos | Avisos que llegan con la sesión abierta | Solo se notifican los nuevos, sin leer y del usuario, una sola vez; al cerrar sesión se deja de escuchar |
| PU-644 | Permisos | Tocar la notificación del teléfono | Se marca como leído y se abre la incidencia; la de otra persona se ignora |
| PU-645 | Permisos | Datos que guarda la notificación | Se recupera el aviso para abrirlo; datos inválidos se ignoran |
| PU-646 | Permisos | Abrir la cámara con el permiso concedido, negado o negado para siempre | Se pide antes de abrirla (no para la galería); si se niega, no se abre y se explica cómo activarla |
| PU-647 | Permisos | El técnico niega la cámara al agregar evidencias | No se agrega nada y se muestra el mensaje |

Las pruebas de las HU 3.5, 3.7, 4.9 y 4.10 siguen pasando: el contenido de sus avisos no cambió.

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Incidencia nueva | Registrar una incidencia como residente y revisar "Avisos" del administrador | Llega "Nueva incidencia INC-…" con el tipo; al tocarla abre los reportes pendientes |
| PM-02 | Asignación | Asignar la incidencia a un técnico | El residente recibe el nombre del técnico y la hora estimada; el técnico recibe "Nueva asignación INC-…" |
| PM-03 | Atención y resolución | El técnico comienza la atención y después finaliza la incidencia | El residente y los administradores reciben "en proceso" y "resuelta" |
| PM-04 | Rechazo | Rechazar una incidencia pendiente | El residente recibe el aviso con el motivo |
| PM-05 | Cambio de residente | Con la incidencia de un residente cuya vivienda pasó a otro, asignarla o rechazarla | Reciben el aviso ambos residentes; si el anterior se dio de baja, solo el nuevo |
| PM-06 | Fin de suspensión | Iniciar sesión con la suspensión vencida | Entra; en Firestore la cuenta queda `activa` y aparece el aviso "Cuenta reactivada" |
| PM-07 | Leídos y contador | Revisar la barra, abrir un aviso y usar "Marcar todo como leído" | El número baja al abrir cada aviso y desaparece al marcar todos |
| PM-08 | Privacidad | Revisar los avisos con otra cuenta | Cada usuario solo ve los suyos |
| PM-09 | Permiso al entrar | Instalar FIXO, iniciar sesión y elegir "Activar" (y en otro teléfono "Ahora no") | Aparece la explicación y luego el permiso del sistema; no se vuelve a preguntar; con "Ahora no", en Avisos se ofrece activarlas |
| PM-10 | Notificación del teléfono | Con la app en segundo plano, asignar o rechazar una incidencia del residente | Llega la notificación; al tocarla se abre la incidencia y el aviso queda leído |
| PM-11 | Permiso de la cámara | Agregar una evidencia con la cámara por primera vez; negar y volver a intentar | Se pide el permiso; negado, se explica cómo activarlo y la cámara no se abre |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-11 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 14/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 6.1 (PU-619 a PU-647) | 29 | Aprobadas |
| Proyecto completo (`flutter test`) | 353 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-08 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-09 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-10 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-11 | Aprobada | 14/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
