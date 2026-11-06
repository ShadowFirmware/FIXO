# Plan de pruebas — HU 3.2 Modificar perfil

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.2 Modificar perfil |
| Rama | `feature/HU-3.2-modificar-perfil` |
| Fecha | 05/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda modificar su nombre, correo y teléfono desde su perfil, que la especialidad se muestre solo como lectura, que no se guarden datos inválidos y que, después de guardar, el perfil muestre la información actualizada.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Formulario | Carga de los datos actuales y detección de cambios |
| Especialidad | Se muestra con candado y no se puede editar |
| Validación | Formato de nombre, correo y teléfono, y correo ya registrado por otro usuario |
| Guardado | Escritura en `usuarios/{uid}`, mensaje de éxito y perfil actualizado |
| Cambio de correo | Envío del enlace de verificación, correo pendiente en `correoPendiente` y actualización de `correo` al entrar con el correo confirmado |
| Errores | Mensaje claro y permanencia en el formulario si no se guardó |

**No incluye**

- Cambio de especialidad por el administrador (HU 4.5).
- Zona o edificio asignado: la HU lo menciona, pero se decidió no mostrarlo.
- Reglas de seguridad de Firestore: las reglas actuales son de desarrollo y permiten escribir cualquier campo. Antes de la entrega hay que limitar al técnico a `nombre`, `correo`, `correoPendiente` y `telefono` de su propio documento.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.2 | Pruebas |
|---|---|---|
| CA-1 | Acceder a modificar perfil desde la vista del perfil | PU-500, PM-01 |
| CA-2 | Modificar únicamente los datos de contacto y personales permitidos | PU-501, PU-502, PU-507, PM-02 |
| CA-3 | La especialidad se muestra como solo lectura | PU-499, PU-502, PM-02 |
| CA-4 | Solo el administrador puede cambiar la especialidad | PU-502, PU-507, PM-02 |
| CA-5 | Se validan los campos antes de guardar | PU-505, PU-506, PM-03, PM-04, PM-05 |
| CA-6 | Con datos válidos se guardan los cambios | PU-507, PU-510, PU-513, PM-07, PM-10 |
| CA-7 | Después de guardar se muestra un mensaje de éxito y la información actualizada | PU-507, PU-510, PM-07, PM-08, PM-10 |
| CA-8 | Con datos inválidos se informa al técnico y no se guarda | PU-505, PU-506, PU-508, PU-511, PU-512, PM-03, PM-04, PM-05, PM-06, PM-09 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias usan `FakeProfileRepository`, `FakeHousingRepository` y `FakeAuthRepository` en lugar de Firebase.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`, Firestore con reglas de desarrollo

## 6. Datos de prueba

Las pruebas unitarias usan al técnico `Juan Pérez Ramírez`. Para las pruebas manuales se necesita un usuario real con rol `tecnico`, estado `activa` y una especialidad registrada, además de un correo nuevo al que se tenga acceso para abrir el enlace de verificación.

| Dato | Valor |
|---|---|
| Nombre válido | `Juan Pérez` |
| Correo válido | Un correo real, sin registrar en el sistema |
| Teléfono válido | `7779998877` |
| Nombre inválido | vacío, `Al`, `Juan 123` |
| Correo inválido | vacío, `juan@`, `@correo.com` |
| Correo ya registrado | El correo de otro usuario existente |
| Teléfono inválido | vacío, `777111223` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician
```

### 7.1 Formulario — `technician_edit_profile_screen_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-501 | Abrir el formulario | Muestra el nombre, el correo y el teléfono actuales |
| PU-502 | Revisar la especialidad | Muestra el valor con candado y solo hay 3 campos editables |
| PU-503 | Revisar la posición del formulario | El contenido empieza debajo de la barra superior |
| PU-504 | Editar y restaurar un campo | "Guardar cambios" se habilita con cambios y se deshabilita sin ellos |
| PU-505 | Guardar con correo inválido | Muestra "Correo no válido", no llama al repositorio y la sesión no cambia |
| PU-506 | Guardar con teléfono inválido | Muestra "El teléfono debe tener 10 dígitos", no llama al repositorio y la sesión no cambia |
| PU-507 | Guardar nombre y teléfono válidos | Guarda los datos sin espacios de más, no envía ningún enlace, muestra el mensaje de éxito, regresa, actualiza el perfil y conserva la especialidad |
| PU-508 | Falla el guardado por correo duplicado | Muestra el motivo, sigue en el formulario y la sesión no cambia |
| PU-509 | Pulsar "Cancelar" con cambios | Regresa sin guardar |
| PU-510 | Guardar un correo nuevo | Pide el enlace con el correo en minúsculas, avisa que debe confirmarlo y conserva el correo actual en el perfil |
| PU-511 | No se puede enviar el enlace | Muestra el motivo, sigue en el formulario y no guarda ningún dato |

### 7.2 Cambio de correo — `technician_email_change_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-512 | Errores de Authentication | `requires-recent-login`, `email-already-in-use`, `too-many-requests` y `network-request-failed` muestran su mensaje |
| PU-513 | Entrar después de confirmar el enlace | `correo` pasa a ser el correo nuevo |
| PU-514 | Entrar sin haber confirmado el enlace | El perfil conserva su correo |

Los errores de Firestore y las validaciones de nombre y teléfono ya están cubiertos por PU-58 a PU-60, porque el técnico usa el mismo código que el residente y el administrador. Las llamadas reales a Firebase, incluida la consulta de correo duplicado, no tienen prueba unitaria y se verifican con PM-06, PM-07 y PM-10.

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el formulario | En Perfil pulsar "Modificar perfil" | Abre el formulario con el nombre, el correo y el teléfono actuales |
| PM-02 | Especialidad de solo lectura | Revisar la especialidad | Tiene candado, no se puede editar y aparece la nota de que solo un administrador la cambia |
| PM-03 | Nombre inválido | Borrar el nombre; luego escribir `Juan 123` | "Ingresa tu nombre" y "El nombre solo puede tener letras"; no se guarda |
| PM-04 | Correo inválido | Escribir `juan@` y pulsar "Guardar cambios" | "Correo no válido"; no se guarda |
| PM-05 | Teléfono inválido | Escribir `777111223` y pulsar "Guardar cambios" | "El teléfono debe tener 10 dígitos"; no se guarda. El campo no acepta letras ni más de 10 dígitos |
| PM-06 | Correo duplicado | Escribir el correo de otro usuario y guardar | "El correo electrónico ya está registrado por otro usuario."; sigue en el formulario |
| PM-07 | Guardar cambios | Cambiar nombre, correo y teléfono por datos válidos y guardar | Avisa que se envió un enlace al correo nuevo y regresa al perfil con el nombre y el teléfono nuevos y el correo anterior. En `usuarios` cambian `nombre` y `telefono`, y aparece `correoPendiente` |
| PM-08 | Persistencia | Después de PM-07 cerrar y volver a abrir la app | El perfil conserva los datos nuevos |
| PM-09 | Sin internet | Activar modo avión, cambiar el teléfono y guardar | Mensaje de error y sigue en el formulario |
| PM-10 | Confirmar el correo nuevo | Después de PM-07 abrir el enlace recibido, cerrar sesión e intentar entrar con el correo anterior; luego entrar con el nuevo | El correo anterior ya no entra y el nuevo sí. El perfil muestra el correo nuevo, `correo` cambia en `usuarios` y `correoPendiente` desaparece |
| PM-11 | Botones sin cambios | Abrir el formulario sin modificar nada; luego cambiar un dato y pulsar "Cancelar" | "Guardar cambios" está deshabilitado sin cambios y "Cancelar" regresa sin guardar |
| PM-12 | Enlace sin confirmar | Pedir el cambio de correo, no abrir el enlace, cerrar sesión y entrar con el correo anterior | Entra con el correo anterior y el perfil lo sigue mostrando |
| PM-13 | Sesión antigua | Con una sesión iniciada hace varias horas, pedir el cambio de correo | Si Firebase lo rechaza, muestra "Por seguridad, cierra sesión y vuelve a entrar para cambiar tu correo." y no guarda nada |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test test/unitarias/technician`).
- Los casos manuales PM-01 a PM-13 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 05/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.2 (PU-501 a PU-509) | 9 | Aprobadas |
| Proyecto completo (`flutter test`) | 215 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-02 | Pendiente | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-03 | Pendiente | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-01 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-04 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-05 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-06 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-07 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-08 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-09 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-10 | Pendiente | 05/11/2026 | Vanessa Negrete Juárez |  |
| PM-11 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-12 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-13 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
