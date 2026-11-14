# Plan de pruebas — HU 4.3 Registrar residente

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.3 Registrar residente |
| Rama | `FEATURE/HU-4.2-Nueva-funcionalidad` (actualizado en `feature/mejoras-generales`) |
| Fecha | 31/10/2026 — actualizado el 09/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda registrar nuevos residentes con sus datos básicos y asignarles una vivienda previamente registrada, que el correo sea único, la contraseña tenga mínimo 8 caracteres, la vivienda esté activa y disponible, y que al registrar correctamente el residente aparezca en la lista con rol Residente, conducta Bueno y cuenta Activa.

> **Cambio del 09/11/2026:** Residentes y Técnicos se unieron en la sección **Usuarios**. El residente se registra desde "Agregar" eligiendo el rol **Residente**; el formulario pide la vivienda solo para ese rol. En el teléfono el formulario es una pantalla completa y en la web una ventana.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Usuarios" del menú del administrador, filtro "Residentes" |
| Formulario | Rol Residente: nombre completo, correo, teléfono, contraseña y vivienda |
| Validación | Mensaje en cada campo que falta o no es válido, aviso general, correo único, contraseña mínimo 8 caracteres, vivienda activa y disponible |
| Persistencia | Creación en Firebase Authentication y Firestore (`usuarios`) |
| Lista | Tarjetas (teléfono) o tabla (web) con rol y estado de la cuenta |

**No incluye**

- Registro de técnicos (HU 4.4), edición (HU 4.5) y baja (HU 4.6).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.3 | Pruebas |
|---|---|---|
| CA-1 | El formulario solicita nombre, correo, teléfono, contraseña y vivienda | PU-577, PM-02 |
| CA-2 | El correo electrónico debe ser único en el sistema | PU-575, PM-07 |
| CA-3 | La contraseña debe tener mínimo 8 caracteres | PU-578, PM-04 |
| CA-4 | El administrador puede seleccionar una vivienda activa y disponible | PU-575, PM-02, PM-09 |
| CA-5 | Una vivienda con residente activo no puede asignarse | PM-09 |
| CA-6 | Al completar el registro, el usuario aparece con rol Residente | PU-575, PM-05, PM-06 |
| CA-7 | Estado de conducta Bueno y cuenta Activa automáticamente | PM-05 |
| CA-8 | El sistema informa si el registro es correcto o si hay error | PU-575, PU-578, PU-579, PM-03, PM-05, PM-07, PM-08 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/admin/admin_users_test.dart` | Simulado con fakes |
| Manuales (PM) | App en emulador, teléfono o navegador | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico) y web (Chrome)
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

## 7. Casos de prueba unitarios

```bash
flutter test test/unitarias/admin/admin_users_test.dart
```

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-574 | Residentes y técnicos en una sola lista, filtro por rol y búsqueda | Se ordenan por nombre; los filtros y la búsqueda dejan solo los que coinciden |
| PU-575 | Registrar un residente, un técnico y un correo repetido | Cada uno se guarda con sus datos (vivienda o especialidad); el correo repetido muestra "El correo electrónico ya está registrado." |
| PU-577 | Abrir el formulario en el teléfono y cambiar de rol | Pantalla completa; con Residente pide la vivienda y con Técnico la especialidad |
| PU-578 | Guardar con datos vacíos o inválidos | Mensaje en cada campo, aviso "Revisa los campos marcados en rojo." y no se registra |
| PU-579 | Registrar con correo repetido y luego con uno nuevo | El error aparece arriba del formulario; después se registra, se cierra y se ve en la lista |
| PU-580 | Abrir la sección en la web | Tabla con todas las columnas y el formulario en una ventana |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso al módulo | En el menú del administrador pulsar "Usuarios" y elegir el filtro "Residentes" | Se abre "Usuarios" con los residentes |
| PM-02 | Formulario de registro | Pulsar "Agregar" (teléfono) o "Agregar usuario" (web) y dejar el rol en Residente | El formulario pide nombre, correo, teléfono, contraseña y vivienda |
| PM-03 | Campos obligatorios | Pulsar "Registrar" con los campos vacíos | Cada campo muestra su mensaje, aparece "Revisa los campos marcados en rojo." y no se registra |
| PM-04 | Contraseña corta | Escribir una contraseña de menos de 8 caracteres | "La contraseña debe tener al menos 8 caracteres"; no se registra |
| PM-05 | Registro correcto | Llenar todos los campos con datos válidos y una vivienda disponible | Mensaje de éxito; el residente aparece con rol Residente y cuenta Activa; en Firestore tiene conducta `bueno` y la vivienda queda asignada |
| PM-06 | Visualización | Revisar la lista después de registrar | Teléfono: tarjeta con nombre, rol, vivienda y estado. Web: tabla con nombre, rol, correo, teléfono, vivienda y cuenta |
| PM-07 | Correo duplicado | Registrar con un correo ya existente | "El correo electrónico ya está registrado." arriba del formulario; no se crea el usuario |
| PM-08 | Error de red | Activar modo avión y registrar | Mensaje de error en el formulario y no se crea el residente |
| PM-09 | Vivienda ocupada | Desplegar "Vivienda" | Solo aparecen viviendas activas y disponibles; si no hay, se avisa que hay que registrar o liberar una |
| PM-10 | Ver detalles | Tocar la tarjeta (teléfono) o el nombre (web) | Se abre el detalle con rol, correo, teléfono, vivienda, cuenta y conducta |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| Usuarios (PU-574 a PU-581, PU-590 y PU-596) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 307 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-08 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-09 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-10 | Aprobada | 31/10/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
