# Plan de pruebas — HU 3.6 Registrar la solución y evidencias de una incidencia

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.6 Registrar la solución y evidencias de una incidencia (#236) |
| Tarea | T 3.6.9 Probar el registro de soluciones y evidencias (#245) |
| Rama | `feature/HU-3.6-Registrar-la-solucion-y-evidencias-de-una-incidencia` |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda registrar la solución de una incidencia propia que esté En proceso. Debe poder escribir la descripción, adjuntar fotografías o videos del trabajo y revisar todo antes de guardarlo. El sistema valida que los datos y las evidencias obligatorias estén completos, guarda la solución y las evidencias en la incidencia, y deja esa información disponible para el técnico, el residente y el administrador.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 3.6.1 | Pantalla "Registrar solución", que se abre desde el detalle de una incidencia En proceso |
| T 3.6.2 | Campo de descripción de la solución, de 10 a 500 caracteres |
| T 3.6.3 | Captura de fotos y videos con la cámara o la galería; máximo 5, fotos de hasta 10 MB y videos de hasta 50 MB |
| T 3.6.4 | Vista previa de la descripción y las evidencias, que se abren en pantalla completa; opción de corregir |
| T 3.6.5 | Descripción y al menos una evidencia obligatorias |
| T 3.6.6 | Solo se registra la solución de una incidencia propia En proceso; mensajes si sigue Asignada, ya está Resuelta o fue rechazada |
| T 3.6.7 | Subida de las evidencias a Cloudinary (`…/despues`). En una transacción, la incidencia pasa a Resuelta con la solución, el técnico vuelve a estar Disponible y se avisa al residente y a los administradores |
| T 3.6.8 | Consulta de la solución: historial del técnico con sus incidencias resueltas y la solución con sus evidencias en el detalle |

**No incluye**

- Reglas de seguridad de Firestore (entorno de desarrollo).
- La carga de evidencias desde el navegador web: igual que en el registro de incidencias (HU 2.3), la subida usa la ruta del archivo en el dispositivo.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.6 | Pruebas |
|---|---|---|
| CA-1 | El técnico puede registrar la solución de una incidencia que tiene asignada y se encuentra En proceso | PU-547, PU-552, PU-555, PU-556, PM-01, PM-06 |
| CA-2 | El sistema permite ingresar una descripción de la solución aplicada | PU-546, PU-553, PM-02 |
| CA-3 | El técnico puede adjuntar fotografías o videos como evidencias del trabajo realizado | PU-551, PM-03 |
| CA-4 | El sistema permite revisar la información y las evidencias antes de guardarlas | PU-553, PM-04 |
| CA-5 | El sistema valida que los campos y las evidencias obligatorias estén completos | PU-546, PU-549, PU-553, PM-05 |
| CA-6 | La solución y las evidencias se guardan asociadas a la incidencia correspondiente | PU-547, PU-548, PU-554, PM-07 |
| CA-7 | La información registrada queda disponible para su consulta por el técnico, residente y administrador | PU-550, PU-556, PU-557, PM-08 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | Emulador o teléfono Android | — | Proyecto real `fixo-a7763` y Cloudinary |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador con cámara o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo. Evidencias en Cloudinary.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Técnico | Técnico activo con una incidencia En proceso y otra Asignada |
| Evidencias | Dos fotos y un video corto; una foto de más de 10 MB |
| Residente y administrador | Con sesión abierta en otros dispositivos |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician/register_solution_data_test.dart test/unitarias/technician/register_solution_test.dart
```

### 7.1 Reglas y datos — `register_solution_data_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-546 | T 3.6.2, T 3.6.5 | Descripción vacía, corta, demasiado larga y válida | Un mensaje para cada caso; la válida pasa |
| PU-547 | T 3.6.6, T 3.6.7 | Incidencia de otro técnico, técnico deshabilitado, incidencia Resuelta, Asignada, Pendiente o Rechazada | Solo se permite la propia En proceso. Se guardan `resuelta`, la solución, las evidencias y la fecha del servidor; el técnico queda Disponible; el aviso resume la solución en 200 caracteres |
| PU-548 | T 3.6.7 | Guardar con dos evidencias; fallan las subidas; Firestore rechaza la solución | Primero se suben las evidencias a `despues` y luego se guarda con sus URLs y se avisa al administrador; si la subida falla no se guarda nada; cada error tiene su mensaje |
| PU-549 | T 3.6.5 | Un residente intenta guardar; descripción corta; sin evidencias; datos completos | Se niega o se pide completar los datos sin subir nada; con los datos completos se guarda la descripción sin espacios sobrantes |
| PU-550 | T 3.6.8 | Incidencias resueltas, en proceso y de otro técnico | El historial solo muestra las resueltas por el técnico, de la más reciente a la más antigua |

### 7.2 ViewModel y pantallas — `register_solution_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-551 | T 3.6.3 | Agregar fotos (una demasiado pesada), un video y más fotos de las permitidas; quitar una | Se rechaza la pesada con su mensaje; no pasan de 5; al quitar una se puede agregar otra |
| PU-552 | T 3.6.6 | Abrir el formulario con incidencias en distintos estados o de otro técnico | Solo la propia En proceso no tiene error |
| PU-553 | T 3.6.1, T 3.6.2, T 3.6.4, T 3.6.5 | Revisar sin datos, completar y revisar, corregir | Muestra los errores; con datos completos aparece la vista previa con la descripción y "Evidencias del trabajo (1)"; al corregir se conserva lo escrito |
| PU-554 | T 3.6.7 | Guardar con un error y luego correctamente | El error se muestra y se queda en la vista previa; después muestra "Guardando…", guarda, avisa y regresa |
| PU-555 | T 3.6.6 | Abrir el formulario de una incidencia Asignada | Muestra "Primero comienza la atención…" en lugar del formulario |
| PU-556 | T 3.6.1, T 3.6.8 | Detalle En proceso y luego Resuelta | En proceso ofrece "Registrar solución"; Resuelta muestra la solución, la fecha y las evidencias del trabajo |
| PU-557 | T 3.6.8 | Historial sin resueltas y con una resuelta | Mensaje informativo; luego la incidencia con "Resuelta el…" |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | En el detalle de una incidencia En proceso, tocar "Registrar solución" | Se abre el formulario con el número y nombre de la incidencia |
| PM-02 | Descripción | Escribir la solución | Se ve el contador de caracteres hasta 500 |
| PM-03 | Evidencias | Tomar una foto, elegir otra de la galería y grabar un video; intentar una foto de más de 10 MB | Aparecen las miniaturas; la pesada se rechaza con su mensaje |
| PM-04 | Vista previa | Tocar "Revisar solución" y abrir cada evidencia | Se ven la descripción y las evidencias; cada una se abre en pantalla completa; "Corregir" regresa al formulario |
| PM-05 | Obligatorios | Tocar "Revisar solución" sin descripción ni evidencias | Se indican los dos datos faltantes |
| PM-06 | Estado | Abrir el detalle de una incidencia Asignada | No aparece "Registrar solución" |
| PM-07 | Guardar | Guardar la solución y revisar Firestore y Cloudinary | La incidencia está `resuelta` con `solucion`, `evidenciasDespues` y `fechaResolucion`; el técnico tiene `disponible: true`; las evidencias están en `fixo/incidencias/{id}/despues`; hay avisos para el residente y los administradores |
| PM-08 | Consulta | Revisar el historial del técnico, el detalle del residente y el historial del administrador | Los tres muestran la solución y las evidencias del trabajo |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.6 (PU-546 a PU-557) | 12 | Aprobadas |
| Proyecto completo (`flutter test`) | 263 | Aprobadas |

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
