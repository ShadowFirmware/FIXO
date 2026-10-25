# Plan de pruebas — HU 2.5 Consultar historial de incidencias

| Dato | Valor |
|---|---|
| Módulo | 2. Residente |
| Historia de usuario | HU 2.5 Consultar historial de incidencias (#40) |
| Tarea | T 2.5.8 Probar filtros, permisos y navegación al detalle (#80) |
| Rama | `feature/HU-2.5-consultar-historial-incidencias` |
| Fecha | 24/10/2026 |

## 1. Objetivo

Verificar que el residente pueda consultar el historial de incidencias de su departamento, incluidas las que reportaron residentes anteriores. Se prueban los datos de cada reporte, los filtros, el mensaje cuando no hay resultados y la navegación al detalle. También se verifica que no aparezcan incidencias de otro departamento.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 2.5.2 | Obtención de las incidencias de la vivienda del residente, ordenadas de la más reciente a la más antigua y actualizadas en tiempo real |
| T 2.5.3 | Número de reporte, nombre, tipo, fecha de creación y estado de cada incidencia |
| T 2.5.4 | Búsqueda por número o nombre, y filtros por estado, tipo y rango de fechas |
| T 2.5.5 | Mensaje cuando no hay incidencias o ninguna coincide con los filtros |
| T 2.5.6 | Abrir el detalle (HU 2.4) desde el historial |
| T 2.5.7 | Incidencias en los cinco estados y el dato adicional de cada uno |

**No incluye**

- Diseño visual (T 2.5.1): se revisa en las pruebas manuales.
- El contenido del detalle: ya se probó en la HU 2.4.
- Reglas de seguridad de Firestore: siguen siendo de desarrollo. La restricción por departamento se hace en la app.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 2.5 | Pruebas |
|---|---|---|
| CA-1 | Acceder a una sección de historial | PM-01 |
| CA-2 | Solo incidencias del departamento del residente, también las de residentes anteriores | PU-90, PU-97, PM-02, PM-09 |
| CA-3 | Mostrar número, nombre, tipo, fecha de creación y estado | PU-100, PM-01 |
| CA-4 | Incluir Pendientes, Asignadas, Rechazadas, En proceso y Resueltas | PU-91, PM-03 |
| CA-5 | Abrir el detalle de una incidencia | PU-101, PM-07 |
| CA-6 | Información de resolución o motivo de rechazo cuando corresponda | PU-99, PM-03 |
| CA-7 | Aplicar filtros | PU-92 a PU-95, PM-04, PM-05 |
| CA-8 | Mensaje cuando no hay resultados | PU-96, PU-102, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/resident/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

`FakeIncidentRepository.housingChanges` simula los cambios que Firestore envía en tiempo real.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo
- La consulta usa solo `where('viviendaId', ==)` y se ordena en la app, así que no requiere índices compuestos.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente A | Residente activo con `viviendaId` = vivienda A |
| Residente B | Residente activo con `viviendaId` = vivienda B |
| Incidencias | Al menos cinco de la vivienda A, una por estado. Una de ellas con `creadaPor` de otro residente (residente anterior) |
| Incidencia ajena | Una incidencia de la vivienda B |

Para los estados se editan los mismos campos que en la HU 2.4 (sección 6 de su plan): `estado`, `horaEstimada`, `solucion`, `fechaResolucion`, `comentarioRechazo` y `fechaRechazo`.

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/resident/incident_history_view_model_test.dart test/unitarias/resident/incident_history_screen_test.dart
```

### 7.1 Historial y filtros — `incident_history_view_model_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-90 | T 2.5.2 | Firestore devuelve incidencias de la vivienda y una de otra | Solo las de la vivienda, de la más reciente a la más antigua, incluida la del residente anterior; departamento "Torre A – 4B" |
| PU-91 | T 2.5.7 | Una incidencia por estado | Aparecen los cinco estados |
| PU-92 | T 2.5.4 | Filtrar por Rechazada y luego por Todos | Una incidencia y luego las cinco |
| PU-93 | T 2.5.4 | Filtrar por Luz, y por fechas del 2 al 4 de octubre | Las de luz; las del rango, incluida una creada el día 4 a las 11:59 p. m. |
| PU-94 | T 2.5.4 | Buscar "ELECTRICO", "INC-0002" y "3" | Encuentra "Apagador eléctrico dañado", el reporte 2 y el reporte 3 |
| PU-95 | T 2.5.4 | Tipo y estado juntos; limpiar filtros | Solo la que cumple ambos; al limpiar vuelven todas |
| PU-96 | T 2.5.5 | Sin incidencias; filtros sin coincidencias | "Aún no hay incidencias registradas en tu departamento." y "No se encontraron incidencias con los filtros seleccionados." |
| PU-97 | T 2.5.2 | Usuario técnico; residente sin vivienda | Mensaje de acceso denegado o de vivienda faltante, sin consultar Firestore |
| PU-98 | T 2.5.2 | Se registra una incidencia nueva; falla la conexión | Aparece primero sin recargar; luego mensaje de error |
| PU-99 | T 2.5.7 | Dato adicional por estado | Asignada: llegada estimada; Resuelta: solución o fecha; Rechazada: motivo; Pendiente: nada |

### 7.2 Pantalla — `incident_history_screen_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-100 | T 2.5.3 | Mostrar una incidencia | "INC-0007", "Fuga en baño", "Agua · 20 de octubre de 2026" y "Pendiente" |
| PU-101 | T 2.5.6 | Tocar la incidencia | Se abre la ruta del detalle con el ID `inc-7` |
| PU-102 | T 2.5.5 | Buscar "gas" y pulsar "Limpiar filtros" | Aparece el aviso sin resultados; al limpiar vuelve la incidencia y el campo de búsqueda queda vacío |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el historial | Como residente A, tocar "Historial" en la barra inferior | Lista con número, nombre, tipo, fecha y estado de cada incidencia, de la más reciente a la más antigua |
| PM-02 | Residente anterior | Revisar la incidencia con `creadaPor` de otro residente | También aparece en el historial |
| PM-03 | Estados | Revisar las cinco incidencias | Cada una con su color de estado; la asignada muestra la llegada estimada, la resuelta la solución y la rechazada el motivo |
| PM-04 | Buscar | Escribir parte del nombre sin acentos y luego un número de reporte | Solo quedan las que coinciden; el contador dice "N de M incidencias" |
| PM-05 | Filtros | Elegir un estado; en el botón de filtros elegir un tipo y un rango de fechas | La lista se reduce al momento; el botón muestra cuántos filtros de tipo y fecha hay activos |
| PM-06 | Sin resultados | Combinar filtros sin coincidencias y pulsar "Limpiar filtros" | Aparece el aviso; al limpiar vuelve la lista completa |
| PM-07 | Abrir el detalle | Tocar una incidencia | Se abre su detalle (HU 2.4); al regresar el historial conserva los filtros |
| PM-08 | Tiempo real | Con el historial abierto, registrar una incidencia o cambiar el estado de una en Firestore | La lista se actualiza sin recargar |
| PM-09 | Otro departamento | Iniciar sesión como residente B | No aparece ninguna incidencia de la vivienda A |
| PM-10 | Sin incidencias | Iniciar sesión con un residente cuya vivienda no tiene incidencias | "Aún no hay incidencias registradas en tu departamento." y sin filtros |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 24/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 2.5 (PU-90 a PU-102) | 13 | Aprobadas |
| Proyecto completo (`flutter test`) | 105 | Aprobadas |

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
