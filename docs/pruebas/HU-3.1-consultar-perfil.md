# Plan de pruebas — HU 3.1 Consultar perfil

| Dato | Valor |
|---|---|
| Módulo | 3. Técnico |
| Historia de usuario | HU 3.1 Consultar perfil |
| Fecha | 05/11/2026 |

## 1. Objetivo

Verificar que el técnico pueda consultar la información de su perfil, que se muestre únicamente la información del técnico autenticado, que los datos correspondan a lo almacenado en el sistema y que desde la consulta exista la opción para modificar su información.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Navegación | Barra inferior del técnico y acceso a la pestaña Perfil después de iniciar sesión |
| Datos mostrados | Iniciales, nombre, correo, teléfono, rol, especialidad, estado de la cuenta y fecha de registro |
| Sesión | Solo se muestra información del técnico autenticado y se actualiza al cambiar o cerrar la sesión |
| Especialidad | Se muestra como dato de solo lectura |
| Opciones del perfil | "Modificar perfil" abre su pantalla y "Cerrar sesión" regresa al login |
| Permisos de rutas | Solo el técnico puede abrir la ruta de modificar perfil |

**No incluye**

- Formulario para modificar el perfil (HU 3.2). Por ahora el botón abre una pantalla temporal.
- Contenido de las pestañas Inicio, Historial y Avisos, que siguen siendo pantallas temporales.
- Cambio de especialidad desde el módulo de administrador (HU 4.5).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 3.1 | Pruebas |
|---|---|---|
| CA-1 | El técnico debe poder acceder a la sección de su perfil después de iniciar sesión | PM-01, PM-02 |
| CA-2 | El sistema debe mostrar únicamente la información correspondiente al técnico autenticado | PU-491, PU-496, PU-497, PU-498, PM-03 |
| CA-3 | La información mostrada debe corresponder a los datos almacenados en el sistema | PU-491, PU-493, PU-494, PU-495, PU-498, PM-04 |
| CA-4 | Desde la consulta del perfil, el técnico debe tener disponible la opción para modificar su información | PU-500, PM-05 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/technician/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en emulador o teléfono | — | Proyecto real `fixo-a7763` |

Las pruebas unitarias usan `FakeAuthRepository` en lugar de Firebase.

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763`

## 6. Datos de prueba

Los datos de la tabla son los que usan las pruebas unitarias. Para las pruebas manuales se necesita un usuario real de la colección `usuarios` con esas características.

| Dato | Valor |
|---|---|
| Técnico | Usuario con rol `tecnico` y estado de cuenta `activa` |
| Correo | `jorge@correo.com` |
| Nombre | `Jorge Ramírez Soto` |
| Teléfono | `7774445566` |
| Especialidad | `Luz` |

Para PM-03 se necesita un segundo técnico con datos distintos, y para PM-07 un usuario con rol `residente`.

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/technician
```

### 7.1 ViewModel del perfil del técnico — `technician_profile_view_model_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-491 | Muestra los datos del técnico autenticado | Muestra nombre, correo, teléfono y especialidad correctos |
| PU-492 | Las iniciales usan las dos primeras palabras del nombre | "Jorge Ramírez Soto" → "JR", "Pedro" → "P", nombre vacío → "?" |
| PU-493 | Los datos vacíos se muestran como "Sin registrar" | Teléfono, especialidad y fecha sin valor muestran "Sin registrar" |
| PU-494 | El estado de la cuenta se muestra en español | Muestra "Activa", "Suspendida", "Deshabilitada" o "Dada de baja", y solo "Activa" cuenta como activa |
| PU-495 | La fecha de registro se muestra en español | Muestra "27 de octubre de 2026" |
| PU-496 | Sin sesión no se muestran datos de ningún usuario | Muestra "Sin registrar", iniciales "?" y cuenta no activa |
| PU-497 | Al cambiar o cerrar la sesión se actualizan los datos | Muestra los datos del nuevo usuario y, al cerrar sesión, los valores por defecto |

### 7.2 Pantalla de perfil del técnico — `technician_profile_screen_test.dart`

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-498 | Muestra el perfil del técnico autenticado | Aparecen el título "Mi perfil", los datos personales, el rol "Técnico", la especialidad y el estado de la cuenta |
| PU-499 | La especialidad se muestra como solo lectura | Aparece el ícono de candado |
| PU-500 | "Modificar perfil" abre la pantalla de edición | Al pulsar el botón se navega a la ruta de modificar perfil |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Entrada a la app del técnico | Iniciar sesión como técnico | Se abre la pestaña Inicio con la barra inferior: Inicio, Historial, Avisos y Perfil |
| PM-02 | Acceso al perfil | Pulsar la pestaña Perfil | Se abre "Mi perfil" con la pestaña Perfil seleccionada |
| PM-03 | Solo datos del técnico autenticado | Revisar el perfil, cerrar sesión e iniciar con otro técnico | Cada técnico ve únicamente sus propios datos |
| PM-04 | Datos iguales a los almacenados | Comparar el perfil con el documento del técnico en la colección `usuarios` | Nombre, correo, teléfono, especialidad, estado y fecha de registro coinciden |
| PM-05 | Opción para modificar perfil | Pulsar "Modificar perfil" y después regresar | Se abre la pantalla "Modificar perfil" (temporal hasta la HU 3.2) y al regresar se vuelve al perfil |
| PM-06 | Cerrar sesión desde el perfil | Pulsar "Cerrar sesión" | Se cierra la sesión y se muestra el login sin poder regresar con el botón atrás |
| PM-07 | Permisos de la ruta | Iniciar sesión como residente e intentar abrir la ruta `/technician/profile/edit` (en web, escribiéndola en la barra de direcciones) | La app redirige al inicio del residente |
| PM-08 | Barras al hacer scroll | En el perfil, desplazarse hacia abajo y luego hacia arriba | Las barras se ocultan al bajar, reaparecen al subir y el contenido final no queda tapado |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test test/unitarias/technician`).
- Los casos manuales PM-01 a PM-08 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 05/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 3.1 (PU-491 a PU-500) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 206 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-02 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-03 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-04 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-05 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-06 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-07 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
| PM-08 | Aprobada | 05/11/2026 | Vanessa Negrete Juárez | Sin observaciones |
