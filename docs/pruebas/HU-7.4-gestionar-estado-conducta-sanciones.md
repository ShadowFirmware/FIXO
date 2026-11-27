# Plan de pruebas — HU 7.4 Gestionar estado de conducta y sanciones

| Dato | Valor |
|---|---|
| Módulo | 7. Reportes de conducta |
| Historia de usuario | HU 7.4 Gestionar estado de conducta y sanciones |
| Tarea | T 7.4.16 Probar las reglas de conducta y sanciones |
| Rama | `feature/HU-7.4-Gestionar-estado-de-conducta-y-sanciones` |
| Fecha | 25/11/2026 |

## 1. Objetivo

Verificar que el sistema lleve el historial de reportes de conducta validados y aplique progresivamente las medidas correspondientes (advertencia, suspensión de 5, 10 o 20 días y deshabilitación indefinida), controlando reincidencias de residentes y técnicos, incluyendo reactivaciones automáticas y administrativas, y la reasignación de incidencias activas de técnicos sancionados.

## 2. Alcance

**Incluye**

| Apartado | Qué se prueba |
|---|---|
| Estructura de datos | Campos `estadoConducta`, `reportesValidados`, `suspendidaHasta`, `suspensionPendiente` y `diasSuspensionPendiente` en `usuarios` |
| Estado inicial | Residentes y técnicos nuevos con estado de conducta Bueno |
| Contador | Solo los reportes validados incrementan `reportesValidados` |
| Sanciones progresivas | Estado de conducta y consecuencia según la cantidad de reportes validados |
| Suspensiones temporales | Suspensión automática de 5, 10 o 20 días y fecha de término |
| Deshabilitación indefinida | Cuenta deshabilitada al quinto reporte validado |
| Reactivación automática | Cuenta reactivada al terminar la suspensión temporal |
| Reactivación administrativa | El administrador reactiva cuentas deshabilitadas indefinidamente |
| Reincidencia | Una cuenta reactivada que recibe otro reporte validado se deshabilita de nuevo |
| Técnico con incidencias activas | Bloqueo de nuevas asignaciones y aviso al administrador |
| Reasignación | El administrador reasigna las incidencias activas a otro técnico disponible |
| Suspensión diferida | La suspensión se aplica cuando el técnico ya no tiene incidencias activas |
| Notificaciones | Advertencias, suspensiones, deshabilitaciones y reactivaciones |
| Historial | Conservación de reportes validados, cambios de estado y sanciones |

**No incluye**

- El registro de los reportes de conducta (HU 7.1 y HU 7.2).
- La revisión manual del reporte (HU 7.3), salvo el efecto de validar.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | Todo residente y técnico nuevo inicia con estado de conducta Bueno | PU-006 (HU 1.1), PM-01 |
| CA-2 | Solo los reportes validados por el administrador se contabilizan | PU-691 (HU 7.3), PU-743, PM-01 |
| CA-3 | El sistema mantiene un contador histórico por usuario | PU-743, PU-744, PU-745, PM-01 a PM-05 |
| CA-4 | Sanciones progresivas según la cantidad de reportes validados | PU-740, PU-741, PU-743, PU-744, PU-745, PM-01 a PM-05 |
| CA-5 | Suspensión automática de 5, 10 o 20 días | PU-744, PU-741, PM-02 a PM-04 |
| CA-6 | Deshabilitación indefinida al quinto reporte | PU-742, PU-745, PM-05 |
| CA-7 | Reactivación automática al terminar la suspensión | PU-629 (HU 6.1), PM-06 |
| CA-8 | Reactivación administrativa de cuentas deshabilitadas | PM-07 |
| CA-9 | Reincidencia después de reactivación deshabilita de nuevo | PM-08 |
| CA-10 | Técnico con incidencias activas bloquea nuevas asignaciones y notifica al administrador | PU-746, PM-09 |
| CA-11 | El administrador puede reasignar las incidencias activas | PM-10 |
| CA-12 | La suspensión se aplica cuando el técnico ya no tiene incidencias activas | PU-747, PM-10 |
| CA-13 | Notificaciones de advertencias, suspensiones, deshabilitaciones y reactivaciones | PU-626 a PU-628 (HU 6.1), PU-749, PM-01 a PM-08 |

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
| Residente reportado | Residente activo, con estado de conducta Bueno y 0 reportes validados |
| Técnico reportado | Técnico activo y disponible, con estado de conducta Bueno y 0 reportes validados |
| Reportes validados | 1, 2, 3, 4 y 5 reportes validados sobre el mismo usuario para probar cada nivel |
| Técnico con incidencia activa | Técnico con una incidencia en estado Asignada o En proceso y una suspensión diferida |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/conduct_sanction_plan_test.dart
```

### 7.1 Reglas de sanciones — `conduct_sanction_plan_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-740 | Estado de conducta según reportes validados | 1 bueno, 2-3 medio, 4-5 malo |
| PU-741 | Días de suspensión progresiva | 2→5, 3→10, 4→20; los demás 0 |
| PU-742 | Deshabilitación de la cuenta | A partir del 5.º reporte validado |
| PU-743 | Primer reporte validado | Solo advertencia; la cuenta no cambia |
| PU-744 | Segundo reporte validado | Suspensión de 5 días y estado Medio |
| PU-745 | Quinto reporte validado | Cuenta deshabilitada de forma indefinida |
| PU-746 | Técnico con incidencias activas | Suspensión diferida y bloqueo de nuevas asignaciones |
| PU-747 | Aplicar suspensión diferida | La cuenta pasa a suspendida cuando ya no hay incidencias activas |
| PU-748 | Reporte rechazado | No cambia el perfil del usuario reportado |
| PU-749 | Notificaciones de sanción | Advertencia y, según el nivel, suspensión o deshabilitación |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Advertencia | Validar el primer reporte de un usuario | El usuario recibe la advertencia; la cuenta sigue activa |
| PM-02 | Suspensión de 5 días | Validar el segundo reporte | La cuenta se suspende por 5 días y el usuario recibe el aviso |
| PM-03 | Suspensión de 10 días | Validar el tercer reporte | La cuenta se suspende por 10 días y el usuario recibe nueva advertencia |
| PM-04 | Suspensión de 20 días | Validar el cuarto reporte | La cuenta se suspende por 20 días con advertencia de posible baja indefinida |
| PM-05 | Deshabilitación | Validar el quinto reporte | La cuenta queda deshabilitada de forma indefinida y el usuario es notificado |
| PM-06 | Reactivación automática | Iniciar sesión con una suspensión vencida | La cuenta se reactiva y aparece el aviso "Cuenta reactivada" |
| PM-07 | Reactivación administrativa | Como administrador, habilitar una cuenta deshabilitada indefinidamente | La cuenta vuelve a estar activa y el usuario recibe el aviso de reactivación |
| PM-08 | Reincidencia tras reactivación | Validar otro reporte de una cuenta reactivada por el administrador | La cuenta se deshabilita de nuevo de forma automática |
| PM-09 | Técnico con incidencia activa | Validar un reporte de un técnico con una incidencia Asignada o En proceso | Se bloquean nuevas asignaciones y el administrador recibe el aviso |
| PM-10 | Reasignación | Reasignar la incidencia activa a otro técnico disponible | La suspensión correspondiente se aplica al técnico original |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 25/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 7.4 (`conduct_sanction_plan_test.dart`) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 429 | Aprobadas |

### Manuales

| ID | Resultado | Fecha      | Responsable             | Observaciones     |
|---|-----------|------------|-------------------------|-------------------|
| PM-01 | Aprobado  | 25/11/2026 | Diego Daniel Gomez Nava | Sin observaciones |
| PM-02 | Pendiente |            |                         |                   |
| PM-03 | Pendiente |            |                         |                   |
| PM-04 | Pendiente |            |                         |                   |
| PM-05 | Pendiente |            |                         |                   |
| PM-06 | Pendiente |            |                         |                   |
| PM-07 | Pendiente |            |                         |                   |
| PM-08 | Pendiente |            |                         |                   |
| PM-09 | Pendiente |            |                         |                   |
| PM-10 | Pendiente |            |                         |                   |