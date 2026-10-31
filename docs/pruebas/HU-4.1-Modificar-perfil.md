# Plan de pruebas — HU 4.2 Modificar perfil (administrador)

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.2 Modificar perfil (#HU-4.2) |
| Rama | `FEATURE/HU-4.2-Nueva-funcionalidad` |
| Fecha | 30/10/2026 |

## 1. Objetivo

Verificar que el administrador pueda modificar su información personal y de contacto (nombre, correo electrónico y teléfono) desde su perfil, que el sistema valide formatos y duplicados de correo, que solo el administrador tenga acceso a la edición, y que existan ventanas de confirmación al guardar o cancelar con cambios pendientes.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Modificar perfil" desde la consulta del perfil del administrador |
| Edición | Nombre, correo electrónico y teléfono editables |
| Validación | Formato de correo, longitud/formato de teléfono, nombre |
| Duplicado | Nuevo correo no registrado por otro usuario |
| Confirmaciones | Guardar con cambios, cancelar con cambios, cancelar sin cambios |
| Persistencia | Guardado en `usuarios/{uid}` y actualización de la sesión |
| Restricción | Solo el administrador puede acceder a la edición |

**No incluye**

- Modificación de la vivienda asignada (solo lectura).
- Gestión de perfiles de otros usuarios (HU 4.5).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.2 | Pruebas |
|---|---|---|
| CA-1 | Acceder a la opción de modificar perfil desde la consulta del propio perfil | PM-01 |
| CA-2 | Modificar únicamente nombre, correo y teléfono | PU-54, PU-56, PM-02 |
| CA-3 | Si se edita el correo, validar que no esté registrado por otro usuario | PM-08 |
| CA-4 | Validar formatos de correo y teléfono antes de guardar | PU-55, PU-59, PU-60, PM-03, PM-04 |
| CA-5 | Con información válida, guardar las modificaciones en la base de datos | PU-56, PM-05 |
| CA-6 | Después de guardar, mostrar mensaje de éxito y reflejar la información actualizada | PU-56, PM-05, PM-06 |
| CA-7 | Con datos inválidos o duplicados, informar con mensaje de error y no guardar | PU-55, PU-57, PU-58, PM-03, PM-04, PM-07, PM-08 |
| CA-8 | Solo el administrador puede acceder a la edición | PM-09 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/resident/`, `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias reutilizan `EditProfileViewModel`, `FakeProfileRepository`, `FakeHousingRepository` y `FakeAuthRepository`. La edición de perfil es compartida, pero solo se expone al administrador mediante `adminEditProfile`.

## 5. Entorno

- Flutter 3.47.8 / Dart 3.13.7
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`, Firestore con reglas de desarrollo

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario con rol `admin` y estado de cuenta `activa` |
| Correo actual | `admin@correo.com` |
| Nombre actual | `Admin Prueba` |
| Teléfono actual | `7771234567` |
| Correo válido nuevo | `admin.nuevo@correo.com` |
| Teléfono válido nuevo | `5559876543` |
| Correo ya registrado | `maria@correo.com` (residente) |
| Nombre inválido | vacío, `Al`, `Admin 123` |
| Teléfono inválido | vacío, `777123456`, `77712345678` |
| Correo inválido | `admin`, `admin@`, `@correo.com` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias
```

### 7.1 Formulario y guardado — `edit_profile_view_model_test.dart`

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-52 | Carga de datos | Abrir el formulario | Nombre, teléfono y correo actuales; vivienda según asignación |
| PU-53 | Vivienda no disponible | La vivienda no se puede consultar | La vivienda muestra "No disponible" |
| PU-54 | Detección de cambios | Editar campos | Solo hay cambios si el nombre, correo o teléfono son distintos (sin contar espacios) |
| PU-55 | Datos inválidos | Guardar con datos inválidos | Devuelve el mensaje de error, no llama a Firestore y la sesión no cambia |
| PU-56 | Guardado válido | Guardar datos válidos | Guarda el nombre sin espacios de más, el correo normalizado y el teléfono; el perfil muestra los datos nuevos y la vivienda se conserva |
| PU-57 | Fallo de guardado | Falla el guardado | Mensaje de error, deja de cargar y el perfil no cambia |

### 7.2 Errores de Firestore — `profile_repository_impl_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-58 | `unavailable`, `permission-denied`, `not-found` y otro código | Sin conexión, sin permiso, perfil no encontrado y error genérico, cada uno con su mensaje |

### 7.3 Validaciones — `profile_validators_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-59 | Nombre vacío, corto, de más de 80 caracteres o con números o símbolos | Mensajes correspondientes; nombres con acentos, apóstrofo o guion son válidos |
| PU-60 | Teléfono vacío, con 9 u 11 dígitos o con guiones | "Ingresa tu teléfono" o "El teléfono debe tener 10 dígitos"; 10 dígitos son válidos |

### 7.4 Validación de correo duplicado (back)

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-61 | Correo ya registrado por otro usuario | Lanza `ProfileFailure` con mensaje "El correo electrónico ya está registrado por otro usuario." y no actualiza el documento |
| PU-62 | Correo igual al actual del mismo usuario | Permite guardar (no se considera duplicado) |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | En "Mi perfil" (administrador) pulsar "Modificar perfil" | Abre el formulario con nombre, correo y teléfono actuales, sin barra azul superior |
| PM-02 | Campos editables | Revisar los campos del formulario | Nombre, correo y teléfono son editables; la vivienda (si existe) se muestra como solo lectura con candado |
| PM-03 | Nombre inválido | Borrar el nombre; luego escribir `Admin 123` | "Ingresa tu nombre" y "El nombre solo puede tener letras"; no se guarda |
| PM-04 | Teléfono inválido | Escribir `777123456` y pulsar "Guardar cambios" | "El teléfono debe tener 10 dígitos"; no se guarda. El campo no acepta letras ni más de 10 dígitos |
| PM-05 | Correo inválido | Escribir `admin@` y pulsar "Guardar cambios" | "Correo no válido"; no se guarda |
| PM-06 | Guardar cambios | Cambiar nombre, correo y teléfono por datos válidos y guardar | Aparece diálogo "Guardar cambios" → "¿Deseas guardar los cambios realizados?" (Cancelar/Guardar). Al confirmar guarda, muestra "Tu perfil se actualizó correctamente" y regresa al perfil con los datos nuevos; el documento en Firestore cambia |
| PM-07 | Cancelar con cambios | Modificar un campo y pulsar "Cancelar" | Aparece diálogo "Descartar cambios" → "Tienes cambios sin guardar. ¿Deseas descartarlos y salir?" (Cancelar/Descartar). Si descarta, no aplica cambios y regresa al perfil; si cancela, permanece en el formulario con el cambio |
| PM-08 | Correo duplicado | Cambiar el correo a uno ya registrado por otro usuario y guardar | Mensaje "El correo electrónico ya está registrado por otro usuario."; no se guarda |
| PM-09 | Solo administrador | Iniciar sesión como residente o técnico e intentar acceder a la edición | No se puede acceder; la ruta redirige o muestra "No disponible para este rol" |
| PM-10 | Cancelar sin cambios | Abrir el formulario sin modificar nada y pulsar "Cancelar" o la flecha atrás | Regresa al perfil inmediatamente, sin diálogo |
| PM-11 | Botón sin cambios | Abrir el formulario sin modificar nada | "Guardar cambios" está deshabilitado |
| PM-12 | Persistencia | Después de PM-06 cerrar y volver a abrir la app | El perfil conserva los datos nuevos |
| PM-13 | Sin internet | Activar modo avión, cambiar el teléfono y guardar | Mensaje de error y sigue en el formulario |
| PM-14 | Confirmación guardar cancelada | Modificar un campo, pulsar "Guardar cambios" y en el diálogo pulsar "Cancelar" | Permanece en el formulario con los cambios sin guardar |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 30/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.2 (reutiliza PU-52 a PU-60) | 9 | Aprobadas |
| Proyecto completo (`flutter test`) | 121 | Aprobadas |

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
| PM-10 | Pendiente | | | |
| PM-11 | Pendiente | | | |
| PM-12 | Pendiente | | | |
| PM-13 | Pendiente | | | |
| PM-14 | Pendiente | | | |