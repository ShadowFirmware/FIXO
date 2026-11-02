# Plan de pruebas — HU 4.10 Rechazar reporte

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.10 Rechazar reporte (#94) |
| Tarea | T 4.10.8 Probar el proceso de rechazo (#169) |
| Rama | `feature/HU-4.10-Rechazar-reporte` |
| Fecha | 02/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda rechazar una incidencia pendiente con un motivo obligatorio y después de confirmar. La incidencia debe pasar a Rechazada con el motivo y la fecha, sin técnico ni hora estimada, y el residente debe recibir una notificación con el motivo. También se verifica que una incidencia rechazada ya no se pueda asignar.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 4.10.1 | Opción "Rechazar" en las tarjetas, la tabla y el detalle de cada incidencia pendiente |
| T 4.10.2 | Formulario con el resumen de la incidencia y el campo del motivo |
| T 4.10.3 | Motivo obligatorio (no vacío ni solo espacios) y de máximo 500 caracteres, en el formulario y en el repositorio |
| T 4.10.4 | Confirmación con el motivo y sus consecuencias antes de rechazar |
| T 4.10.5 | La incidencia pasa a Rechazada con el motivo y la fecha; sin técnico ni hora estimada |
| T 4.10.6 | Notificación al residente con el motivo; no se asigna técnico ni se crea chat |
| T 4.10.7 | Una incidencia rechazada no se puede asignar |

**No incluye**

- Asignar incidencias (HU 4.9) y la lista de pendientes (HU 4.8).
- Cómo ve el residente el rechazo: el detalle (HU 2.4) ya muestra el comentario y la fecha.
- La pantalla de notificaciones (HU 6.1): aquí se verifica el documento que se guarda en `notificaciones`.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.10 | Pruebas |
|---|---|---|
| CA-1 | Rechazar una incidencia pendiente de asignación | PU-451, PU-461, PM-01, PM-02 |
| CA-2 | Comentario obligatorio con el motivo | PU-454, PU-458, PM-03 |
| CA-3 | No permitir el rechazo con el comentario vacío | PU-454, PU-455, PU-458, PM-03 |
| CA-4 | Solicitar confirmación antes de rechazar | PU-459, PM-04 |
| CA-5 | El estado cambia de Pendiente a Rechazada | PU-452, PU-460, PM-05 |
| CA-6 | El residente recibe una notificación con el motivo | PU-453, PM-06 |
| CA-7 | Sin técnico asignado ni chat de atención | PU-452, PM-05 |
| CA-8 | Una incidencia rechazada es definitiva y no se puede asignar | PU-451, PU-456, PU-457, PM-07 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las reglas del rechazo están en `RejectionPlan` y `RejectionRules`, que se prueban sin Firestore.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario `administrador` activo |
| Residente | Residente activo con vivienda y al menos dos incidencias pendientes |
| Técnico | `tecnico` activo y disponible (para intentar asignar una rechazada) |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin/rejection_plan_test.dart test/unitarias/admin/reject_incident_test.dart
```

### 7.1 Reglas y datos guardados — `rejection_plan_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-451 | T 4.10.5 | Incidencia inexistente, asignada o ya rechazada | No se rechaza: "ya no está pendiente" |
| PU-452 | T 4.10.5, T 4.10.6 | Datos de la incidencia | `estado: rechazada`, `comentarioRechazo`, `fechaRechazo` del servidor, `tecnicoId` y `horaEstimada` nulos, sin datos de chat |
| PU-453 | T 4.10.6 | Aviso al residente | "Tu reporte "Puerta del elevador" fue rechazado. Motivo: Es del área común" |

### 7.2 Validaciones, formulario y confirmación — `reject_incident_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-454 | T 4.10.3 | Motivo vacío, con solo espacios, de 501 caracteres y válido | Mensaje correspondiente; el válido pasa |
| PU-455 | T 4.10.3 | Llamar al repositorio con un motivo vacío | Se rechaza la llamada sin escribir en Firestore |
| PU-456 | T 4.10.7 | Asignar una incidencia rechazada | "La incidencia fue rechazada y ya no se puede asignar." |
| PU-457 | T 4.10.7 | El ViewModel recibe una incidencia rechazada para asignar | No llama al repositorio y muestra el mismo mensaje |
| PU-458 | T 4.10.2, T 4.10.3 | Abrir el formulario y pulsar "Rechazar" sin motivo | Muestra la incidencia y el aviso para el residente; pide el motivo y el error desaparece al escribir |
| PU-459 | T 4.10.4 | Confirmación | Muestra el motivo sin espacios extra y las consecuencias; al cancelar no se rechaza |
| PU-460 | T 4.10.5 | Confirmar | Se rechaza con el motivo y aparece "Incidencia INC-0001 rechazada." |
| PU-461 | T 4.10.1 | Pulsar "Rechazar" en el detalle de la incidencia | Se abre el formulario de rechazo |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Opción en la lista | Como administrador, en "Reportes pendientes" revisar la tabla (PC) o las tarjetas (teléfono) | Cada incidencia tiene "Rechazar" |
| PM-02 | Opción en el detalle | Abrir el detalle de una incidencia pendiente | Tiene "Rechazar" y "Asignar"; "Rechazar" abre el formulario |
| PM-03 | Motivo obligatorio | Pulsar "Rechazar" sin motivo y luego con solo espacios | "Escribe el motivo del rechazo"; no se pasa a la confirmación |
| PM-04 | Confirmación | Escribir un motivo y pulsar "Rechazar"; en la confirmación pulsar "Cancelar" | Se ve el motivo y las consecuencias; al cancelar la incidencia sigue pendiente |
| PM-05 | Rechazar | Repetir y confirmar | "Incidencia INC-xxxx rechazada."; desaparece de pendientes; en Firestore `estado: rechazada`, `comentarioRechazo`, `fechaRechazo` y sin `tecnicoId` |
| PM-06 | Notificación | Revisar la colección `notificaciones` | Documento para el residente con el título y el motivo |
| PM-07 | No se puede asignar | Con el formulario de asignar abierto en otra sesión, rechazar la incidencia y luego confirmar la asignación | "La incidencia fue rechazada y ya no se puede asignar."; sigue rechazada |
| PM-08 | Vista del residente | Como residente, abrir la incidencia rechazada (HU 2.4) | Se ve el motivo y la fecha del rechazo, sin técnico ni hora estimada |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 02/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.10 (PU-451 a PU-461) | 11 | Aprobadas |
| Proyecto completo (`flutter test`) | 167 | Aprobadas |

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
