# Plan de pruebas — HU 4.9 Asignar un técnico y establecer hora estimada

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.9 Asignar un técnico y establecer hora estimada (#93) |
| Tarea | T 4.9.8 Probar el proceso de asignación (#161) |
| Rama | `feature/HU-4.9-Asignar-un-tecnico-y-establecer-hora-estimada` |
| Fecha | 02/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda asignar una incidencia pendiente a un técnico disponible y establecer la hora estimada de llegada con un selector. Al confirmar, la incidencia debe pasar a Asignada, el técnico debe quedar No disponible y el residente y el técnico deben recibir su notificación. No se deben poder asignar técnicos suspendidos, deshabilitados, dados de baja o no disponibles.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 4.9.1 | Formulario con los datos de la incidencia, los técnicos como tarjetas seleccionables y la hora estimada |
| T 4.9.2 | Solo técnicos con cuenta activa y estado Disponible; reintentar si falla la consulta |
| T 4.9.3 | Selección de fecha y hora con los selectores del sistema; aviso inmediato si la hora ya pasó |
| T 4.9.4 | Reglas: incidencia todavía pendiente, técnico con rol técnico, cuenta activa, disponible y sin suspensión vigente; hora entre ahora y 30 días |
| T 4.9.5 | La incidencia cambia a Asignada con el técnico, la hora estimada y la fecha de asignación |
| T 4.9.6 | El técnico cambia a No disponible en la misma transacción |
| T 4.9.7 | Notificación al residente (técnico y hora) y al técnico (tipo, departamento, detalles y hora) |

**No incluye**

- Que el técnico vuelva a estar disponible al completar el reporte: corresponde a las historias del técnico (módulo 3).
- Rechazar incidencias (HU 4.10) y la lista de pendientes (HU 4.8).
- La pantalla de notificaciones (HU 6.1): aquí se verifica el documento que se guarda en `notificaciones`.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.9 | Pruebas |
|---|---|---|
| CA-1 | Mostrar solo técnicos con cuenta activa y estado Disponible | PU-440, PU-447, PM-02 |
| CA-2 | Seleccionar un técnico disponible | PU-447, PU-448, PM-03 |
| CA-3 | Hora estimada con selector, no con texto libre | PU-445, PU-446, PU-448, PM-04 |
| CA-4 | Al confirmar, la incidencia pasa de Pendiente a Asignada | PU-439, PU-441, PU-448, PM-05 |
| CA-5 | El residente recibe el nombre del técnico y la hora estimada | PU-443, PM-06 |
| CA-6 | El técnico recibe los detalles de la incidencia | PU-444, PM-06 |
| CA-7 | El técnico cambia a No disponible | PU-442, PM-07 |
| CA-8 | No asignar técnicos suspendidos, desactivados o inhabilitados | PU-440, PU-450, PM-08 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las reglas de la asignación están en `AssignmentPlan`, que trabaja con los datos leídos en la transacción. Así se prueban sin Firestore y sin agregar dependencias.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario `administrador` activo |
| Residente | Residente activo con vivienda, con al menos dos incidencias pendientes |
| Técnico A | `tecnico`, `estadoCuenta: activa`, `disponible: true` |
| Técnico B | `tecnico`, `estadoCuenta: suspendida` |
| Técnico C | `tecnico`, `estadoCuenta: activa`, `disponible: false` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/assignment_plan_test.dart test/unitarias/admin/assign_incident_test.dart
```

### 7.1 Reglas y datos guardados — `assignment_plan_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-439 | T 4.9.4 | Incidencia inexistente o ya asignada | No se asigna: "ya no está pendiente" |
| PU-440 | T 4.9.4 | Técnico inexistente, suspendido, deshabilitado, dado de baja, no disponible, sin campo `disponible`, con rol residente o con suspensión vigente | No se asigna: "ya no está disponible"; con una suspensión ya vencida sí se asigna |
| PU-441 | T 4.9.5 | Datos de la incidencia | `estado: asignada`, `tecnicoId`, `horaEstimada` y `fechaAsignacion` del servidor |
| PU-442 | T 4.9.6 | Datos del técnico | `disponible: false` |
| PU-443 | T 4.9.7 | Aviso al residente | "Juan Pérez atenderá "Fuga en baño". Hora estimada de llegada: 2 de noviembre de 2026, 4:30 p. m." |
| PU-444 | T 4.9.7 | Aviso al técnico | Título, tipo, departamento, detalles (recortados si son largos) y hora estimada |

### 7.2 Formulario — `assign_incident_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-445 | T 4.9.3, T 4.9.4 | Hora vacía, pasada, dentro del rango y a más de 30 días | Mensaje correspondiente; el día 30 a las 11:59 p. m. es válido |
| PU-446 | T 4.9.3 | Hora sugerida | Dentro de una hora, redondeada al siguiente cuarto (10:07 → 11:15) |
| PU-447 | T 4.9.1, T 4.9.2 | Abrir el formulario y confirmar sin datos | Muestra la incidencia y los técnicos con especialidad y teléfono; pide técnico y luego hora |
| PU-448 | T 4.9.5 | Elegir técnico y hora, y confirmar | Se asigna al técnico elegido y aparece "Incidencia INC-0001 asignada." |
| PU-449 | T 4.9.2 | Falla la consulta de técnicos | Mensaje de error y botón "Reintentar" que vuelve a consultar |
| PU-450 | T 4.9.4 | El técnico dejó de estar disponible antes de confirmar | "El técnico seleccionado ya no está disponible. Elige otro." |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | Como administrador, en "Reportes pendientes" pulsar "Asignar" en una incidencia | Se ve el número, título, tipo, departamento y quién la reportó |
| PM-02 | Técnicos disponibles | Revisar la lista del formulario | Aparece el técnico A; no aparecen el B (suspendido) ni el C (no disponible) |
| PM-03 | Elegir técnico | Tocar la tarjeta del técnico A | Queda marcada |
| PM-04 | Hora estimada | Tocar "Fecha y hora de llegada" y elegir una hora que ya pasó, luego una válida | Con la pasada aparece el aviso; con la válida se muestra la fecha y hora elegidas |
| PM-05 | Confirmar | Pulsar "Asignar" | Mensaje "Incidencia INC-xxxx asignada."; desaparece de pendientes y en Firestore queda `estado: asignada` con `tecnicoId` y `horaEstimada` |
| PM-06 | Notificaciones | Revisar la colección `notificaciones` | Un documento para el residente con el nombre del técnico y la hora, y otro para el técnico con tipo, departamento, detalles y hora |
| PM-07 | Disponibilidad | Revisar al técnico A en Firestore y en "Técnicos" | `disponible: false`; ya no aparece al asignar otra incidencia |
| PM-08 | Técnico que deja de estar disponible | Abrir el formulario, cambiar en Firestore `disponible: false` al técnico elegido y confirmar | "El técnico seleccionado ya no está disponible. Elige otro." y la incidencia sigue pendiente |
| PM-09 | Detalle del residente | Como residente, abrir la incidencia asignada (HU 2.4) | Se ve el técnico y la hora estimada |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-09 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 02/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.9 (PU-439 a PU-450) | 12 | Aprobadas |
| Proyecto completo (`flutter test`) | 156 | Aprobadas |

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
