# Plan de pruebas — HU 2.3 Registrar incidencia

| Dato | Valor |
|---|---|
| Módulo | 2. Residente |
| Historia de usuario | HU 2.3 Registrar incidencia (#38) |
| Tarea | T 2.3.10 Probar el registro, las validaciones y la consulta posterior (#64) |
| Rama | `feature/HU-2.3-registrar-incidencia` |
| Fecha | 20/10/2026 |

## 1. Objetivo

Verificar que el residente pueda registrar una incidencia con título, tipo, descripción y evidencias, y que el sistema valide los campos obligatorios. También se verifica que asigne un número de reporte único, que asocie la incidencia a la vivienda del residente con estado Pendiente, que avise al administrador y que permita consultar la incidencia creada.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 2.3.2 | Lectura y escritura de la incidencia en `incidencias` |
| T 2.3.3 | Captura de título, tipo y descripción |
| T 2.3.4 | Selección de fotos y videos, límites de cantidad y tamaño, y carga en Cloudinary |
| T 2.3.5 | Validación de los campos obligatorios |
| T 2.3.6 | Folio consecutivo y único (`INC-0001`, `INC-0002`, …) |
| T 2.3.7 | Asociación a la vivienda del residente autenticado |
| T 2.3.8 | Guardado con estado `pendiente` |
| T 2.3.9 | Aviso en `notificaciones` para cada administrador activo |

**No incluye**

- Diseño visual del formulario (T 2.3.1): se revisa en las pruebas manuales.
- Pantalla de detalle de la incidencia (HU 2.4). Por ahora, "Ver incidencia" abre la pantalla provisional con el ID.
- Pantalla de notificaciones del administrador: aquí solo se verifica que el aviso se guarde en Firestore.
- Reglas de seguridad por rol: `firestore.rules` es de desarrollo.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 2.3 | Pruebas |
|---|---|---|
| CA-1 | Acceder a la opción para crear una incidencia | PM-01 |
| CA-2 | Ingresar un título | PU-70, PU-75, PM-02 |
| CA-3 | Seleccionar el tipo de incidencia | PU-70, PM-02 |
| CA-4 | Tipos mínimos: Luz, Agua, Estructura y Otros | PU-61, PU-63, PM-01 |
| CA-5 | Ingresar una descripción detallada | PU-70, PU-76, PM-02 |
| CA-6 | Adjuntar fotografías y videos | PU-71, PU-72, PU-73, PU-77, PU-78, PM-03, PM-04 |
| CA-7 | Validar los campos obligatorios antes de registrar | PU-70, PU-75, PU-76, PM-02 |
| CA-8 | Generar un número único de reporte | PU-64, PU-65, PM-05, PM-06 |
| CA-9 | Asociar a la vivienda del residente | PU-64, PU-67, PU-69, PM-05, PM-08 |
| CA-10 | Estado inicial Pendiente | PU-62, PU-64, PM-05 |
| CA-11 | Consultar la incidencia después de registrarla | PM-05 |
| CA-12 | Notificar al administrador | PU-66, PM-07 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/incidents/` y `test/unitarias/resident/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Los fakes están en `test/unitarias/incidents/fakes.dart`. Simulan el contador de folios, la carga de evidencias, los avisos al administrador, la cámara y la galería. La carga en Cloudinary se prueba con el `MockClient` del paquete `http`.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador con cámara virtual o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark) con Firestore y reglas de desarrollo
- Cloudinary: cuenta con un *upload preset* sin firma configurado en `lib/core/constants/cloudinary_config.dart`. El plan Spark no incluye Firebase Storage

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente | Usuario `residente` activo con `viviendaId` de una vivienda existente |
| Residente sin vivienda | Usuario `residente` activo sin `viviendaId` |
| Administrador | Al menos un usuario `admin` con `estadoCuenta: activa` |
| Título válido | `Fuga en baño` |
| Descripción válida | `Gotea la llave del lavabo` |
| Evidencias | 1 o 2 fotos y un video corto (menos de 1 minuto) |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/incidents test/unitarias/resident/register_incident_view_model_test.dart
```

### 7.1 Estructura de datos (T 2.3.2) — `incident_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-61 | Leer un documento de `incidencias` | Lee folio, tipo, estado, vivienda, evidencias y fecha; el número de reporte es `INC-0007` |
| PU-62 | Escribir una incidencia nueva | `estado: pendiente`, sin técnico ni hora estimada y con fecha del servidor |
| PU-63 | Tipo `gas` o estado `abierta` | Se rechaza el documento |

### 7.2 Validaciones (T 2.3.5) — `incident_validators_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-75 | Título vacío, de menos de 5 o de más de 80 caracteres | "Ingresa un título", "El título debe tener al menos 5 caracteres" o "El título no debe pasar de 80 caracteres" |
| PU-76 | Descripción vacía, de menos de 10 o de más de 500 caracteres | "Describe el problema", "La descripción debe tener al menos 10 caracteres" o "La descripción no debe pasar de 500 caracteres" |

### 7.3 Carga de evidencias (T 2.3.4) — `evidence_storage_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-77 | Subir una foto y un video | Se envían a `/image/upload` y `/video/upload` de Cloudinary y se devuelven sus URLs en orden |
| PU-78 | Cloudinary rechaza el archivo o no hay conexión | Se lanza un error de carga; si es por la red, se indica que fue por la conexión |

### 7.4 Registro (T 2.3.6 a T 2.3.9) — `register_incident_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-64 | Registrar con datos válidos | Folio siguiente (`INC-0007`), estado pendiente, vivienda y UID del residente, textos sin espacios de más y URLs de las evidencias |
| PU-65 | Registrar dos incidencias | Folios consecutivos y documentos distintos |
| PU-66 | Registrar con dos administradores activos | Se genera un aviso para los dos con el ID y el título de la incidencia |
| PU-67 | Residente sin vivienda o usuario técnico | "No tienes una vivienda asignada…" o "Solo los residentes…"; no se guarda nada |
| PU-68 | Falla la subida de evidencias o no hay internet | "No se pudieron subir las evidencias…" o "No hay conexión…"; no se guarda la incidencia ni el aviso |

### 7.5 Formulario — `register_incident_view_model_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-69 | T 2.3.7 | Abrir el formulario | Muestra la vivienda "Torre A – 4B" |
| PU-70 | T 2.3.5 | Registrar sin título, tipo o descripción | Indica el error de cada campo y no registra |
| PU-71 | T 2.3.4 | Agregar fotos y videos | Se agregan hasta 5; después avisa del límite. Se pueden quitar |
| PU-72 | T 2.3.4 | Video de 60 MB | No se agrega y avisa el límite de tamaño |
| PU-73 | T 2.3.8 | Registrar con datos válidos | Devuelve la incidencia pendiente con su número de reporte y las evidencias |
| PU-74 | T 2.3.8 | Falla el registro | Muestra el mensaje de error y deja de cargar |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | En Inicio pulsar "Registrar incidencia" | Formulario con título, los tipos Luz, Agua, Estructura y Otros, descripción, evidencias y la vivienda con candado |
| PM-02 | Campos obligatorios | Pulsar "Registrar incidencia" sin llenar nada | Errores en título, tipo y descripción; no se registra |
| PM-03 | Adjuntar fotos | "Agregar evidencia" → tomar una foto y elegir otra de la galería | Aparecen las miniaturas y se pueden quitar con la X |
| PM-04 | Adjuntar video | "Agregar evidencia" → grabar un video | Aparece con ícono de reproducir; la grabación se corta al minuto |
| PM-05 | Registro exitoso | Llenar todo con datos válidos y registrar | Diálogo "Incidencia registrada" con su número (`INC-…`) y estado Pendiente; "Ver incidencia" abre la incidencia. En Firestore: documento con `estado: pendiente`, la `viviendaId` del residente y las URLs en `evidenciasAntes`; archivos en Cloudinary, en la carpeta `fixo/incidencias/{id}/antes` |
| PM-06 | Número único | Registrar otra incidencia | El número de reporte aumenta en uno y `contadores/incidencias.ultimoFolio` se actualiza |
| PM-07 | Aviso al administrador | Después de PM-05 revisar `notificaciones` | Un documento por administrador activo con `tipo: nueva_incidencia` y `refId` igual al ID de la incidencia |
| PM-08 | Residente sin vivienda | Iniciar sesión con el residente sin vivienda y abrir el formulario | Muestra "Sin vivienda asignada" y el botón de registrar está deshabilitado |
| PM-09 | Sin internet | Activar modo avión y registrar | Mensaje de error y sigue en el formulario con los datos |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-07 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 20/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 2.3 (PU-61 a PU-78) | 18 | Aprobadas |
| Proyecto completo (`flutter test`) | 72 | Aprobadas |

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
