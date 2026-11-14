# Plan de pruebas — HU 4.5 Editar información de residentes y técnicos

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.5 Editar información de residentes y técnicos |
| Rama | `FEATURE/HU-4.5-Editar-informacion` (actualizado en `feature/mejoras-generales`) |
| Fecha | 01/11/2026 — actualizado el 09/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda editar el nombre, correo y teléfono de residentes y técnicos, la vivienda de los residentes y la especialidad de los técnicos, con correo único, solo viviendas activas y disponibles, y que los cambios se reflejen de inmediato.

> **Cambio del 09/11/2026:** la edición se hace desde la sección **Usuarios** (opción "Editar" del menú de cada usuario). El formulario es el mismo que el de registro, sin rol ni contraseña, y conserva la confirmación al guardar y al descartar cambios.
>
> **Cambio de correo:** desde la app no se puede cambiar el correo con el que otra persona inicia sesión (requiere un servidor, que el plan Spark no tiene). Por eso el correo nuevo queda pendiente en `correoPendiente`; en el siguiente inicio de sesión del usuario (con su correo anterior) se le envía el enlace de verificación, y al abrirlo cambia su correo de acceso.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Editar" de cada usuario en "Usuarios" |
| Formulario | Datos actuales; vivienda (residente) o especialidad (técnico) |
| Validación | Mensaje en cada campo que falta o no es válido y correo único |
| Confirmaciones | Al guardar y al cancelar con cambios |
| Vivienda | Solo activas y disponibles; la anterior queda libre |

**No incluye**

- Registro (HU 4.3 y HU 4.4) y baja (HU 4.6).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.5 | Pruebas |
|---|---|---|
| CA-1 | Editar nombre, correo y teléfono | PU-576, PU-590, PM-02, PM-05 |
| CA-2 | Residentes: modificar vivienda; técnicos: especialidad | PU-576, PM-02, PM-05 |
| CA-3 | Correo único al modificar | PM-07 |
| CA-1 | Cambio de correo (acceso con el correo nuevo) | PU-597 a PU-600, PM-13 |
| CA-4 | Cambios reflejados inmediatamente | PU-590, PM-05, PM-06 |
| CA-5 | Solo vivienda activa y disponible | PM-08 |
| CA-6 | No asignar vivienda con residente activo | PM-08 |
| CA-7 | Vivienda anterior queda disponible | PM-09 |
| CA-8 | Incidencias no se trasladan a nueva vivienda | PM-10 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/admin_users_test.dart` | Simulado con fakes |
| Manuales (PM) | App en emulador, teléfono o navegador | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico) y web (Chrome)
- Firebase: proyecto `fixo-a7763`

## 6. Casos de prueba unitarios

```bash
flutter test test/unitarias/admin/admin_users_test.dart
```

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-576 | Editar un residente con otra vivienda | Se guarda con la vivienda nueva |
| PU-590 | Editar el teléfono de un residente | No pide rol ni contraseña; pide confirmar, guarda y avisa "Residente actualizado correctamente." |
| PU-596 | Cambiar la especialidad de un técnico y cancelar | Pide confirmar; al descartar se cierra sin guardar |
| PU-597 a PU-600 | Cambiar el correo de un usuario (`test/unitarias/auth/pending_email_test.dart`) | El correo queda en `correoPendiente`; al iniciar sesión se envía el enlace una sola vez; si falla, entra igual; el administrador ve el aviso |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso a edición | En "Usuarios", abrir el menú de un residente o técnico y pulsar "Editar" | Se abre el formulario con los datos actuales |
| PM-02 | Editar residente | Modificar nombre, correo, teléfono y vivienda y guardar | Pide confirmar; los cambios se guardan, la lista se actualiza y la vivienda anterior queda disponible |
| PM-03 | Cancelar sin cambios | Pulsar "Cancelar" sin modificar | Se cierra el formulario sin preguntar |
| PM-04 | Descartar cambios | Modificar datos y pulsar "Cancelar" | Pregunta "¿Deseas descartar los cambios realizados?"; al confirmar se cierra sin guardar |
| PM-05 | Editar técnico | Modificar nombre, correo, teléfono y especialidad y guardar | Los cambios se guardan y la lista se actualiza |
| PM-06 | Confirmar guardar | Modificar datos y pulsar "Guardar cambios" | Pregunta "¿Deseas guardar los cambios realizados?"; al confirmar se guarda |
| PM-07 | Correo duplicado | Editar con un correo ya registrado | El error aparece arriba del formulario y no se guarda |
| PM-08 | Vivienda no disponible | Desplegar "Vivienda" | Solo aparecen la vivienda actual y las activas disponibles |
| PM-09 | Vivienda anterior disponible | Cambiar la vivienda de un residente | La vivienda anterior queda disponible para otro residente |
| PM-10 | Incidencias no trasladadas | Cambiar la vivienda de un residente con incidencias | Las incidencias siguen asociadas a la vivienda original |
| PM-11 | Teléfono | Editar en el teléfono | El formulario se abre como pantalla completa |
| PM-12 | Web | Editar en el navegador | El formulario se abre como ventana |
| PM-13 | Cambio de correo | Cambiar el correo de un usuario a uno nuevo; iniciar sesión como ese usuario con su correo anterior; abrir el enlace que llega al correo nuevo; cerrar sesión y entrar con el correo nuevo | Al guardar, el administrador ve que el correo queda pendiente. Al iniciar sesión, el usuario ve el aviso y recibe el enlace. Después de abrirlo entra con el correo nuevo, y `correo` cambia en `usuarios` |

## 8. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-13 se cumplen.
- No hay defectos abiertos de severidad alta.

## 9. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| Usuarios (PU-574 a PU-581, PU-590 y PU-596) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 307 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-08 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-09 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-10 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-11 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-12 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-13 | Aprobada | 01/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
