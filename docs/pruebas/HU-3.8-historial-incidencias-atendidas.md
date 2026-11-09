# Plan de pruebas — HU 3.8 Consultar historial de incidencias atendidas

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.8 Consultar historial de incidencias atendidas (#247) |
| Tarea | T 3.8.7 Probar la consulta del historial (#273) |
| Rama | `feature/HU-3.8-Consultar-historial-de-incidencias-atendidas` |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda consultar el historial de las incidencias que atendió, ver la solución, las evidencias y la fecha de resolución de cada una, y filtrarlas por tipo y fecha. Si no hay incidencias que coincidan, el sistema debe mostrar un mensaje informativo.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.8.1 | Pestaña "Historial" con "Incidencias atendidas", el total y una tarjeta por incidencia |
| T 3.8.2 | Consulta en Firestore de las incidencias resueltas del técnico (`tecnicoId` y `estado`, sin índice compuesto); reintento tras un error |
| T 3.8.3 | Tarjeta con número, nombre, tipo, lugar, fecha de resolución, resumen de la solución, evidencias y duración de la atención |
| T 3.8.4 | Detalle con la solución, las evidencias del trabajo y el resumen de la atención (inicio, solución, resolución y duración) |
| T 3.8.5 | Filtros por tipo y por rango de fechas de resolución |
| T 3.8.6 | Mensajes si no hay incidencias atendidas o ninguna coincide con los filtros, con "Limpiar filtros" |

**No incluye**

- La finalización de incidencias (HU 3.7).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.8 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede acceder a una sección de Historial o Reportes atendidos | PU-571, PM-01 |
| CA-2 | El historial muestra únicamente las incidencias resueltas que fueron atendidas por el técnico autenticado | PU-566, PU-567, PM-02 |
| CA-3 | El técnico puede consultar los detalles de cada incidencia | PU-573, PM-03 |
| CA-4 | El sistema muestra la solución registrada, las evidencias y la fecha de resolución | PU-568, PU-571, PU-573, PM-03 |
| CA-5 | El técnico puede filtrar las incidencias por tipo y fecha | PU-568, PU-569, PU-571, PU-572, PM-04, PM-05 |
| CA-6 | Si no existen incidencias que coincidan con la consulta, el sistema muestra un mensaje informativo | PU-569, PU-570, PU-572, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. La consulta usa dos filtros de igualdad, que no necesitan índice compuesto.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnico | Con tres incidencias resueltas de distintos tipos y fechas, y una En proceso |
| Otro técnico | Con una incidencia resuelta, que no debe aparecer |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/attended_history_test.dart
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-566 | T 3.8.2 | Consultar las resueltas y errores de Firestore | Llegan con el residente; mensajes de sin conexión, sin permiso y error de carga |
| PU-567 | T 3.8.2 | Un residente consulta; incidencias del técnico, de otro técnico y En proceso | Se niega al residente; solo quedan las resueltas del técnico, de la más reciente a la más antigua |
| PU-568 | T 3.8.3, T 3.8.5 | Duración de la atención, evidencias y texto del rango de fechas | "2 h 15 min", "45 min", "1 d 3 h"; "2 evidencias"; "Todas las fechas", "1 nov 2026 – 9 nov 2026", "Desde 1 nov 2026" |
| PU-569 | T 3.8.5, T 3.8.6 | Filtrar por tipo, por fechas (incluidos ambos días) y combinados; limpiar | Quedan las que coinciden; sin resultados aparece el mensaje; al limpiar vuelven todas |
| PU-570 | T 3.8.2, T 3.8.6 | Falla la consulta, se reintenta y no hay historial | Muestra el error; al reintentar vuelve a consultar; mensaje de que aún no hay incidencias atendidas |
| PU-571 | T 3.8.1, T 3.8.3, T 3.8.5 | Historial con tres incidencias y filtro "Luz" | Total 3; cada tarjeta con fecha, solución, evidencias y duración; el filtro deja una y muestra "Mostrando 1 de 3" |
| PU-572 | T 3.8.5, T 3.8.6 | Sin historial; rango de fechas sin resultados; limpiar filtros | Mensaje sin filtros; mensaje de sin coincidencias; "Limpiar filtros" vuelve a mostrar todas |
| PU-573 | T 3.8.4 | Detalle de una incidencia atendida | Solución, evidencias del trabajo y resumen con el inicio, la solución, la resolución y la duración, sin fechas repetidas |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso | Como técnico, abrir la pestaña "Historial" | Se ve "Incidencias atendidas" con el total |
| PM-02 | Solo las suyas | Comparar con Firestore | Solo aparecen las incidencias `resuelta` con el `tecnicoId` del técnico |
| PM-03 | Detalle | Tocar una incidencia | Muestra la solución, las evidencias (se abren en pantalla completa) y el resumen de la atención |
| PM-04 | Tipo | Elegir un tipo | Solo quedan las de ese tipo y se indica cuántas se muestran |
| PM-05 | Fechas | Elegir un rango de fechas y luego quitarlo | Solo quedan las resueltas en ese rango, incluidos ambos días |
| PM-06 | Sin resultados | Elegir un rango sin incidencias y tocar "Limpiar filtros"; entrar con un técnico sin historial | Mensaje de sin coincidencias y luego la lista completa; para el técnico sin historial, el mensaje de que aún no hay incidencias atendidas |
| PM-07 | Tiempo real | Con el historial abierto, finalizar otra incidencia desde otro dispositivo | Aparece sin recargar |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-07 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.8 (PU-566 a PU-573) | 8 | Aprobadas |
| Proyecto completo (`flutter test`) | 279 | Aprobadas |

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
