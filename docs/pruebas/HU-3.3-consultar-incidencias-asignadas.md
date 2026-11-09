# Plan de pruebas — HU 3.3 Consultar incidencias asignadas

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.3 Consultar incidencias asignadas (#197) |
| Tarea | T 3.3.6 Probar la consulta de incidencias asignadas (#220) |
| Rama | `feature/HU-3.3-Consultar-incidencias-asignadas` |
| Fecha | 08/11/2026 |

## 1. Objetivo

Verificar que el técnico vea únicamente las incidencias que le asignaron, en estado Asignada o En proceso, que pueda filtrarlas por estado y consultar la información general de cada una, y que se muestre un mensaje cuando no tenga incidencias asignadas.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.3.1 | Pantalla "Incidencias asignadas" en la pestaña Inicio del técnico, con una tarjeta por incidencia |
| T 3.3.2 | Consulta en Firestore de las incidencias del técnico autenticado; solo un técnico puede consultarlas y solo las suyas |
| T 3.3.3 | Solo los estados Asignada y En proceso; filtro Todas / Asignada / En proceso con cuántas hay de cada una |
| T 3.3.4 | Información de cada incidencia en la lista y en el detalle: tipo, departamento, residente, teléfono, fechas, descripción y evidencias |
| T 3.3.5 | Mensaje cuando no hay incidencias asignadas o ninguna en el estado elegido |

**No incluye**

- El historial del técnico ni el cambio de estado de las incidencias (otras HU).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.3 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede consultar únicamente las incidencias que le han sido asignadas | PU-517, PU-518, PU-520, PU-527, PM-01, PM-02 |
| CA-2 | Se muestran las incidencias en estado Asignada o En proceso | PU-518, PU-521, PU-524, PM-03 |
| CA-3 | Cada incidencia permite consultar su información general | PU-515, PU-524, PU-525, PU-527, PM-04 |
| CA-4 | Las incidencias resueltas dejan de aparecer en la lista de asignadas y pasan al historial | PU-518, PU-522, PM-05 |
| CA-5 | Si el técnico no tiene incidencias asignadas, el sistema muestra un mensaje informativo | PU-522, PU-526, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. La consulta filtra un solo campo (`tecnicoId`), así que no necesita índice compuesto.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnicos | Dos técnicos activos, cada uno con incidencias asignadas |
| Incidencias | Del técnico de prueba: dos asignadas (una con hora estimada), una en proceso y una resuelta; otra asignada a un técnico distinto |
| Otros usuarios | Un residente y un administrador, para comprobar que no pueden abrir la pantalla |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/assigned_incidents_data_test.dart test/unitarias/technician/assigned_incidents_test.dart
```

### 7.1 Datos, permisos y orden — `assigned_incidents_data_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-515 | T 3.3.2, T 3.3.4 | Incidencias con vivienda y residente existentes y sin registrar | Llegan con el departamento, el nombre y el teléfono, o "Sin registrar"; cada vivienda y residente se consulta una sola vez |
| PU-516 | T 3.3.2 | Errores de Firestore en la lista y en el detalle | Mensajes de sin conexión, sin permiso y error de carga; una incidencia que no existe llega como vacía |
| PU-517 | T 3.3.2 | Consulta de un residente o sin sesión | Se niega el acceso y no se consulta Firestore |
| PU-518 | T 3.3.2, T 3.3.3 | Incidencias en los cinco estados y de otro técnico | Solo quedan las del técnico en estado Asignada o En proceso |
| PU-519 | T 3.3.3 | Incidencias con y sin hora estimada | Primero la llegada más próxima; las que no tienen hora van al final, por folio |
| PU-520 | T 3.3.4 | Detalle de una incidencia propia, inexistente y de otro técnico; detalle pedido por un administrador | Se muestra la propia; la de otro técnico y la del administrador se niegan |

### 7.2 ViewModel y pantallas — `assigned_incidents_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-521 | T 3.3.2, T 3.3.3 | Cargar tres incidencias y filtrar por estado | Se consulta el técnico en sesión; conteos 3 / 2 / 1; el filtro muestra solo las del estado elegido |
| PU-522 | T 3.3.3, T 3.3.5 | Filtrar un estado sin incidencias y luego resolver la única incidencia | Mensaje del estado sin incidencias; al resolverse sale de la lista y aparece el mensaje de que no hay asignadas |
| PU-523 | T 3.3.2 | Falla la consulta | Se muestra el mensaje del error |
| PU-524 | T 3.3.1, T 3.3.3, T 3.3.4 | Lista con tres incidencias y filtro "En proceso" en la pantalla | Número, nombre, tipo, departamento, residente y llegada estimada; chips con sus cantidades; el filtro oculta las demás |
| PU-525 | T 3.3.4 | Tocar una incidencia | Se abre el detalle de esa incidencia |
| PU-526 | T 3.3.5 | Sin incidencias y con un filtro sin resultados | Mensaje informativo sin filtros; "Ver todas" vuelve a mostrar la lista |
| PU-527 | T 3.3.4 | Detalle propio y de otro técnico | Tipo, departamento, hora estimada, descripción, residente y teléfono; la de otro técnico muestra "Esta incidencia no está asignada a ti." |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso | Iniciar sesión como técnico | La pestaña Inicio muestra "Incidencias asignadas"; un residente o administrador no puede abrir `/technician` |
| PM-02 | Solo las suyas | Comparar la lista con Firestore | Aparecen solo las incidencias con `tecnicoId` del técnico en sesión |
| PM-03 | Estados | Revisar los estados y usar el filtro Todas / Asignada / En proceso | No aparecen pendientes, rechazadas ni resueltas; los conteos coinciden |
| PM-04 | Información | Tocar una incidencia | El detalle muestra tipo, departamento, fecha de creación, hora estimada, descripción, residente, teléfono y evidencias |
| PM-05 | Resuelta | Con la lista abierta, cambiar en Firestore el estado de una incidencia a `resuelta` | La incidencia desaparece de la lista sin recargar |
| PM-06 | Sin incidencias | Iniciar sesión con un técnico sin incidencias asignadas | Se muestra "No tienes incidencias asignadas por el momento…" |
| PM-07 | Nueva asignación | Con la lista abierta, asignar una incidencia al técnico desde la sesión del administrador | Aparece en la lista sin recargar |
| PM-08 | Diseño | Abrir la lista y el detalle en el teléfono y en la PC | El contenido se lee completo, sin cortes ni desbordes; las barras se ocultan al desplazarse |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 08/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.3 (PU-515 a PU-527) | 13 | Aprobadas |
| Proyecto completo (`flutter test`) | 233 | Aprobadas |

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
