---
| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.8 Consultar incidencias pendientes de asignación |
| Rama | `feature/HU-4.8-Consultar-incidencias-pendientes-de-asignacion` |
| Fecha | 02/11/2026 |
---

# Plan de pruebas — HU 4.8 Consultar incidencias pendientes de asignación

## 1. Objetivo

Verificar que el administrador pueda consultar las incidencias en estado "Pendiente" desde la opción "Reportes pendientes" del menú de hamburguesa y desde el inicio. Se prueba que cada incidencia muestre sus datos completos, que se ordenen de la más antigua a la más reciente, que se puedan filtrar por tipo, que la información corresponda a lo guardado en Firestore y que una incidencia desaparezca de la lista en cuanto deja de estar pendiente (al asignarla o rechazarla).

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Reportes pendientes" en el menú de hamburguesa de todas las pantallas del administrador |
| Inicio | Las 3 incidencias pendientes más antiguas y el botón "Ver más" |
| Consulta | Tabla (PC) o tarjetas (teléfono) con número de reporte, nombre, tipo, detalles, evidencias, departamento, usuario que reportó y fecha de creación |
| Orden | De la más antigua a la más reciente; a igual fecha, por número de reporte |
| Filtro | Filtro por tipo: Todos, Luz, Agua, Estructura y Otros |
| Detalle | Modal con todos los datos y las evidencias (fotos y videos) |
| Tiempo real | La lista se actualiza sola y solo conserva las incidencias en estado "Pendiente" |
| Opciones | Botones "Asignar" y "Rechazar" que sacan la incidencia de la lista |

**No incluye**

- Las reglas completas de la asignación (HU 4.9) y del rechazo (HU 4.10): aquí solo se verifica que existan las opciones y que la incidencia salga de la lista al cambiar de estado. Las notificaciones al residente y al técnico se prueban en esas historias.
- El apartado de incidencias con otros estados (HU 4.11 Consultar historial de incidencias).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.8 | Pruebas |
|---|---|---|
| CA-1 | Mostrar las incidencias que se encuentran en estado "Pendiente" | PU-416, PU-419, PM-02, PM-03, PM-14, PM-15 |
| CA-2 | Cada incidencia muestra número de reporte, nombre, tipo, detalles, evidencias, departamento, usuario que la reportó y fecha de creación | PU-428, PU-435, PM-04, PM-05, PM-06 |
| CA-3 | Ordenar por fecha de creación, mostrando primero las más antiguas | PU-417, PU-426, PU-427, PM-07, PM-10 |
| CA-4 | Filtrar las incidencias por tipo | PU-418, PU-436, PM-08, PM-09 |
| CA-5 | La información corresponde a los registros almacenados en el sistema | PU-416, PU-428, PU-429, PM-06, PM-13 |
| CA-6 | Al cambiar de estado (asignada o rechazada) la incidencia desaparece del apartado | PU-419, PU-421 a PU-425, PU-437, PM-14, PM-15, PM-16 |
| CA-7 | Acceso desde el menú de hamburguesa ("Reportes pendientes") | PM-01 |
| CA-8 | El inicio muestra 3 incidencias y el botón "Ver más" lleva al apartado | PU-417, PU-433, PU-434, PM-10, PM-11, PM-12 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

`FakeIncidentAdminRepository.controller` y `FakeIncidentAdminRemoteDataSource.controller` (en `pending_incidents_fakes.dart`) simulan los cambios que Firestore envía en tiempo real.

## 5. Entorno

- Flutter 3.47.5 / Dart 3.13.4
- Android (emulador o dispositivo físico) y escritorio/web para la vista de tabla
- Firebase: proyecto `fixo-a7763`, Firestore con reglas de desarrollo
- La consulta usa solo `where('estado', == 'pendiente')` y se ordena en la app, así que no requiere índices compuestos.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario con rol `admin` y estado `activa` |
| Residente | Residente activo con vivienda asignada (por ejemplo "Torre A – 4B") |
| Técnico disponible | Técnico con estado `activa` y `disponible` = `true` |
| Incidencias pendientes | Al menos 4 en estado `pendiente`, creadas en días distintos y de tipos distintos (Luz, Agua, Estructura). Una con evidencias (foto y video) y otra sin evidencias |
| Incidencia con otro estado | Una incidencia en estado `asignada` y otra en `rechazada` |

Las incidencias se registran como residente (HU 2.3) o se editan en la consola de Firestore cambiando el campo `estado`.

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/pending_incidents_view_model_test.dart test/unitarias/admin/incident_admin_repository_impl_test.dart test/unitarias/admin/admin_pending_incidents_screen_test.dart
```

### 7.1 ViewModel — `pending_incidents_view_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-416 | Llegan 4 incidencias pendientes de Firestore | Deja de cargar y muestra las 4 en el orden recibido |
| PU-417 | Lista para el inicio | Solo las 3 más antiguas (1, 2 y 3) y `hasMore` verdadero |
| PU-418 | Filtrar por Agua, por Otros y quitar el filtro | Solo las de agua (1 y 3); ninguna; vuelven las 4 |
| PU-419 | Firestore deja de enviar una incidencia (cambió de estado) | Desaparece de la lista sin recargar |
| PU-420 | Falla la conexión | Se muestra "No hay conexión a internet. Revisa tu conexión e inténtalo de nuevo." |
| PU-421 | Rechazar con comentario vacío o solo espacios | "Escribe el motivo del rechazo" y no se llama al repositorio |
| PU-422 | Rechazar con comentario | Se llama al repositorio y se muestra "Incidencia INC-0001 rechazada." |
| PU-423 | Asignar sin técnico, sin hora o con hora pasada | "Selecciona un técnico", "Selecciona la hora estimada de llegada" y "La hora estimada no puede ser en el pasado" |
| PU-424 | Asignar con técnico y hora futura | Se llama al repositorio y se muestra "Incidencia INC-0001 asignada." |
| PU-425 | Asignar una incidencia que otro administrador ya atendió | Se muestra el aviso de que la incidencia ya no está pendiente |

### 7.2 Repositorio — `incident_admin_repository_impl_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-426 | Incidencias desordenadas y una sin fecha | Quedan 1, 2, 3 y al final la que no tiene fecha |
| PU-427 | Dos incidencias con la misma fecha | Se ordenan por número de reporte |
| PU-428 | Vivienda y residente existentes; y otros que no existen | "Torre A – 4B" y "Ana López"; los que no existen muestran "Sin registrar" |
| PU-429 | Dos actualizaciones con el mismo residente | El nombre se lee de Firestore una sola vez |
| PU-430 | Firestore responde `unavailable` | Se traduce a `IncidentFailure.offline` |
| PU-431 | La incidencia ya no está pendiente / el técnico ya no está disponible | Se traducen a `IncidentFailure.notPending` y `IncidentFailure.technicianUnavailable` |
| PU-432 | Rechazar con espacios al inicio y al final | Se guarda "No procede" sin espacios extra |

### 7.3 Pantallas — `admin_pending_incidents_screen_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-433 | Inicio con 4 pendientes; pulsar "Ver más" | Se ven las incidencias 1 a 3, no la 4; "Ver más" abre la ruta de reportes pendientes |
| PU-434 | Inicio sin pendientes | "No hay reportes por el momento" |
| PU-435 | Tabla en PC | Columnas No. reporte, Nombre, Tipo, Detalles, Evidencias, Departamento, Reportó, Fecha de creación y Opciones; "INC-0001", "1 (ver)", "1 de octubre de 2026, 9:30 a. m.", departamento, residente y botones Asignar y Rechazar en cada fila |
| PU-436 | Filtro Luz y filtro Otros | Solo "INC-0002"; luego "No hay incidencias pendientes de tipo Otros" |
| PU-437 | Rechazar sin motivo, con motivo y confirmar | Primero "Escribe el motivo del rechazo"; luego "Confirmar rechazo"; al confirmar se rechaza y aparece "Incidencia INC-0001 rechazada." |
| PU-438 | Asignar sin técnicos disponibles | "No hay técnicos disponibles en este momento." |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso desde el menú | Iniciar sesión como administrador, abrir el menú de hamburguesa y pulsar "Reportes pendientes". Repetir desde Residentes, Técnicos y Residencias | Se abre la pantalla "Reportes pendientes" desde cualquier apartado |
| PM-02 | Solo pendientes | Abrir "Reportes pendientes" con los datos de prueba | Aparecen solo las incidencias en estado "Pendiente"; no aparecen la asignada ni la rechazada |
| PM-03 | Lista vacía | Abrir el apartado sin incidencias pendientes | Se muestra "No hay incidencias pendientes de asignación" |
| PM-04 | Datos en la tabla (PC) | Abrir el apartado en escritorio | Cada fila muestra número de reporte, nombre, tipo, detalles, evidencias, departamento, usuario que reportó, fecha de creación y las opciones Asignar y Rechazar |
| PM-05 | Datos en tarjetas (teléfono) | Abrir el apartado en un teléfono | Cada tarjeta muestra nombre, número, tipo, detalles, departamento, residente, fecha, número de evidencias y los botones Asignar y Rechazar |
| PM-06 | Ver detalle y evidencias | Tocar una incidencia con evidencias | Se abre el modal con todos sus datos; al tocar una foto o video se abre en pantalla completa. En una sin evidencias se muestra "No se adjuntaron evidencias." |
| PM-07 | Orden | Revisar el orden de la lista | La incidencia más antigua aparece primero y la más reciente al final |
| PM-08 | Filtrar por tipo | Pulsar "Luz", luego "Agua" y luego "Todos" | La lista solo muestra las del tipo elegido; con "Todos" vuelven todas |
| PM-09 | Filtro sin resultados | Pulsar un tipo sin incidencias pendientes (por ejemplo "Otros") | Se muestra "No hay incidencias pendientes de tipo Otros" |
| PM-10 | Inicio con 3 incidencias | Iniciar sesión como administrador con 4 o más pendientes | El inicio muestra el total de pendientes y solo las 3 más antiguas |
| PM-11 | Botón "Ver más" | En el inicio, bajar hasta el final y pulsar "Ver más" | Se abre "Reportes pendientes" con la lista completa |
| PM-12 | Inicio sin pendientes | Iniciar sesión sin incidencias pendientes | Se muestra "No hay reportes por el momento" |
| PM-13 | Corresponde a Firestore | Comparar una incidencia de la lista con su documento en la consola de Firestore | Folio, nombre, tipo, detalles, vivienda, residente, fecha y número de evidencias coinciden |
| PM-14 | Nueva incidencia en tiempo real | Con el apartado abierto, registrar una incidencia como residente | Aparece al final de la lista sin recargar |
| PM-15 | Cambio de estado en tiempo real | Con el apartado abierto, cambiar el `estado` de una incidencia a `asignada` o `rechazada` en Firestore | Desaparece de la lista y del inicio sin recargar |
| PM-16 | Opciones Asignar y Rechazar | Asignar una incidencia a un técnico disponible con hora estimada; rechazar otra con un motivo y confirmar | Se muestra el mensaje de éxito y ambas desaparecen del apartado. Rechazar sin motivo muestra "Escribe el motivo del rechazo" |
| PM-17 | Modales | Abrir los modales de Asignar, Rechazar y su confirmación | Los botones Cancelar y la acción tienen el mismo tamaño |
| PM-18 | Sin conexión | Desactivar internet y abrir el apartado | Se muestra un mensaje de error de conexión en lugar de la lista |
| PM-19 | Acceso por rol | Iniciar sesión como residente o técnico e intentar abrir la ruta `/admin/incidents/pending` | Se redirige a su propio inicio |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-19 se cumplen.
- Solo se muestran incidencias en estado "Pendiente", ordenadas de la más antigua a la más reciente.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 02/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.8 (PU-416 a PU-438) | 23 | Aprobadas |
| Proyecto completo (`flutter test test/unitarias`) | 141 | Aprobadas |

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
| PM-15 | Pendiente | | | |
| PM-16 | Pendiente | | | |
| PM-17 | Pendiente | | | |
| PM-18 | Pendiente | | | |
| PM-19 | Pendiente | | | |
