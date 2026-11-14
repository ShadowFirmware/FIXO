# Plan de pruebas — HU 4.12 Consultar estadísticas de incidencias por periodo

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.12 Consultar estadísticas de incidencias por periodo (#96) |
| Tarea | T 4.12.9 Probar los periodos, cálculos y gráficas (#186) |
| Rama | `feature/HU-4.12-Consultar-estadisticas-de-incidencias-por-periodo` |
| Fecha | 02/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda elegir un periodo (semanal, mensual o personalizado) y ver un dashboard con las gráficas de incidencias por tipo, por estado y asignadas por técnico, y que las estadísticas se actualicen en tiempo real con los cambios del sistema.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 4.12.1 | Pantalla "Estadísticas" en el menú del administrador, con el resumen y las tres secciones en 1, 2 o 3 columnas según el ancho |
| T 4.12.2 | Periodo semanal (lunes a domingo), mensual o personalizado; flechas para el periodo anterior y siguiente |
| T 4.12.3 | Consulta a Firestore de las incidencias creadas dentro del periodo, con los nombres de los técnicos |
| T 4.12.4 | Incidencias por tipo, incluidos los tipos sin incidencias |
| T 4.12.5 | Incidencias por estado y el resumen por estado |
| T 4.12.6 | Incidencias asignadas por técnico, de más a menos, con cuántas resolvió |
| T 4.12.7 | Gráficas de barras (tipo y técnico) y de dona (estado), con cantidad y porcentaje |
| T 4.12.8 | Actualización en tiempo real, hora de la última actualización y reintento tras un error |

**No incluye**

- El historial de incidencias (HU 4.11) ni su exportación a PDF.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.12 | Pruebas |
|---|---|---|
| CA-1 | Seleccionar el periodo: semanal, mensual o rango personalizado | PU-476, PU-477, PU-478, PU-479, PU-485, PU-489, PM-02, PM-03, PM-04 |
| CA-2 | Gráfica de incidencias por tipo | PU-481, PU-484, PU-488, PM-05 |
| CA-3 | Gráfica de incidencias por estado | PU-482, PU-484, PU-488, PM-05 |
| CA-4 | Número de incidencias asignadas por técnico | PU-483, PU-488, PM-06 |
| CA-5 | Las estadísticas se actualizan en tiempo real con los datos del sistema | PU-480, PU-486, PU-487, PU-490, PM-07, PM-08 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

Los periodos (`StatsPeriod`) y los cálculos (`IncidentStats`) se prueban sin Firestore. Las pruebas del ViewModel y del dashboard usan un reloj fijo: miércoles 4 de noviembre de 2026, 10:00.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. La consulta filtra un solo campo (`fechaCreacion`), así que no necesita índice compuesto.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario `administrador` activo |
| Incidencias | De esta semana, de semanas anteriores del mismo mes y del mes anterior; de varios tipos y en los cinco estados |
| Técnicos | Dos técnicos con incidencias asignadas, uno de ellos con incidencias resueltas |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/admin_statistics_data_test.dart test/unitarias/admin/admin_statistics_test.dart
```

### 7.1 Periodos, datos y cálculos — `admin_statistics_data_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-476 | T 4.12.2 | Semana de un miércoles y de un domingo que cruza de mes | Va de lunes a domingo; "2 nov 2026 – 8 nov 2026" |
| PU-477 | T 4.12.2 | Mes de noviembre y de diciembre | Del día 1 al último día; "Noviembre 2026"; diciembre termina el 31 |
| PU-478 | T 4.12.2 | Rango personalizado, invertido, de más de 366 días y de un solo día | Incluye ambos días completos; mensajes de error para los inválidos |
| PU-479 | T 4.12.2 | Periodo anterior y siguiente | Semana ± 7 días, mes ± 1 (incluido el cambio de año), rango ± su duración; se detecta el periodo que incluye hoy |
| PU-480 | T 4.12.3, T 4.12.8 | Incidencias del periodo y errores de Firestore | Llegan con el nombre del técnico; mensaje para permisos, sin conexión y otros errores |
| PU-481 | T 4.12.4 | Conteo por tipo | Cuenta cada tipo e incluye los que tienen 0 |
| PU-482 | T 4.12.5 | Conteo por estado | Cuenta cada estado; la suma es el total |
| PU-483 | T 4.12.6 | Conteo por técnico | De más a menos y, si empatan, por nombre; incluye las resueltas; las incidencias sin técnico no cuentan |
| PU-484 | T 4.12.7 | Porcentajes, largo de las barras y ángulos de la dona | "25 %", "33.3 %", "0 %"; la barra mayor mide 1; la dona suma una vuelta completa |

### 7.2 ViewModel y dashboard — `admin_statistics_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-485 | T 4.12.2, T 4.12.3 | Abrir, cambiar a mensual, ir al mes anterior y siguiente, elegir un rango | Se consulta el rango correcto en cada caso; no se avanza más allá del periodo actual; el rango inválido no se consulta |
| PU-486 | T 4.12.8 | Llegan cambios del sistema y luego se cambia de periodo | Las estadísticas y la hora de actualización cambian; al cambiar de periodo se borran los datos del anterior |
| PU-487 | T 4.12.8 | Falla la consulta y se reintenta | Muestra el error; al reintentar vuelve a consultar y carga |
| PU-488 | T 4.12.1, T 4.12.4–T 4.12.7 | Dashboard con 4 incidencias | Resumen, gráficas por tipo, estado y técnico con cantidad y porcentaje, y "En tiempo real · Actualizado a las 10:00 a. m." |
| PU-489 | T 4.12.2 | Elegir "Mensual" y el mes anterior en la pantalla | "Noviembre 2026" y luego "Octubre 2026"; la flecha siguiente está deshabilitada en el mes actual |
| PU-490 | T 4.12.1, T 4.12.8 | Periodo sin incidencias y error | "No hay incidencias en este periodo." en las tres secciones; "Reintentar" vuelve a cargar |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso | Como administrador, abrir el menú y elegir "Estadísticas" | Se abre el dashboard con la semana actual; un residente o técnico no puede abrir `/admin/statistics` |
| PM-02 | Semanal | Revisar el periodo y usar las flechas | Va de lunes a domingo; la flecha siguiente está deshabilitada en la semana actual |
| PM-03 | Mensual | Elegir "Mensual" y recorrer meses | Muestra "Noviembre 2026", "Octubre 2026", etc., con sus incidencias |
| PM-04 | Personalizado | Elegir "Personalizado" y un rango; luego tocar el periodo para cambiarlo | Solo cuenta las incidencias creadas en el rango, incluidos el primer y el último día |
| PM-05 | Tipo y estado | Comparar las gráficas con Firestore para el mismo periodo | Las cantidades y porcentajes coinciden |
| PM-06 | Técnicos | Revisar "Asignadas por técnico" | Cada técnico con sus incidencias asignadas y resueltas, de más a menos |
| PM-07 | Tiempo real | Con el dashboard abierto, registrar, asignar o rechazar una incidencia de esta semana desde otra sesión | Las gráficas y la hora de actualización cambian sin recargar |
| PM-08 | Sin conexión | Desconectar internet y cambiar de periodo; reconectar y pulsar "Reintentar" | Se muestra el error; al reintentar se cargan los datos |
| PM-09 | Diseño | Abrir en el teléfono y en la PC | En el teléfono las secciones van una debajo de otra; en la PC en dos o tres columnas |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-09 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 02/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.12 (PU-476 a PU-490) | 15 | Aprobadas |
| Proyecto completo (`flutter test`) | 196 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-08 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-09 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
