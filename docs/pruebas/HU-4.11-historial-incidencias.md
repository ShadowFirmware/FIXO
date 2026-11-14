# Plan de pruebas — HU 4.11 Consultar historial de incidencias

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.11 Consultar historial de incidencias (#95) |
| Tarea | T 4.11.8 Probar el historial, los filtros y la exportación (#177) |
| Rama | `feature/HU-4.11-Consultar-historial-de-incidencias` |
| Fecha | 02/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda consultar todas las incidencias, sin importar su estado, con todos sus datos. También se verifica que pueda filtrarlas por estado, tipo, técnico, departamento y rango de fechas, ver las evidencias del residente (antes) y del técnico (después), y exportar el historial a PDF.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 4.11.1 | Pantalla "Historial" en el menú del administrador: tarjetas en el teléfono y tabla en pantallas anchas |
| T 4.11.2 | Incidencias de los cinco estados, de la más reciente a la más antigua, con el conteo por estado y los errores de carga |
| T 4.11.3 | Número de reporte, nombre, tipo, estado, detalles, evidencias, departamento, quién reportó, técnico asignado, fecha de creación y de resolución; detalle completo con la solución o el motivo del rechazo |
| T 4.11.4 | Filtros por estado, tipo, técnico y departamento, combinables y con "Limpiar filtros" |
| T 4.11.5 | Filtro por rango de fechas de creación (ambos días completos) |
| T 4.11.6 | Evidencias del residente (antes) y del técnico (después) en el detalle |
| T 4.11.7 | Exportación a PDF de las incidencias que se muestran, con los filtros aplicados |

**No incluye**

- Asignar y rechazar incidencias (HU 4.9 y HU 4.10), ni la lista de pendientes (HU 4.8).
- Subir las evidencias: las del residente se registran en la HU 2.3 y las del técnico al resolver la incidencia.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.11 | Pruebas |
|---|---|---|
| CA-1 | Ver todas las incidencias, sin importar su estado | PU-462, PU-469, PM-01, PM-02 |
| CA-2 | Cada incidencia muestra número, nombre, tipo, detalles, evidencias, departamento, quién la registró, técnico, fecha de creación y de resolución | PU-462, PU-472, PU-473, PU-474, PM-03, PM-04 |
| CA-3 | Filtrar por estado, tipo, técnico, departamento y rango de fechas | PU-464, PU-465, PU-470, PU-472, PM-05, PM-06 |
| CA-4 | Al abrir una incidencia se ven las evidencias del residente (antes) y del técnico (después) | PU-474, PM-07 |
| CA-5 | El historial se puede exportar a PDF | PU-466, PU-467, PU-468, PU-471, PU-475, PM-08, PM-09 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

Los filtros (`AdminHistoryFilter`) y el contenido del reporte (`HistoryReport`) se prueban sin Firestore. En las pruebas de la pantalla, `FakeHistoryPdfExporter` guarda lo que se exportaría en lugar de abrir el menú para compartir.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Paquetes nuevos: `pdf` 3.13.1 y `printing` 5.15.1
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario `administrador` activo |
| Incidencias | Al menos una en cada estado: Pendiente, Asignada, En proceso, Resuelta (con evidencias antes y después, y solución) y Rechazada (con motivo) |
| Técnicos | Dos técnicos con incidencias asignadas |
| Departamentos | Incidencias de al menos dos viviendas distintas |
| Fechas | Incidencias creadas en días distintos del mismo mes |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/admin_history_data_test.dart test/unitarias/admin/admin_incident_history_test.dart
```

### 7.1 Datos, filtros y reporte — `admin_history_data_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-462 | T 4.11.2, T 4.11.3 | Incidencias de los cinco estados, con y sin fecha | Llegan todas, de la más reciente a la más antigua (las recién creadas primero), con el departamento, quién reportó y el técnico; sin técnico queda vacío |
| PU-463 | T 4.11.2 | Firestore falla por permisos, sin conexión u otro error | Mensaje para cada caso |
| PU-464 | T 4.11.4 | Filtrar por estado, tipo, técnico y departamento; combinarlos y quitar uno | Solo quedan las que cumplen todos los filtros activos |
| PU-465 | T 4.11.5 | Rango completo, solo "desde", solo "hasta", fecha final antes de la inicial | Se incluyen ambos días completos; las incidencias sin fecha no entran; el rango invertido no es válido |
| PU-466 | T 4.11.7 | Fila del reporte de una incidencia resuelta y de una pendiente con detalles largos | Tiene las 11 columnas; los detalles se recortan a 120 caracteres; "Sin asignar" y "-" cuando falta un dato |
| PU-467 | T 4.11.7 | Encabezado del reporte | Lista los filtros aplicados (o "ninguno"), la fecha de generación y el nombre `historial-incidencias-AAAA-MM-DD.pdf` |
| PU-468 | T 4.11.7 | Generar el PDF con guiones largos, comillas, "ñ" y emojis | Es un PDF válido; los caracteres que la fuente no tiene se cambian por su equivalente simple |

### 7.2 ViewModel e interfaz — `admin_incident_history_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-469 | T 4.11.2 | Cargar el historial, quedarse sin incidencias y fallar | Conteo por estado correcto; "Aún no hay incidencias registradas."; mensaje de error |
| PU-470 | T 4.11.4, T 4.11.5 | Opciones de técnico y departamento; aplicar y limpiar filtros; rango invertido | Opciones sin repetir y en orden; "No se encontraron incidencias…" cuando nada coincide; el rango inválido no se aplica |
| PU-471 | T 4.11.7 | Exportar con un filtro, sin resultados y con un error | Exporta solo lo filtrado con sus filtros y nombre de archivo; avisa cuando no hay nada que exportar o falla |
| PU-472 | T 4.11.1, T 4.11.3, T 4.11.4 | Teléfono: tarjetas, chip "Resuelta (1)" y filtro de técnico | Cada tarjeta muestra sus datos; "1 de 3 incidencias" al filtrar; el técnico elegido filtra la lista |
| PU-473 | T 4.11.1, T 4.11.3 | Pantalla ancha | Tabla con todas las columnas |
| PU-474 | T 4.11.3, T 4.11.6 | Abrir una incidencia rechazada y una resuelta | Motivo del rechazo; solución; secciones de evidencias del residente y del técnico con su cantidad o el aviso de que no hay |
| PU-475 | T 4.11.7 | Pulsar "Exportar a PDF" con un filtro y sin resultados | Exporta lo filtrado; avisa que no hay incidencias para exportar |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso | Como administrador, abrir el menú y elegir "Historial de incidencias" | Se abre el historial; un residente o técnico no puede abrir la ruta `/admin/incidents/history` |
| PM-02 | Todos los estados | Revisar los chips de estado | "Todas (n)" y el número de cada estado coinciden con Firestore |
| PM-03 | Datos completos (PC) | En el navegador con la ventana ancha, revisar la tabla | Tiene número, nombre, tipo, estado, detalles, evidencias, departamento, quién reportó, técnico y fechas de creación y resolución |
| PM-04 | Datos completos (teléfono) | En el teléfono, revisar las tarjetas | Cada tarjeta muestra los mismos datos; la fecha de resolución solo en las resueltas |
| PM-05 | Filtros | Filtrar por estado, después por tipo, técnico y departamento; luego "Limpiar filtros" | La lista y el contador "x de n incidencias" cambian al momento; al limpiar vuelven todas |
| PM-06 | Rango de fechas | Elegir un rango de fechas de creación y después quitarlo | Solo quedan las creadas en ese rango, incluidos el primer y el último día |
| PM-07 | Evidencias | Abrir una incidencia resuelta con evidencias | Se ven las evidencias del residente (antes) y del técnico (después); al tocar una se abre en pantalla completa |
| PM-08 | PDF en la web | Con un filtro activo, pulsar el ícono de PDF en Chrome | Se descarga `historial-incidencias-AAAA-MM-DD.pdf` con los filtros, la fecha y solo las incidencias filtradas |
| PM-09 | PDF en el teléfono | Pulsar el ícono de PDF en Android | Se abre el menú para compartir o guardar el PDF; los acentos y la "ñ" se ven bien |
| PM-10 | Tiempo real | Con el historial abierto, asignar o rechazar una incidencia desde otra sesión | El estado y los contadores se actualizan solos |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 02/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.11 (PU-462 a PU-475) | 14 | Aprobadas |
| Proyecto completo (`flutter test`) | 181 | Aprobadas |

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
| PM-10 | Aprobada | 02/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
