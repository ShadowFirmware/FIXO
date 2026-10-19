# Plan de pruebas — HU 1.1 Iniciar sesión

| Dato | Valor |
|---|---|
| Módulo | 1. Autenticación |
| Historia de usuario | HU 1.1 Iniciar sesión (#28) |
| Tarea | T 1.1.7 Probar el inicio de sesión (#35) |
| Rama | `feature/HU-1.1-iniciar-sesion` |
| Fecha | 19/10/2026 |

## 1. Objetivo

Verificar que un usuario registrado pueda iniciar sesión con su correo y contraseña, que el sistema lo dirija a las funciones de su rol (Residente, Técnico o Administrador) y que se rechacen las credenciales incorrectas, los usuarios no registrados y las cuentas sin acceso.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 1.1.2 | Lectura del perfil del usuario desde la colección `usuarios` |
| T 1.1.3 | Validación de credenciales contra Firebase Authentication |
| T 1.1.4 | Bloqueo de cuentas sin acceso, conservación y cierre de sesión |
| T 1.1.5 | Redirección a la pantalla del rol |
| T 1.1.6 | Mensajes de error del formulario y de las credenciales |

**No incluye**

- Recuperación de contraseña (HU 1.2).
- Diseño visual de la pantalla de login (T 1.1.1).
- Reglas de seguridad de Firestore por rol: las reglas actuales son de desarrollo.

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 1.1 | Pruebas |
|---|---|---|
| CA-1 | El usuario puede ingresar su correo y contraseña | PM-01, widget |
| CA-2 | Se valida que las credenciales correspondan a un usuario registrado | PU-07 a PU-14, PM-02 a PM-05 |
| CA-3 | Con credenciales correctas se permite el acceso | PU-07, PU-25, PM-01 |
| CA-4 | El usuario es dirigido a las funciones de su rol | PU-35 a PU-38, PM-01, PM-06, PM-07 |
| CA-5 | Con credenciales incorrectas se muestra un mensaje de credenciales no válidas | PU-08 a PU-10, PU-26, PM-02, PM-03 |
| CA-6 | No se permite el acceso a usuarios no registrados | PU-09, PU-13, PM-03, PM-04 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/auth/` | Simulado con fakes, sin conexión |
| Widget | `flutter_test` | `test/widget_test.dart` | No se usa |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias reemplazan Firebase por `FakeAuthRemoteDataSource` (en `test/unitarias/auth/fakes.dart`) para probar la lógica sin internet y con resultados repetibles.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`, Authentication con correo y contraseña, Firestore con reglas de desarrollo

## 6. Datos de prueba

Cada usuario debe existir en **Authentication** y tener un documento en `usuarios` cuyo ID sea su UID.

| Usuario | Rol (`rol`) | Estado (`estadoCuenta`) | Uso |
|---|---|---|---|
| Admin de prueba | `admin` | `activa` | Acceso de administrador |
| Residente de prueba | `residente` | `activa` | Acceso de residente |
| Técnico de prueba | `tecnico` | `activa` | Acceso de técnico |
| Residente dado de baja | `residente` | `baja` | Cuenta sin acceso |
| Residente suspendido | `residente` | `suspendida`, `suspendidaHasta` en el futuro | Suspensión vigente |
| Usuario sin perfil | — | Solo existe en Authentication | Usuario no registrado en el sistema |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias
```

### 7.1 Estructura de datos (T 1.1.2) — `user_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-01 | Leer un residente con todos sus campos | Se cargan rol, estado, conducta, reportes, suspensión y vivienda |
| PU-02 | Leer los tres roles | `admin`, `residente` y `tecnico` se reconocen |
| PU-03 | Documento con rol no válido (`Residente`) | Se rechaza con `FormatException` |
| PU-04 | Documento sin `estadoCuenta` | Se rechaza con `FormatException` |
| PU-05 | Guardar un usuario | No se guarda la contraseña ni campos de otros roles |
| PU-06 | Guardar un técnico nuevo | Conducta `bueno`, 0 reportes y disponible |

### 7.2 Validación de credenciales (T 1.1.3) — `auth_repository_impl_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-07 | Credenciales válidas | Devuelve el perfil del usuario |
| PU-08 | Contraseña incorrecta | "El correo o la contraseña no son válidos." |
| PU-09 | Correo no registrado | "El correo o la contraseña no son válidos." |
| PU-10 | Códigos de Firebase `invalid-credential`, `invalid-email`, `wrong-password`, `user-not-found`, `user-disabled` | Todos muestran credenciales no válidas |
| PU-11 | Demasiados intentos | "Demasiados intentos. Espera un momento…" |
| PU-12 | Sin internet | "No hay conexión a internet…" |
| PU-13 | Cuenta en Authentication sin documento en `usuarios` | "Este usuario no está registrado en el sistema." y se cierra la sesión |
| PU-14 | Sin permiso para leer `usuarios` | Error genérico y se cierra la sesión |

### 7.3 Control de acceso y sesión (T 1.1.4) — `auth_repository_impl_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-15 | Cuenta dada de baja | "Tu cuenta fue dada de baja…" |
| PU-16 | Cuenta deshabilitada | "Tu cuenta está deshabilitada…" |
| PU-17 | Suspensión vigente | "Tu cuenta está suspendida hasta el dd/mm/aaaa." |
| PU-18 | Suspensión ya vencida | Permite el acceso |
| PU-19 | Cuenta rechazada | La sesión queda cerrada |
| PU-20 | Abrir la app sin sesión guardada | No recupera usuario y se muestra el login |
| PU-21 | Abrir la app con sesión guardada | Recupera al usuario sin pedir credenciales |
| PU-22 | Sesión guardada de una cuenta dada de baja | No se recupera y se cierra la sesión |
| PU-23 | Cerrar sesión | Se borra la sesión guardada |

### 7.4 Mensajes de error (T 1.1.6) — `login_view_model_test.dart` y `validators_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-24 | Correo con espacios al inicio o al final | Se quitan los espacios; la contraseña no se modifica |
| PU-25 | Inicio de sesión exitoso | Devuelve el usuario y no hay mensaje de error |
| PU-26 | Credenciales inválidas | Queda el mensaje "El correo o la contraseña no son válidos." |
| PU-27 | Error inesperado | "Ocurrió un error inesperado. Inténtalo de nuevo." |
| PU-28 | Mientras se valida | Indica que está cargando y al terminar deja de cargar |
| PU-29 | Nuevo intento después de un error | Se limpia el mensaje anterior |
| PU-30 | Correo vacío | "Ingresa tu correo" |
| PU-31 | Correo sin formato válido (`maria`, `maria@`, `maria@correo`, `@correo.com`) | "Correo no válido" |
| PU-32 | Correo válido | Sin error |
| PU-33 | Contraseña vacía | "Ingresa tu contraseña" |
| PU-34 | Contraseña escrita | Sin error |

### 7.5 Redirección por rol (T 1.1.5) — `role_redirect_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-35 | Rol residente | Pantalla del residente (`/resident`) |
| PU-36 | Rol técnico | Pantalla del técnico (`/technician`) |
| PU-37 | Rol administrador | Pantalla del administrador (`/admin`) |
| PU-38 | Todos los roles | Cada rol tiene una pantalla distinta |

## 8. Casos de prueba manuales

Se ejecutan en la app con el proyecto real de Firebase y los datos de la sección 6.

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso de residente | Ingresar correo y contraseña del residente de prueba y pulsar "Iniciar sesión" | Entra a Inicio del residente y muestra "Hola, {nombre}" |
| PM-02 | Contraseña incorrecta | Ingresar el correo del residente con otra contraseña | Mensaje "El correo o la contraseña no son válidos." y sigue en el login |
| PM-03 | Correo no registrado | Ingresar un correo que no existe | Mensaje "El correo o la contraseña no son válidos." |
| PM-04 | Usuario sin perfil | Iniciar sesión con el usuario que solo existe en Authentication | Mensaje "Este usuario no está registrado en el sistema." |
| PM-05 | Formulario vacío o correo mal escrito | Pulsar "Iniciar sesión" sin datos; luego escribir `maria` en correo | "Ingresa tu correo", "Ingresa tu contraseña" y "Correo no válido" |
| PM-06 | Acceso de técnico | Iniciar sesión con el técnico de prueba | Entra a "Inicio del técnico" |
| PM-07 | Acceso de administrador | Iniciar sesión con el admin de prueba | Entra a "Inicio del administrador" |
| PM-08 | Cuenta dada de baja | Iniciar sesión con el residente dado de baja | "Tu cuenta fue dada de baja…" y no entra |
| PM-09 | Cuenta suspendida | Iniciar sesión con el residente suspendido | "Tu cuenta está suspendida hasta el…" y no entra |
| PM-10 | Conservar la sesión | Iniciar sesión, cerrar la app por completo y volver a abrirla | Entra directo a la pantalla de su rol |
| PM-11 | Cerrar sesión | Desde Perfil pulsar "Cerrar sesión"; cerrar y abrir la app | Regresa al login; al reabrir pide credenciales |
| PM-12 | Botón mientras valida | Pulsar "Iniciar sesión" con datos válidos | El botón muestra un indicador de carga y no se puede pulsar dos veces |
| PM-13 | Sin internet | Activar modo avión e intentar iniciar sesión | Mensaje de error de conexión y sigue en el login |

## 9. Criterios de aprobación

- Todas las pruebas unitarias y de widget pasan (`flutter test`).
- Los casos manuales PM-01 a PM-11 se cumplen.
- No hay defectos abiertos de severidad alta en el inicio de sesión.

## 10. Resultados

### Automatizadas — 19/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| Unitarias (`test/unitarias`) | 42 | Aprobadas |
| Widget (`test/widget_test.dart`) | 3 | Aprobadas |
| **Total** | **45** | **Aprobadas** |

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
