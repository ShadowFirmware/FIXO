# Plan de pruebas — HU 4.2 Modificar perfil

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.2 Modificar perfil |
| Fecha | 27/10/2026 |

## 1. Objetivo

Verificar que el administrador pueda modificar nombre, correo electrónico y teléfono desde la consulta de su perfil, que se validen los campos y que no se permita guardar correos duplicados. También verificar que al guardar correctamente se muestre mensaje de éxito y se reflejen los cambios.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Navegación desde consulta de perfil a modificar perfil |
| Campos editables | Nombre, correo electrónico y teléfono |
| Validaciones | Formato de correo, formato/teléfono, nombre |
| Correo único | Validación de duplicados |
| Guardado | Persistencia en base de datos con datos válidos |
| Mensajes | Éxito y errores claros |

**No incluye**

- Cambio de rol o estado de cuenta
- Gestión de viviendas
- Modificación de otros usuarios

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.2 | Pruebas |
|---|---|---|
| CA-1 | El administrador debe poder acceder a la opción de modificar perfil desde la consulta de su propio perfil en la aplicación web | PM-01 |
| CA-2 | El administrador deberá poder modificar únicamente sus datos personales y de contacto permitidos, como nombre, correo electrónico y teléfono | PU-450, PU-452, PM-02 |
| CA-3 | Si se edita el correo electrónico, el sistema debe validar que el nuevo correo no esté ya registrado por otro usuario en el sistema | PU-458, PM-06 |
| CA-4 | El sistema debe validar que los campos, incluido el formato del correo y la longitud o formato del teléfono, contengan información válida antes de guardar los cambios | PU-453, PU-454, PU-455, PM-03, PM-04, PM-05 |
| CA-5 | Si la información es válida, el sistema debe guardar las modificaciones realizadas en la base de datos | PU-456, PU-457, PM-07 |
| CA-6 | Después de guardar, el sistema debe mostrar un mensaje de éxito y reflejar la información actualizada en el perfil | PU-456, PU-457, PM-07, PM-08 |
| CA-7 | Si existe algún dato inválido o duplicado, el sistema debe informar al administrador con un mensaje de error claro y no guardar los cambios incorrectos | PU-453, PU-454, PU-455, PU-458, PU-459, PU-460, PM-03 a PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o teléfono)
- Firebase: proyecto `fixo-a7763`

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario con rol `admin` y estado `activa` |
| Correo actual | `admin@correo.com` |
| Correo duplicado | Correo ya registrado por otro usuario |
| Nombre válido | `Carlos Admin Actualizado` |
| Teléfono válido | `5559876543` |
| Teléfono inválido | `123` o con letras |
| Correo inválido | `correo-sin-arroba` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin
```

### 7.1 ViewModel de edición de perfil del administrador — `admin_edit_profile_view_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-450 | Carga los datos actuales en el formulario | Muestra nombre, correo y teléfono iniciales |
| PU-451 | No hay cambios si se deja igual | `hasChanges` es falso sin modificaciones |
| PU-452 | Hay cambios si se modifica nombre, correo o teléfono | `hasChanges` es verdadero al cambiar cualquier campo |
| PU-453 | No guarda con nombre inválido | Devuelve false, muestra error, no llama al repositorio |
| PU-454 | No guarda con correo inválido | Devuelve false, muestra error, no llama al repositorio |
| PU-455 | No guarda con teléfono inválido | Devuelve false, muestra error, no llama al repositorio |
| PU-456 | Guarda nombre, correo y teléfono válidos | Guarda datos normalizados, actualiza sesión, `hasChanges` vuelve a falso |
| PU-457 | Actualiza la sesión tras guardar | La sesión refleja nombre, correo y teléfono actualizados |
| PU-458 | Muestra error si el correo ya está registrado | Muestra mensaje de correo duplicado, no guarda |
| PU-459 | Muestra error de red si falla la conexión | Muestra mensaje de red |
| PU-460 | Muestra error genérico si falla inesperadamente | Muestra mensaje genérico de error |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceder desde consulta de perfil | Desde perfil de administrador pulsar "Modificar perfil" | Se abre la pantalla "Modificar perfil" con datos actuales |
| PM-02 | Campos editables | Revisar formulario | Se pueden editar nombre completo, correo electrónico y teléfono. No hay campos bloqueados |
| PM-03 | Validación nombre inválido | Dejar nombre vacío o con números y guardar | Se muestra mensaje de validación, no se guarda |
| PM-04 | Validación correo inválido | Escribir correo sin formato válido y guardar | Se muestra mensaje "Correo no válido", no se guarda |
| PM-05 | Validación teléfono inválido | Escribir menos de 10 dígitos y guardar | Se muestra mensaje "El teléfono debe tener 10 dígitos", no se guarda |
| PM-06 | Correo duplicado | Cambiar correo por uno ya registrado por otro usuario y guardar | Se muestra mensaje "El correo electrónico ya está registrado por otro usuario." y no se guarda |
| PM-07 | Guardado exitoso | Cambiar nombre, correo y teléfono por datos válidos y guardar | Muestra "Tu perfil se actualizó correctamente", regresa al perfil |
| PM-08 | Reflejo de cambios | Tras PM-07 revisar perfil | El perfil muestra nombre, correo y teléfono actualizados |
| PM-09 | Persistencia | Cerrar y volver a abrir la app | Los cambios persisten |
| PM-10 | Sin cambios no guarda | Abrir formulario sin modificar y intentar guardar | El botón "Guardar cambios" está deshabilitado |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan.
- Los casos manuales PM-01 a PM-10 se cumplen.
- Se valida correo único correctamente.
- Se muestran mensajes claros en caso de error.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 27/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.2 (PU-450 a PU-460) | 11 | Pendiente de ejecución |

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
