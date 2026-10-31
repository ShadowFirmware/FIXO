# Plan de pruebas — HU 4.3 Registrar residente

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.3 Registrar residente |
| Rama | `FEATURE/HU-4.2-Nueva-funcionalidad` |
| Fecha | 31/10/2026 |

## 1. Objetivo

Verificar que el administrador pueda registrar nuevos residentes con sus datos básicos y asignarles una vivienda previamente registrada, que el correo sea único, la contraseña tenga mínimo 8 caracteres, la vivienda esté activa y disponible, y que al registrar correctamente el residente aparezca en la lista con rol Residente, conducta Bueno y cuenta Activa.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Residentes" en el menú hamburguesa del administrador |
| Formulario | Nombre completo, correo, teléfono, contraseña y vivienda |
| Validación | Correo único, contraseña mínimo 8 caracteres, vivienda activa y disponible |
| Persistencia | Creación en Firebase Authentication y Firestore (`usuarios`) |
| Lista | Visualización de residentes registrados con sus datos |
| Acciones | Ver detalles, editar y eliminar residente |
| Restricción | Solo el administrador puede acceder |

**No incluye**

- Registro de técnicos (HU 4.4).
- Edición completa de residentes (HU 4.5) - solo base.
- Dar de baja (HU 4.6).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.3 | Pruebas |
|---|---|---|
| CA-1 | El formulario solicita nombre, correo, teléfono, contraseña y vivienda | PM-02 |
| CA-2 | El correo electrónico debe ser único en el sistema | PM-07 |
| CA-3 | La contraseña debe tener mínimo 8 caracteres | PM-04 |
| CA-4 | El administrador puede seleccionar una vivienda activa y disponible | PM-02, PM-09 |
| CA-5 | Una vivienda con residente activo no puede asignarse | PM-09 |
| CA-6 | Al completar el registro, el usuario aparece con rol Residente | PM-05, PM-06 |
| CA-7 | Estado de conducta Bueno y cuenta Activa automáticamente | PM-05 |
| CA-8 | El sistema informa si el registro es correcto o si hay error | PM-05, PM-07, PM-08 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.8 / Dart 3.13.7
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario con rol `admin` y estado `activa` |
| Viviendas | Al menos una vivienda activa y disponible, y una ocupada |
| Nombre válido | `María López` |
| Correo válido | `maria.nueva@correo.com` |
| Teléfono válido | `7775556677` |
| Contraseña válida | `Password123` |
| Correo ya registrado | `admin@correo.com` |
| Contraseña corta | `1234` |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso al módulo | En el menú hamburguesa pulsar "Residentes" | Se abre la pantalla "Residentes" |
| PM-02 | Formulario de registro | Pulsar el botón de agregar residente (lado derecho) | Se abre el formulario con campos nombre, correo, teléfono, contraseña y vivienda |
| PM-03 | Campos obligatorios | Intentar registrar dejando campos vacíos | Mensajes de validación y no se registra |
| PM-04 | Contraseña corta | Ingresar contraseña de menos de 8 caracteres | "La contraseña debe tener al menos 8 caracteres"; no se registra |
| PM-05 | Registro correcto | Llenar todos los campos con datos válidos y una vivienda disponible | Mensaje de éxito, el residente aparece en la lista con rol Residente, conducta Bueno y cuenta Activa; la vivienda queda asignada |
| PM-06 | Visualización en tabla | Revisar la lista después de registrar | Se muestran nombre, correo, teléfono y vivienda del residente |
| PM-07 | Correo duplicado | Registrar con un correo ya existente | Mensaje "El correo electrónico ya está registrado."; no se crea el usuario |
| PM-08 | Error de red | Activar modo avión y registrar | Mensaje de error y no se crea el residente |
| PM-09 | Vivienda ocupada | Intentar asignar una vivienda con residente activo | La vivienda no aparece como disponible o se informa que no está disponible |
| PM-10 | Ver detalles | En la tabla (PC) o menú de 3 puntos (móvil) pulsar "Ver detalles" | Se muestra un diálogo con los datos del residente |
| PM-11 | Eliminar residente | Pulsar "Eliminar" y confirmar | El residente se elimina de la lista y la vivienda queda disponible |
| PM-12 | Responsive móvil | Abrir en teléfono | La lista muestra solo el nombre y un botón de 3 puntos con las acciones |
| PM-13 | Responsive PC | Abrir en escritorio | Se muestra la tabla completa con todas las columnas |

## 8. Criterios de aprobación

- El registro de residentes funciona correctamente.
- Las validaciones se cumplen.
- La lista muestra los residentes registrados.
- No hay defectos abiertos de severidad alta.

## 9. Resultados

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