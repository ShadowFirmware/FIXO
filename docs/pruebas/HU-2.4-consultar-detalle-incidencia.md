# Plan de pruebas — HU 2.4 Consultar detalles de la incidencia

| Dato | Valor |
|---|---|
| Módulo | 2. Residente |
| Historia de usuario | HU 2.4 Consultar detalles de la incidencia (#39) |
| Tarea | T 2.4.8 Probar los detalles para los diferentes estados de una incidencia (#72) |
| Rama | `feature/HU-2.4-consultar-detalle-incidencia` |
| Fecha | 24/10/2026 |

## 1. Objetivo

Verificar que el residente pueda consultar el detalle de una incidencia de su departamento, con la información que corresponde a cada estado (Pendiente, Asignada, En proceso, Resuelta y Rechazada). También se verifica que la pantalla se actualice cuando cambia la incidencia y que no se muestren incidencias de otro departamento.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 2.4.2 | Obtención de la incidencia por su ID y actualización en tiempo real |
| T 2.4.3 | Número de reporte, título, tipo, descripción, fecha, departamento y evidencias |
| T 2.4.4 | Estado actual con su descripción y avance |
| T 2.4.5 | Datos del técnico y hora estimada de llegada |
| T 2.4.6 | Solución de una incidencia resuelta, y motivo y fecha de una rechazada |
| T 2.4.7 | Bloqueo de incidencias de otro departamento |

**No incluye**

- Diseño visual (T 2.4.1): se revisa en las pruebas manuales.
- Lista para elegir la incidencia (HU 2.5 Historial). Mientras tanto se llega al detalle desde el diálogo de registro (HU 2.3).
- Asignar, rechazar o resolver incidencias (HU 4.9, 4.10 y 3.6). Para estas pruebas los datos se cambian a mano en Firestore.
- Reglas de seguridad de Firestore: siguen siendo de desarrollo. La restricción por departamento se hace en la app (T 2.4.7).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 2.4 | Pruebas |
|---|---|---|
| CA-1 | Seleccionar una incidencia propia para ver su detalle | PM-01 |
| CA-2 | Solo consultar incidencias de su departamento | PU-85, PU-86, PM-08 |
| CA-3 | Mostrar número, nombre, tipo, descripción, evidencias, fecha, estado y departamento | PU-79, PU-89, PM-01, PM-02 |
| CA-4 | El estado corresponde al estado actual | PU-80 a PU-84, PM-03 a PM-07 |
| CA-5 | Asignada o posterior: información del técnico | PU-81, PU-82, PU-84, PM-04, PM-05 |
| CA-6 | Mostrar la hora estimada de llegada cuando exista | PU-81, PM-04 |
| CA-7 | Resuelta: información de la solución | PU-82, PU-88, PM-06 |
| CA-8 | La información se actualiza al cambiar el estado | PU-84, PM-04 a PM-07 |
| CA-9 | Rechazada: comentario y fecha del rechazo | PU-83, PU-88, PM-07 |
| CA-10 | Rechazada: sin técnico ni hora estimada | PU-83, PM-07 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/resident/` y `test/unitarias/incidents/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

`FakeIncidentRepository.changes` simula los cambios que Firestore envía en tiempo real.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo
- Evidencias en Cloudinary

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente A | Residente activo con `viviendaId` = vivienda A |
| Residente B | Residente activo con `viviendaId` = vivienda B |
| Técnico | Usuario `tecnico` activo con `especialidad` |
| Incidencia | Registrada por el residente A con al menos una foto y un video (HU 2.3) |

Para simular los cambios de estado se editan estos campos de la incidencia en la consola de Firestore:

| Estado | Campos |
|---|---|
| Asignada | `estado: asignada`, `tecnicoId`, `horaEstimada` (timestamp) |
| En proceso | `estado: en_proceso` |
| Resuelta | `estado: resuelta`, `solucion` (texto), `fechaResolucion` (timestamp), `evidenciasDespues` (arreglo de URLs, opcional) |
| Rechazada | `estado: rechazada`, `comentarioRechazo` (texto), `fechaRechazo` (timestamp) |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/resident/incident_detail_view_model_test.dart test/unitarias/incidents
```

### 7.1 Detalle por estado — `incident_detail_view_model_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-79 | T 2.4.2, T 2.4.3 | Abrir una incidencia | Número `INC-0007`, título, tipo "Agua", departamento "Torre A – 4B", fecha "20 de octubre de 2026, 9:30 a. m.", descripción y evidencias |
| PU-80 | T 2.4.4 | Pendiente | Estado "Pendiente", sin técnico, hora estimada, solución ni rechazo |
| PU-81 | T 2.4.5 | Asignada | Nombre, teléfono y especialidad del técnico, y hora estimada "21 de octubre de 2026, 4:00 p. m." |
| PU-82 | T 2.4.6 | Resuelta | Solución, fecha de resolución, evidencias de la reparación y técnico |
| PU-83 | T 2.4.6 | Rechazada (con técnico en el documento) | Comentario y fecha del rechazo; no muestra técnico ni hora estimada |
| PU-84 | T 2.4.2 | Cambia de Pendiente a En proceso | La pantalla muestra el nuevo estado y el técnico sin recargar |
| PU-85 | T 2.4.7 | Incidencia de otro departamento | "No tienes permiso para consultar esta incidencia." y no se conserva ningún dato |
| PU-86 | T 2.4.7 | Usuario técnico | Acceso denegado sin consultar Firestore |
| PU-87 | T 2.4.2 | No existe o falla la carga | Estado "no encontrada" o mensaje de error de conexión |

### 7.2 Datos y evidencias — `incident_model_test.dart` y `evidence_gallery_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-88 | T 2.4.6 | Leer `solucion`, `evidenciasDespues`, `fechaResolucion`, `comentarioRechazo` y `fechaRechazo` | Se leen todos los campos |
| PU-89 | T 2.4.3 | URL de foto y de video de Cloudinary | Distingue el video y genera su miniatura `.jpg` |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el detalle | Como residente A, registrar una incidencia y en el diálogo pulsar "Ver incidencia" | Se ve el número de reporte, título, estado Pendiente, tipo, departamento, fecha y descripción |
| PM-02 | Evidencias | Tocar una foto y luego el video | La foto se abre en pantalla completa y se puede acercar; el video se reproduce y se pausa al tocarlo |
| PM-03 | Pendiente | Revisar la incidencia recién creada | Sin sección de técnico, solución ni rechazo |
| PM-04 | Asignada | Con el detalle abierto, cambiar en Firestore a `asignada` con `tecnicoId` y `horaEstimada` | Sin recargar, cambia el estado y aparecen el técnico y la hora estimada |
| PM-05 | En proceso | Cambiar a `en_proceso` | El estado y la barra de avance cambian; el técnico sigue visible |
| PM-06 | Resuelta | Cambiar a `resuelta` con `solucion` y `fechaResolucion` | Aparece la sección "Solución" con la descripción, la fecha y las evidencias posteriores |
| PM-07 | Rechazada | En otra incidencia pendiente, cambiar a `rechazada` con `comentarioRechazo`, `fechaRechazo` y también un `tecnicoId` | Aparece "Motivo del rechazo" con el comentario y la fecha; no aparece el técnico ni la hora estimada |
| PM-08 | Otro departamento | Iniciar sesión como residente B y abrir el detalle de la incidencia del residente A | Candado y "No tienes permiso para consultar esta incidencia." |
| PM-09 | Sin internet | Abrir el detalle en modo avión | Se muestran los datos guardados en caché o un mensaje de error, sin cerrarse la app |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 24/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 2.4 (PU-79 a PU-89) | 11 | Aprobadas |
| Proyecto completo (`flutter test`) | 92 | Aprobadas |

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
