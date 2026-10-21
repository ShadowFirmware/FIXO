# Plan de pruebas — HU 2.2 Modificar perfil

| Dato | Valor |
|---|---|
| Módulo | 2. Residente |
| Historia de usuario | HU 2.2 Modificar perfil (#37) |
| Tarea | T 2.2.7 Actualizar la información y probar (#54) |
| Rama | `feature/HU-2.2-modificar-perfil` |
| Fecha | 20/10/2026 |

## 1. Objetivo

Verificar que el residente pueda modificar su nombre y teléfono desde su perfil, que la vivienda asignada se muestre solo como lectura, que no se guarden datos inválidos y que, después de guardar, el perfil muestre la información actualizada.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 2.2.2 | Carga de los datos actuales en el formulario |
| T 2.2.3 | Detección de cambios en nombre y teléfono |
| T 2.2.4 | Vivienda asignada como campo de solo lectura |
| T 2.2.5 | Validación del nombre y del teléfono |
| T 2.2.6 | Guardado en `usuarios/{uid}` y mensajes de error |
| T 2.2.7 | Actualización del perfil mostrado después de guardar |

**No incluye**

- Diseño visual del formulario (T 2.2.1): se revisa en las pruebas manuales.
- Cambio de vivienda por el administrador (módulo de administración).
- Reglas de seguridad de Firestore: las reglas actuales son de desarrollo y permiten al usuario escribir cualquier campo. Antes de la entrega hay que limitar al residente a `nombre` y `telefono` de su propio documento.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 2.2 | Pruebas |
|---|---|---|
| CA-1 | Acceder a modificar perfil desde la consulta del perfil | PM-01 |
| CA-2 | Solo se pueden modificar nombre y teléfono | PU-54, PU-56, PM-02 |
| CA-3 | La vivienda se muestra como solo lectura | PU-52, PU-53, PM-02 |
| CA-4 | Solo un administrador puede cambiar la vivienda | PU-56, PM-02 |
| CA-5 | Se validan los campos antes de guardar | PU-55, PU-59, PU-60, PM-03, PM-04 |
| CA-6 | Con datos válidos se guardan los cambios | PU-56, PM-05 |
| CA-7 | Después de guardar se muestra la información actualizada | PU-56, PM-05, PM-06 |
| CA-8 | Con datos inválidos se informa al residente y no se guarda | PU-55, PU-57, PU-58, PM-03, PM-04, PM-07 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/resident/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias usan `FakeProfileRepository` (`test/unitarias/resident/fakes.dart`), `FakeHousingRepository` y `FakeAuthRepository` en lugar de Firebase.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`, Firestore con reglas de desarrollo

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente | Usuario `residente` activo, con `viviendaId` de una vivienda existente |
| Vivienda | Documento en `viviendas` con `edificio` y `numero` (por ejemplo, Torre A – 4B) |
| Nombre válido | `María José Núñez` |
| Teléfono válido | `7779998877` |
| Nombre inválido | vacío, `Al`, `María 123` |
| Teléfono inválido | vacío, `777111223` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/resident
```

### 7.1 Formulario y guardado — `edit_profile_view_model_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-52 | T 2.2.2, T 2.2.4 | Abrir el formulario | Nombre, teléfono y correo actuales; vivienda "Torre A – 4B" |
| PU-53 | T 2.2.4 | La vivienda no se puede consultar | La vivienda muestra "No disponible" |
| PU-54 | T 2.2.3 | Editar campos | Solo hay cambios si el nombre o el teléfono son distintos (sin contar espacios) |
| PU-55 | T 2.2.5 | Guardar con datos inválidos | Devuelve el mensaje de error, no llama a Firestore y la sesión no cambia |
| PU-56 | T 2.2.6, T 2.2.7 | Guardar datos válidos | Guarda el nombre sin espacios de más y el teléfono; el perfil muestra los datos nuevos y la vivienda se conserva |
| PU-57 | T 2.2.6 | Falla el guardado | Mensaje de error, deja de cargar y el perfil no cambia |

### 7.2 Errores de Firestore (T 2.2.6) — `profile_repository_impl_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-58 | `unavailable`, `permission-denied`, `not-found` y otro código | Sin conexión, sin permiso, perfil no encontrado y error genérico, cada uno con su mensaje |

### 7.3 Validaciones (T 2.2.5) — `profile_validators_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-59 | Nombre vacío, corto, de más de 80 caracteres o con números o símbolos | "Ingresa tu nombre", "El nombre es demasiado corto", "El nombre no debe pasar de 80 caracteres" o "El nombre solo puede tener letras"; los nombres con acentos, apóstrofo o guion son válidos |
| PU-60 | Teléfono vacío, con 9 u 11 dígitos o con guiones | "Ingresa tu teléfono" o "El teléfono debe tener 10 dígitos"; 10 dígitos son válidos |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | En Perfil pulsar "Modificar perfil" | Abre el formulario con el nombre y el teléfono actuales |
| PM-02 | Campos de solo lectura | Revisar el correo y la vivienda | Tienen candado, no se pueden editar y se muestra la nota de que solo el administrador cambia la vivienda |
| PM-03 | Nombre inválido | Borrar el nombre; luego escribir `María 123` | "Ingresa tu nombre" y "El nombre solo puede tener letras"; no se guarda |
| PM-04 | Teléfono inválido | Escribir `777111223` y pulsar "Guardar cambios" | "El teléfono debe tener 10 dígitos"; no se guarda. El campo no acepta letras ni más de 10 dígitos |
| PM-05 | Guardar cambios | Cambiar nombre y teléfono por datos válidos y guardar | Mensaje "Tu perfil se actualizó correctamente", regresa al perfil con los datos nuevos y el documento en Firestore cambia |
| PM-06 | Persistencia | Después de PM-05 cerrar y volver a abrir la app | El perfil conserva los datos nuevos |
| PM-07 | Sin internet | Activar modo avión, cambiar el teléfono y guardar | Mensaje de error y sigue en el formulario |
| PM-08 | Botón sin cambios | Abrir el formulario sin modificar nada | "Guardar cambios" está deshabilitado |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-06 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 20/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 2.2 (PU-52 a PU-60) | 9 | Aprobadas |
| Proyecto completo (`flutter test`) | 63 | Aprobadas |

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
