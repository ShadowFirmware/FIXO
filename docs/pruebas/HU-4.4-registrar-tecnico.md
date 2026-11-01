---
| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.4 Registrar técnico |
| Rama | `FEATURE/HU-4.4-Registrar-tecnico` |
| Fecha | 01/11/2026 |
---

# Plan de pruebas — HU 4.4 Registrar técnico

## 1. Objetivo

Verificar que el administrador pueda registrar nuevos técnicos con sus datos básicos (nombre, correo, teléfono, especialidad y contraseña), que el correo sea único, la contraseña tenga mínimo 8 caracteres, y que al registrar correctamente el técnico aparezca en la lista con rol Técnico, conducta Bueno y cuenta Activa.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Técnicos" en el menú hamburguesa del administrador |
| Formulario | Nombre completo, correo, teléfono, especialidad y contraseña |
| Validación | Correo único, contraseña mínimo 8 caracteres |
| Persistencia | Creación en Firebase Authentication y Firestore (`usuarios`) |
| Lista | Visualización de técnicos registrados con sus datos |
| Acciones | Ver detalles, editar y eliminar técnico |
| Restricción | Solo el administrador puede acceder |

**No incluye**

- Edición completa de técnicos (HU 4.5) - solo base.
- Dar de baja (HU 4.6).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.4 | Pruebas |
|---|---|---|
| CA-1 | El formulario solicita nombre, correo, teléfono, especialidad y contraseña | PM-02 |
| CA-2 | El correo electrónico debe ser único en el sistema | PM-07 |
| CA-3 | La contraseña debe tener mínimo 8 caracteres | PM-04 |
| CA-4 | Al completar el registro, el usuario aparece con rol Técnico | PM-05, PM-06 |
| CA-5 | Estado de conducta Bueno y cuenta Activa automáticamente | PM-05 |
| CA-6 | El sistema informa si el registro es correcto o si hay error | PM-05, PM-07, PM-08 |

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
| Nombre válido | `Juan Pérez` |
| Correo válido | `juan.tecnico@correo.com` |
| Teléfono válido | `7774445566` |
| Especialidad válida | `Electricidad` |
| Contraseña válida | `Password123` |
| Correo ya registrado | `admin@correo.com` |
| Contraseña corta | `1234` |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso al módulo | En el menú hamburguesa pulsar "Técnicos" | Se abre la pantalla "Técnicos" |
| PM-02 | Formulario de registro | Pulsar el botón de agregar técnico (lado derecho) | Se abre el formulario con campos nombre, correo, teléfono, especialidad y contraseña |
| PM-03 | Campos obligatorios | Intentar registrar dejando campos vacíos | Mensajes de validación y no se registra |
| PM-04 | Contraseña corta | Ingresar contraseña de menos de 8 caracteres | "La contraseña debe tener al menos 8 caracteres"; no se registra |
| PM-05 | Registro correcto | Llenar todos los campos con datos válidos | Mensaje de éxito, el técnico aparece en la lista con rol Técnico, conducta Bueno y cuenta Activa |
| PM-06 | Visualización en tabla | Revisar la lista después de registrar | Se muestran nombre, correo, teléfono y especialidad del técnico |
| PM-07 | Correo duplicado | Registrar con un correo ya existente | Mensaje "El correo electrónico ya está registrado."; no se crea el usuario |
| PM-08 | Error de red | Activar modo avión y registrar | Mensaje de error y no se crea el técnico |
| PM-09 | Ver detalles | En la tabla (PC) o menú de 3 puntos (móvil) pulsar "Ver detalles" | Se muestra un diálogo con los datos del técnico |
| PM-10 | Eliminar técnico | Pulsar "Eliminar" y confirmar | El técnico se elimina de la lista |
| PM-11 | Responsive móvil | Abrir en teléfono | La lista muestra solo el nombre y un botón de 3 puntos con las acciones |
| PM-12 | Responsive PC | Abrir en escritorio | Se muestra la tabla completa con todas las columnas |

## 8. Criterios de aprobación

- El registro de técnicos funciona correctamente.
- Las validaciones se cumplen.
- La lista muestra los técnicos registrados.
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
