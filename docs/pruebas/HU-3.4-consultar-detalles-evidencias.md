# Plan de pruebas — HU 3.4 Consultar detalles y evidencias de una incidencia

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.4 Consultar detalles y evidencias de una incidencia (#221) |
| Tarea | T 3.4.7 Probar la consulta de detalles y evidencias (#228) |
| Rama | `feature/HU-3.4-Consultar-detalles-y-evidencias-de-una-incidencia` |
| Fecha | 08/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda abrir una incidencia asignada y consultar su información general, las evidencias del residente, la ubicación y los datos del residente, y que mientras la incidencia esté Asignada tenga disponible la opción Comenzar atención.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.4.1 | Pantalla de detalle: una columna en el teléfono y dos en pantallas anchas |
| T 3.4.2 | Detalle de la incidencia seleccionada: se muestra de inmediato con los datos de la lista, se actualiza en tiempo real y se puede reintentar tras un error |
| T 3.4.3 | Número de reporte, título, tipo, descripción, estado, fecha de creación y hora estimada de llegada con el tiempo que falta |
| T 3.4.4 | Fotos y videos adjuntados por el residente, con cuántos hay de cada uno |
| T 3.4.5 | Lugar, tipo de vivienda, edificio y número; nombre, teléfono (con opción de copiarlo) y correo del residente |
| T 3.4.6 | Opción Comenzar atención: confirmación, cambio de Asignada a En proceso y aviso al residente |

**No incluye**

- Registrar la solución y marcar la incidencia como Resuelta (otra HU).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.4 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede abrir una incidencia asignada para consultar sus detalles | PU-532, PU-537, PM-01, PM-02 |
| CA-2 | Se muestra el número de reporte, título, tipo y descripción | PU-533, PM-03 |
| CA-3 | El técnico puede consultar las fotografías, videos u otras evidencias del residente | PU-531, PU-534, PM-04 |
| CA-4 | Se muestra el estado, la fecha de creación y la hora estimada de llegada | PU-531, PU-532, PU-533, PM-03 |
| CA-5 | Se muestra la información del residente y el departamento o lugar | PU-535, PM-05 |
| CA-6 | Cuando la incidencia está Asignada, el técnico tiene disponible la opción Comenzar atención | PU-528, PU-529, PU-530, PU-536, PU-537, PM-06, PM-07 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas de la pantalla usan un reloj fijo: lunes 9 de noviembre de 2026, 9:00, con la llegada estimada a las 10:30.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnico | Técnico activo con una incidencia Asignada y otra En proceso |
| Incidencias | Una con fotos y un video, otra sin evidencias; una en un departamento de torre y otra en una casa |
| Residente | Con teléfono y correo registrados |
| Otro técnico | Con una incidencia asignada, para comprobar que no se puede abrir ni comenzar |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/assigned_incident_detail_data_test.dart test/unitarias/technician/assigned_incident_detail_test.dart
```

### 7.1 Reglas y cálculos — `assigned_incident_detail_data_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-528 | T 3.4.6 | Comenzar una incidencia Asignada, de otro técnico, ya En proceso, Pendiente, Resuelta o Rechazada | Solo la Asignada del técnico se puede comenzar; pasa a `en_proceso` con la fecha del servidor; el aviso al residente dice "Juan Pérez comenzó a atender…" |
| PU-529 | T 3.4.6 | El repositorio guarda el inicio y recibe errores | Se envían la incidencia y el técnico; cada error se traduce a su mensaje |
| PU-530 | T 3.4.6 | Un residente intenta comenzar la atención | Se niega y no se guarda nada; el técnico sí puede |
| PU-531 | T 3.4.3, T 3.4.4 | Tiempo para la llegada y resumen de evidencias | "Faltan 45 min", "Faltan 2 h 15 min", "Faltan 1 d 3 h", "La hora estimada pasó hace 30 min"; "1 foto", "2 fotos · 1 video", "2 videos" |

### 7.2 Pantalla de detalle — `assigned_incident_detail_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-532 | T 3.4.2 | Abrir la incidencia desde la lista y cambiar su estado en Firestore | Se muestra sin indicador de carga y se actualiza sola |
| PU-533 | T 3.4.1, T 3.4.3 | Información general | Número, título, tipo, descripción, estado, fecha de creación, hora estimada y "Faltan 1 h 30 min" |
| PU-534 | T 3.4.4 | Incidencia con dos fotos y un video | "2 fotos · 1 video" y las miniaturas, el video con su ícono de reproducción |
| PU-535 | T 3.4.5 | Departamento en torre y casa; copiar el teléfono | Lugar, tipo, edificio, número, nombre, teléfono y correo; el teléfono se copia; la casa no muestra edificio |
| PU-536 | T 3.4.6 | Cancelar y confirmar Comenzar atención | Cancelar no guarda nada; al confirmar se guarda, se avisa y la opción desaparece cuando la incidencia queda En proceso |
| PU-537 | T 3.4.2, T 3.4.6 | La atención ya había comenzado; falla la carga; la incidencia pasa a otro técnico | Se muestra cada mensaje; "Reintentar" vuelve a consultar; si es de otro técnico no se puede reintentar |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el detalle | Como técnico, tocar una incidencia de la lista de asignadas | El detalle se abre de inmediato con sus datos |
| PM-02 | Otro técnico | Con el detalle abierto, cambiar en Firestore el `tecnicoId` de la incidencia a otro técnico | Se muestra "Esta incidencia no está asignada a ti." |
| PM-03 | Información general | Revisar el detalle | Número, título, tipo, descripción, estado, fecha de creación, hora estimada y cuánto falta |
| PM-04 | Evidencias | Tocar una foto y un video | Se abren en pantalla completa; el video se reproduce |
| PM-05 | Ubicación y residente | Revisar las secciones y copiar el teléfono | Datos de la vivienda y del residente; el teléfono queda copiado |
| PM-06 | Comenzar atención | En una incidencia Asignada, tocar "Comenzar atención" y confirmar | Pasa a En proceso, la opción desaparece y el residente ve el nuevo estado y recibe el aviso en `notificaciones` |
| PM-07 | Sin la opción | Abrir una incidencia En proceso | No aparece "Comenzar atención" |
| PM-08 | Diseño | Abrir el detalle en el teléfono y en la PC | En el teléfono una columna; en la PC dos columnas |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 08/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.4 (PU-528 a PU-537) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 243 | Aprobadas |

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
