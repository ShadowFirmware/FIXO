# Plan de pruebas — HU 3.7 Finalizar una incidencia como resuelta

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.7 Finalizar una incidencia como resuelta (#246) |
| Tarea | T 3.7.8 Probar la finalización de incidencias (#266) |
| Rama | `feature/HU-3.7-Finalizar-una-incidencia-como-resuelta` |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda finalizar como resuelta una incidencia propia que esté En proceso y tenga la solución registrada, siempre con confirmación previa. Al finalizarla, la incidencia debe pasar a Resuelta con la fecha de resolución y su chat debe cerrarse. El residente debe recibir el aviso y el técnico debe quedar Disponible. Además, la incidencia debe salir de las asignadas y pasar al historial de incidencias atendidas.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.7.1 | Opción "Finalizar incidencia" en el detalle, cuando la solución ya está registrada. Registrar la solución (HU 3.6) ya no marca la incidencia como Resuelta |
| T 3.7.2 | Condiciones: incidencia propia, En proceso, con la solución registrada, y técnico con la cuenta activa |
| T 3.7.3 | Confirmación antes de finalizar |
| T 3.7.4 | Cambio de En proceso a Resuelta, cierre del chat (`chatCerrado`) y aviso al residente y a los administradores |
| T 3.7.5 | Fecha de resolución (`fechaResolucion`) que pone el servidor |
| T 3.7.6 | El técnico vuelve a estar Disponible (`disponible: true`) |
| T 3.7.7 | La incidencia sale de las asignadas y aparece en "Incidencias atendidas"; el detalle regresa a la lista |

**No incluye**

- El chat de la incidencia (HU 5.1): esta HU solo guarda que el chat queda cerrado.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.7 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede finalizar únicamente las incidencias que tiene asignadas | PU-558, PU-559, PU-561, PM-02 |
| CA-2 | La incidencia debe encontrarse en estado En proceso | PU-558, PU-559, PM-03 |
| CA-3 | Para finalizar la incidencia, debe existir una solución registrada | PU-558, PU-559, PU-563, PM-01 |
| CA-4 | Al confirmar la finalización, el estado cambia de En proceso a Resuelta | PU-559, PU-563, PU-564, PM-04 |
| CA-5 | El sistema registra la fecha de resolución de la incidencia | PU-559, PM-05 |
| CA-6 | El residente recibe una notificación indicando que su incidencia fue resuelta y puede consultar las evidencias de la solución | PU-559, PU-560, PM-06 |
| CA-7 | El técnico cambia automáticamente a estado Disponible | PU-559, PM-07 |
| CA-8 | El chat asociado a la incidencia se cierra al finalizar la atención | PU-559, PU-562, PM-05 |
| CA-9 | La incidencia deja de aparecer entre las asignadas y pasa al historial de incidencias atendidas | PU-563, PU-565, PM-08 |

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
| Técnico | Técnico activo, marcado como No disponible, con una incidencia En proceso con la solución registrada y otra sin solución |
| Residente y administrador | Con sesión abierta en otros dispositivos |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/finalize_incident_test.dart
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-558 | T 3.7.2 | Incidencia propia con y sin solución, de otro técnico, sin sesión, Resuelta, Pendiente, Asignada o Rechazada | Solo la propia En proceso con solución se puede finalizar; cada caso tiene su mensaje |
| PU-559 | T 3.7.2, T 3.7.4 a T 3.7.6 | Reglas de la transacción y cambios que se guardan | Se rechazan los casos inválidos (incluido el técnico suspendido). Se guardan `resuelta`, `fechaResolucion` del servidor y `chatCerrado`; el técnico queda `disponible`. El aviso dice que se resolvió e invita a consultar la solución y las evidencias |
| PU-560 | T 3.7.4 | Finalizar con dos administradores, sin poder consultarlos y con errores | Se avisa a los administradores; si la consulta falla, se finaliza igual; cada error tiene su mensaje |
| PU-561 | T 3.7.2 | Un residente o un técnico suspendido intentan finalizar | Se niega antes de consultar Firestore; el técnico activo sí puede |
| PU-562 | T 3.7.4 | Leer una incidencia con `fechaSolucion` y `chatCerrado` | Se obtienen ambos datos; sin el campo, el chat está abierto |
| PU-563 | T 3.7.1, T 3.7.3, T 3.7.7 | Detalle sin solución y con solución; cancelar y confirmar | Sin solución solo aparece "Registrar solución"; con solución se ve y aparece "Finalizar incidencia"; cancelar no hace nada; al confirmar muestra "Finalizando…", finaliza y vuelve a la lista |
| PU-564 | T 3.7.3 | La incidencia ya se había finalizado desde otro dispositivo | Se muestra el mensaje y se queda en el detalle |
| PU-565 | T 3.7.7 | La incidencia pasa de En proceso con solución a Resuelta | Primero sigue en las asignadas con "Solución registrada: falta finalizar la incidencia"; después pasa a las atendidas |

Las pruebas de la HU 3.6 (PU-546 a PU-557) se actualizaron: registrar la solución ya no cambia el estado.

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Sin solución | Abrir una incidencia En proceso sin solución | Solo aparece "Registrar solución"; después de registrarla aparece "Finalizar incidencia" |
| PM-02 | Otra incidencia | Cambiar en Firestore el `tecnicoId` y tocar "Finalizar incidencia" | Se muestra "Esta incidencia no está asignada a ti." |
| PM-03 | Estado | Abrir una incidencia Asignada | No aparece "Finalizar incidencia" |
| PM-04 | Finalizar | Tocar "Finalizar incidencia", revisar el mensaje y confirmar | Pasa a Resuelta y regresa a la lista |
| PM-05 | Datos guardados | Revisar la incidencia en Firestore | `estado` es `resuelta`, con `fechaResolucion` y `chatCerrado: true` |
| PM-06 | Aviso al residente | Revisar `notificaciones` y el detalle del residente | Tiene el aviso "Incidencia … resuelta" y ve la solución con sus evidencias |
| PM-07 | Disponibilidad | Revisar el técnico en Firestore y en la asignación del administrador | Tiene `disponible: true` y aparece entre los técnicos disponibles para asignar |
| PM-08 | Listas | Revisar Inicio e Historial del técnico | La incidencia ya no está en Inicio y aparece en "Incidencias atendidas" |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.7 (PU-558 a PU-565) | 8 | Aprobadas |
| Proyecto completo (`flutter test`) | 271 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-08 | Aprobada | 09/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
