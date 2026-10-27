# Plan de pruebas — HU 4.3 Registrar residente

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.3 Registrar residente |
| Fecha | 27/10/2026 |

## 1. Objetivo

Verificar que el administrador pueda registrar nuevos residentes con nombre completo, correo electrónico, teléfono, contraseña y vivienda previamente registrada, que el correo sea único, la contraseña tenga mínimo 8 caracteres, solo se puedan asignar viviendas activas y disponibles, y que al registrar correctamente se establezca estado de conducta Bueno y cuenta Activa.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Formulario | Solicitud de datos obligatorios |
| Validaciones | Correo único, contraseña mínimo 8 caracteres, campos válidos |
| Viviendas | Selección de vivienda activa y disponible |
| Duplicados | Una vivienda ocupada no puede asignarse |
| Registro | Creación en Authentication y Firestore con rol Residente |
| Estados | Estado de conducta Bueno y cuenta Activa |
| Mensajes | Éxito o error claros |

**No incluye**

- Gestión de lista de residentes
- Edición posterior
- Reglas de seguridad complejas

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.3 | Pruebas |
|---|---|---|
| CA-1 | El formulario debe solicitar nombre completo, correo electrónico, teléfono, contraseña y vivienda | PM-01, PM-02 |
| CA-2 | El correo electrónico debe ser único en el sistema | PU-509, PM-06 |
| CA-3 | La contraseña debe tener como mínimo 8 caracteres | PU-505, PM-05 |
| CA-4 | El administrador debe poder seleccionar una vivienda activa y disponible | PU-500, PM-02 |
| CA-5 | Una vivienda que ya tenga otro residente activo no podrá asignarse | PU-507, PM-07 |
| CA-6 | Al completar el registro, el usuario debe aparecer en la lista con el rol Residente | PU-508 (verifica creación con rol residente) |
| CA-7 | Al registrar correctamente al residente, su estado de conducta debe establecerse automáticamente como Bueno y su cuenta como Activa | PU-508 (verifica UserModel con conductStatus bueno y accountStatus active) |
| CA-8 | El sistema debe informar si el registro se realiza correctamente o si existe algún error | PU-502-PU-506, PU-508, PU-509, PM-03 a PM-08 |

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
| Nombre válido | `María González López` |
| Correo válido | `maria.nueva@correo.com` |
| Teléfono válido | `5551234567` |
| Contraseña válida | `Password123` (mínimo 8 caracteres) |
| Contraseña inválida | `pass123` (menos de 8) |
| Vivienda disponible | Vivienda activa sin residente asignado |
| Vivienda ocupada | Vivienda con residente activo |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin
```

### 7.1 ViewModel de registro de residente — `register_resident_view_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-500 | Carga viviendas activas y disponibles | Solo muestra viviendas activas sin residente asignado |
| PU-501 | Campos iniciales | Sin errores, no guarda |
| PU-502 | No registra con nombre inválido | Error de validación, no crea usuario |
| PU-503 | No registra con correo inválido | Error de validación, no crea usuario |
| PU-504 | No registra con teléfono inválido | Error de validación, no crea usuario |
| PU-505 | No registra con contraseña menor a 8 caracteres | Error de validación, no crea usuario |
| PU-506 | No registra sin vivienda seleccionada | Muestra "Selecciona una vivienda" |
| PU-507 | No registra con vivienda ya ocupada | Muestra error de vivienda no disponible |
| PU-508 | Registra residente correctamente | Crea usuario con rol residente, estado activo, conducta bueno, asigna vivienda |
| PU-509 | Muestra error si correo ya existe | Muestra mensaje de correo duplicado |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceder al registro | Desde inicio del administrador pulsar "Registrar residente" | Se abre el formulario de registro |
| PM-02 | Campos obligatorios | Revisar formulario | Se solicitan: nombre completo, correo electrónico, teléfono, contraseña y vivienda |
| PM-03 | Validación nombre inválido | Dejar vacío o con números y guardar | Muestra mensaje de validación |
| PM-04 | Validación correo inválido | Escribir correo sin formato válido | Muestra "Correo no válido" |
| PM-05 | Validación contraseña corta | Escribir contraseña con menos de 8 caracteres | Muestra "La contraseña debe tener mínimo 8 caracteres" |
| PM-06 | Correo duplicado | Registrar con correo ya existente | Muestra "El correo electrónico ya está registrado por otro usuario." |
| PM-07 | Vivienda ocupada no disponible | Verificar lista de viviendas | Solo aparecen viviendas activas y sin residente asignado |
| PM-08 | Registro exitoso | Llenar todos los campos válidos con vivienda disponible y guardar | Muestra "Residente registrado correctamente", regresa al inicio |
| PM-09 | Verificación en Firestore | Revisar documento creado en `usuarios` | Tiene rol `residente`, `estadoCuenta` `activa`, `estadoConducta` `bueno`, `viviendaId` asignado |
| PM-10 | Vivienda asignada | Revisar documento en `viviendas` | Tiene `residenteActivoId` con el UID del nuevo residente |
| PM-11 | Inicio de sesión del residente | Cerrar sesión y entrar con credenciales del residente creado | Puede iniciar sesión correctamente y ver su vivienda asignada |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan.
- Los casos manuales PM-01 a PM-11 se cumplen.
- Solo se asignan viviendas activas y disponibles.
- Se establecen estados correctos automáticamente.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 27/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.3 (PU-500 a PU-509) | 10 | Pendiente de ejecución |

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
