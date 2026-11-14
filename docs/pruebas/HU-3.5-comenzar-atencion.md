# Plan de pruebas — HU 3.5 Comenzar la atención de una incidencia

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.5 Comenzar la atención de una incidencia (#229) |
| Tarea | T 3.5.6 Probar el inicio de atención (#235) |
| Rama | `feature/HU-3.5-Comenzar-la-atencion-de-una-incidencia` |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda comenzar la atención solo de las incidencias que tiene asignadas y que estén en estado Asignada. El estado debe cambiar a En proceso, guardarse en Firestore y reflejarse en las consultas del técnico, el residente y el administrador. Una incidencia En proceso no debe poder iniciarse de nuevo.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.5.1 | Botón "Comenzar atención" en las tarjetas de la lista de asignadas (además del que ya tenía el detalle desde la HU 3.4), con confirmación |
| T 3.5.2 | Solo el técnico asignado, con la cuenta activa y sin suspensión vigente, puede comenzar la atención |
| T 3.5.3 | Solo una incidencia Asignada se puede comenzar; mensajes específicos si ya está En proceso, resuelta, rechazada o sin asignar |
| T 3.5.4 | La incidencia pasa a `en_proceso` con `fechaInicioAtencion`; el técnico ve desde cuándo la atiende |
| T 3.5.5 | Aviso al residente y a los administradores; el inicio de la atención aparece en las pantallas del residente y del administrador |

**No incluye**

- Registrar la solución y marcar la incidencia como Resuelta (otra HU).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.5 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede comenzar la atención únicamente de las incidencias que tiene asignadas | PU-538, PU-540, PM-02, PM-03 |
| CA-2 | La opción Comenzar atención está disponible cuando la incidencia se encuentra en estado Asignada | PU-544, PM-01 |
| CA-3 | Al comenzar la atención, el estado cambia de Asignada a En proceso | PU-541, PU-544, PM-01 |
| CA-4 | El nuevo estado se guarda en el sistema | PU-541, PU-542, PM-04 |
| CA-5 | El cambio de estado se refleja en las consultas del técnico, residente y administrador | PU-543, PU-544, PM-05 |
| CA-6 | Una incidencia que ya se encuentra En proceso no puede volver a iniciarse | PU-539, PU-545, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnico | Técnico activo con dos incidencias Asignadas |
| Otro técnico | Con una incidencia asignada, para comprobar que no se puede comenzar la de otro |
| Residente | Quien reportó las incidencias, con sesión abierta en otro dispositivo |
| Administrador | Con sesión abierta en otro dispositivo |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/start_attention_test.dart
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-538 | T 3.5.2 | Incidencia de otro técnico o sin técnico; técnico sin datos, con otro rol, deshabilitado o suspendido; suspensión ya terminada | Solo el técnico asignado con la cuenta activa puede comenzarla; una suspensión vencida no lo impide |
| PU-539 | T 3.5.3 | Incidencia En proceso, Resuelta, Rechazada o Pendiente | Ninguna se puede comenzar; cada caso tiene su mensaje y el de En proceso dice que no puede volver a iniciarse |
| PU-540 | T 3.5.2 | Técnico con la cuenta suspendida | Se niega antes de consultar Firestore |
| PU-541 | T 3.5.4, T 3.5.5 | Comenzar la atención con dos administradores activos y sin poder consultarlos | Pasa a `en_proceso` con la fecha del servidor; se avisa a los dos administradores; si la consulta falla, comienza igual |
| PU-542 | T 3.5.4 | Leer una incidencia En proceso de Firestore | Se obtiene la fecha de inicio de la atención |
| PU-543 | T 3.5.5 | Incidencia En proceso en las pantallas del técnico, del residente y del administrador | Las tres muestran "En atención desde…" o "Inicio de la atención"; mientras está Asignada, la llegada estimada |
| PU-544 | T 3.5.1, T 3.5.4 | Lista con una Asignada y una En proceso; comenzar la Asignada | El botón solo aparece en la Asignada; se pide confirmación, se guarda y el botón desaparece al cambiar el estado |
| PU-545 | T 3.5.1, T 3.5.3 | La atención ya había comenzado desde otro dispositivo | Se muestra el mensaje y no se guarda nada |

Las pruebas de la HU 3.4 (PU-528 a PU-537) siguen cubriendo la opción en el detalle.

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Desde la lista | En una incidencia Asignada, tocar "Comenzar atención" en su tarjeta y confirmar | Pasa a En proceso, el botón desaparece y la tarjeta muestra "En atención desde…" |
| PM-02 | Otro técnico | Cambiar en Firestore el `tecnicoId` de una incidencia abierta en la lista y tocar "Comenzar atención" | Se muestra "Esta incidencia no está asignada a ti." |
| PM-03 | Cuenta suspendida | Suspender al técnico desde el administrador y tocar "Comenzar atención" | Se muestra que su cuenta no está activa y no cambia el estado |
| PM-04 | Se guarda | Revisar la incidencia en Firestore | `estado` es `en_proceso` y hay `fechaInicioAtencion` |
| PM-05 | Se refleja en el sistema | Revisar el historial y el detalle del residente, y el historial del administrador | Muestran En proceso y el inicio de la atención; el residente y los administradores tienen el aviso en `notificaciones` |
| PM-06 | No se repite | Comenzar la misma incidencia desde dos dispositivos casi al mismo tiempo | Solo uno lo logra; el otro ve que no puede volver a iniciarse |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-06 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.5 (PU-538 a PU-545) | 8 | Aprobadas |
| Proyecto completo (`flutter test`) | 251 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
