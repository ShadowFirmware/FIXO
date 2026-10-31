# Plan de pruebas — HU 4.1 Consultar perfil

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.1 Consultar perfil |
| Fecha | 27/10/2026 |

## 1. Objetivo

Verificar que el administrador pueda consultar la información de su perfil, que se muestre únicamente la información del administrador autenticado, que los datos correspondan a lo almacenado en el sistema y que desde la consulta exista la opción para modificar su información.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Implementación | Acceso a la sección de perfil desde el inicio del administrador |
| Datos mostrados | Información personal, correo, teléfono, estado de cuenta y fecha de registro |
| Sesión | Solo se muestra información del administrador autenticado |
| Navegación | Opción para modificar perfil disponible desde la consulta |
| Vivienda | Comportamiento al cargar vivienda si existe asignación |

**No incluye**

- Modificación del perfil (HU 4.2) - se cubre parcialmente con navegación
- Gestión de otros perfiles (HU 4.5)
- Otras funcionalidades del módulo administrador

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.1 | Pruebas |
|---|---|---|
| CA-1 | El administrador debe poder acceder a la sección de su perfil después de iniciar sesión | PM-01, PM-02 |
| CA-2 | El sistema debe mostrar únicamente la información correspondiente al administrador autenticado | PU-400, PU-401, PU-405, PU-406 |
| CA-3 | La información mostrada debe corresponder a los datos almacenados en el sistema | PU-400, PU-402, PU-403, PU-404 |
| CA-4 | Desde la consulta del perfil, el administrador debe tener disponible la opción para modificar su información | PM-03 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/admin/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias usan `FakeAuthRepository`, `FakeHousingRepository` en lugar de Firebase.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Administrador | Usuario con rol `admin` y estado de cuenta `activa` |
| Correo | `admin@correo.com` |
| Nombre | `Carlos Admin Pérez` |
| Teléfono | `5551234567` |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/admin
```

### 7.1 ViewModel del perfil de administrador — `admin_profile_view_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-400 | Muestra los datos personales del administrador autenticado | Muestra nombre, correo y teléfono correctos |
| PU-401 | Las iniciales usan las dos primeras palabras del nombre | Calcula iniciales correctamente ("Carlos Admin Pérez" → "CA", "Pedro" → "P", nombre vacío → "?") |
| PU-402 | Los datos vacíos se muestran como "Sin registrar" | Teléfono vacío o fecha nula muestran "Sin registrar" |
| PU-403 | El estado de la cuenta se muestra en español | Muestra "Activa", "Suspendida", "Deshabilitada" o "Dada de baja" correctamente |
| PU-404 | La fecha de registro se muestra en español | Formatea la fecha en español (ej. "27 de octubre de 2026") |
| PU-405 | Sin sesión no se muestran datos de ningún usuario | Muestra "Sin registrar", iniciales "?" y cuenta no activa |
| PU-406 | Al cambiar o cerrar la sesión se actualizan los datos mostrados | Al iniciar sesión con otro usuario actualiza los datos, al cerrar sesión muestra valores por defecto |
| PU-407 | Muestra "Sin registrar" cuando el administrador no tiene vivienda | Si no tiene housingId muestra "Sin registrar" |
| PU-408 | Muestra "Cargando…" mientras se consulta la vivienda | Mientras se consulta muestra "Cargando…" y después el nombre de la vivienda |
| PU-409 | Si la vivienda no existe se muestra "No disponible" | Cuando la vivienda no existe muestra "No disponible" |
| PU-410 | Si falla la consulta se muestra "No disponible" | En caso de error de red/consulta muestra "No disponible" |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso al perfil desde inicio | Iniciar sesión como administrador, desde la pantalla de inicio pulsar el ícono de perfil en la AppBar o "Mi perfil" | Se abre la pantalla "Mi perfil" mostrando la información del administrador |
| PM-02 | Verificar datos mostrados | Revisar la información mostrada en el perfil | Se muestra: foto/iniciales, nombre, correo, rol "Administrador", información personal (nombre, correo, teléfono), estado de cuenta y fecha de registro. Solo aparecen datos del administrador autenticado |
| PM-03 | Opción para modificar perfil | Desde la pantalla de perfil del administrador, verificar la presencia del botón "Modificar perfil" | Existe el botón "Modificar perfil" y al pulsarlo navega a la pantalla de edición |
| PM-04 | Navegación desde home | Desde AdminHomeScreen verificar acceso al perfil | Se puede acceder desde el ícono de persona en el AppBar y desde la acción "Mi perfil" |
| PM-05 | Persistencia de datos | Verificar que los datos mostrados coinciden con los datos del usuario en Firestore | La información coincide con lo almacenado en la colección `usuarios` |
| PM-06 | Cerrar sesión desde perfil | Desde el perfil del administrador pulsar "Cerrar sesión" | Se cierra la sesión y redirige a la pantalla de login |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test test/unitarias/admin`).
- Los casos manuales PM-01 a PM-06 se cumplen.
- Se verifica que desde la consulta hay opción para modificar perfil.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 27/10/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 4.1 (PU-400 a PU-410) | 11 | Pendiente de ejecución |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Pendiente | | | |
| PM-02 | Pendiente | | | |
| PM-03 | Pendiente | | | |
| PM-04 | Pendiente | | | |
| PM-05 | Pendiente | | | |
| PM-06 | Pendiente | | | |
