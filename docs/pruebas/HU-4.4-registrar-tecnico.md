# Plan de pruebas — HU 4.4 Registrar técnico

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.4 Registrar técnico |
| Rama | `FEATURE/HU-4.4-Registrar-tecnico` (actualizado en `feature/mejoras-generales`) |
| Fecha | 01/11/2026 — actualizado el 09/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda registrar nuevos técnicos con sus datos básicos (nombre, correo, teléfono, especialidad y contraseña), que el correo sea único, la contraseña tenga mínimo 8 caracteres, y que al registrar correctamente el técnico aparezca en la lista con rol Técnico, conducta Bueno y cuenta Activa.

> **Cambio del 09/11/2026:** Residentes y Técnicos se unieron en la sección **Usuarios**. El técnico se registra desde "Agregar" eligiendo el rol **Técnico**; el formulario cambia la vivienda por la especialidad.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Usuarios" del menú del administrador, filtro "Técnicos" |
| Formulario | Rol Técnico: nombre completo, correo, teléfono, contraseña y especialidad |
| Validación | Mensaje en cada campo que falta o no es válido, aviso general, correo único, contraseña mínimo 8 caracteres, especialidad obligatoria |
| Persistencia | Creación en Firebase Authentication y Firestore (`usuarios`) |
| Lista | Tarjetas (teléfono) o tabla (web) con rol, especialidad y estado de la cuenta |

**No incluye**

- Registro de residentes (HU 4.3), edición (HU 4.5) y baja (HU 4.6).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.4 | Pruebas |
|---|---|---|
| CA-1 | El formulario solicita nombre, correo, teléfono, especialidad y contraseña | PU-577, PM-02 |
| CA-2 | El correo electrónico debe ser único en el sistema | PU-575, PU-579, PM-07 |
| CA-3 | La contraseña debe tener mínimo 8 caracteres | PU-578, PM-04 |
| CA-4 | Al completar el registro, el usuario aparece con rol Técnico | PU-575, PU-579, PM-05, PM-06 |
| CA-5 | Estado de conducta Bueno y cuenta Activa automáticamente | PM-05 |
| CA-6 | El sistema informa si el registro es correcto o si hay error | PU-578, PU-579, PM-03, PM-05, PM-07, PM-08 |

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
| Nombre válido | `Jorge Ramírez` |
| Correo válido | `jorge.tecnico@correo.com` |
| Teléfono válido | `7774445566` |
| Especialidad válida | `Electricidad` |
| Contraseña válida | `Password123` |
| Correo ya registrado | `admin@correo.com` |
| Contraseña corta | `1234` |

## 7. Casos de prueba unitarios

```bash
flutter test test/unitarias/admin/admin_users_test.dart
```

Son las mismas pruebas de la sección Usuarios que la HU 4.3 (PU-574 a PU-580). Las que tocan al técnico:

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-575 | Registrar un técnico con especialidad y otro con correo repetido | Se guarda con su especialidad; el correo repetido muestra el error |
| PU-577 | Cambiar el rol a Técnico en el formulario | Desaparece la vivienda y aparece la especialidad |
| PU-578 | Guardar como Técnico sin especialidad | "Ingresa la especialidad" y no se registra |
| PU-579 | Registrar un técnico con correo repetido y luego con uno nuevo | Error en el formulario; después se registra y aparece en la lista |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso al módulo | En el menú del administrador pulsar "Usuarios" y elegir el filtro "Técnicos" | Se abre "Usuarios" con los técnicos |
| PM-02 | Formulario de registro | Pulsar "Agregar" y elegir el rol Técnico | El formulario pide nombre, correo, teléfono, contraseña y especialidad |
| PM-03 | Campos obligatorios | Pulsar "Registrar" con los campos vacíos | Cada campo muestra su mensaje, aparece "Revisa los campos marcados en rojo." y no se registra |
| PM-04 | Contraseña corta | Escribir una contraseña de menos de 8 caracteres | "La contraseña debe tener al menos 8 caracteres"; no se registra |
| PM-05 | Registro correcto | Llenar todos los campos con datos válidos | Mensaje de éxito; el técnico aparece con rol Técnico y cuenta Activa; en Firestore tiene conducta `bueno` |
| PM-06 | Visualización | Revisar la lista después de registrar | Teléfono: tarjeta con nombre, rol, especialidad y estado. Web: tabla con todas las columnas |
| PM-07 | Correo duplicado | Registrar con un correo ya existente | "El correo electrónico ya está registrado." arriba del formulario; no se crea el usuario |
| PM-08 | Error de red | Activar modo avión y registrar | Mensaje de error en el formulario y no se crea el técnico |
| PM-09 | Ver detalles | Tocar la tarjeta (teléfono) o el nombre (web) | Se abre el detalle con especialidad, disponibilidad, cuenta y conducta |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-09 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| Usuarios (PU-574 a PU-581, PU-590 y PU-596) | 10 | Aprobadas |
| Proyecto completo (`flutter test`) | 307 | Aprobadas |

### Manuales

Las observaciones indican qué prueba automatizada ya cubre el caso con datos simulados. Aun así, cada caso debe ejecutarse en el dispositivo con Firebase real.

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Pendiente | | | Automatizada en PU-574 |
| PM-02 | Pendiente | | | Automatizada en PU-577 |
| PM-03 | Pendiente | | | Automatizada en PU-578 |
| PM-04 | Pendiente | | | Automatizada en PU-578 |
| PM-05 | Pendiente | | | Automatizada en PU-579 (sin Firebase) |
| PM-06 | Pendiente | | | Automatizada en PU-579 y PU-580 |
| PM-07 | Pendiente | | | Automatizada en PU-579 |
| PM-08 | Pendiente | | | Requiere el dispositivo sin conexión |
| PM-09 | Pendiente | | | |
