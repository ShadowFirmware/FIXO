---
| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.5 Editar información de residentes y técnicos |
| Rama | `FEATURE/HU-4.5-Editar-informacion` |
| Fecha | 01/11/2026 |
---

# Plan de pruebas — HU 4.5 Editar información de residentes y técnicos

## 1. Objetivo

Verificar que el administrador pueda editar la información de residentes y técnicos (nombre, correo, teléfono y vivienda/especialidad), validando correo único, disponibilidad de vivienda y actualización inmediata de la lista.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción de editar en la lista de residentes y técnicos |
| Formulario | Nombre, correo, teléfono, vivienda (residentes) o especialidad (técnicos) |
| Validación | Correo único, vivienda activa y disponible |
| Reasignación | Vivienda anterior disponible, incidencias no se trasladan |
| Confirmación | Diálogos de guardar y descartar cambios |
| Lista | Cambios reflejados inmediatamente |

**No incluye**

- Edición de contraseña.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.5 | Pruebas |
|---|---|---|
| CA-1 | Editar nombre, correo y teléfono | PM-02, PM-05 |
| CA-2 | Residentes: modificar vivienda; técnicos: especialidad | PM-02, PM-05 |
| CA-3 | Correo único al modificar | PM-07 |
| CA-4 | Cambios reflejados inmediatamente | PM-05, PM-06 |
| CA-5 | Solo vivienda activa y disponible | PM-08 |
| CA-6 | No asignar vivienda con residente activo | PM-08 |
| CA-7 | Vivienda anterior queda disponible | PM-09 |
| CA-8 | Incidencias no se trasladan a nueva vivienda | PM-10 |

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
| Residente existente | Residente con vivienda asignada |
| Técnico existente | Técnico con especialidad |
| Vivienda disponible | Vivienda activa sin residente |
| Vivienda ocupada | Vivienda con residente activo |
| Correo existente | `admin@correo.com` |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso a edición | En la lista pulsar "Editar" en un residente o técnico | Se abre el formulario de edición con datos actuales |
| PM-02 | Editar residente | Modificar nombre, correo, teléfono y vivienda y guardar | Cambios guardados, lista actualizada, vivienda anterior disponible |
| PM-03 | Cancelar sin cambios | Pulsar "Cancelar" sin modificar | Se cierra el formulario sin cambios |
| PM-04 | Descartar cambios | Modificar datos y pulsar "Cancelar" | Diálogo de confirmación; al confirmar se descartan los cambios |
| PM-05 | Editar técnico | Modificar nombre, correo, teléfono y especialidad y guardar | Cambios guardados y lista actualizada |
| PM-06 | Confirmar guardar | Modificar datos y pulsar "Guardar" | Diálogo de confirmación; al confirmar se guardan los cambios |
| PM-07 | Correo duplicado | Editar con un correo ya registrado | Mensaje de error, no se guardan los cambios |
| PM-08 | Vivienda no disponible | Intentar asignar vivienda ocupada o inactiva | La vivienda no aparece como disponible o se informa que no está disponible |
| PM-09 | Vivienda anterior disponible | Cambiar vivienda de un residente | La vivienda anterior queda disponible para otro residente |
| PM-10 | Incidencias no trasladadas | Cambiar vivienda de un residente con incidencias | Las incidencias siguen asociadas a la vivienda original |
| PM-11 | Responsive móvil | Editar en teléfono | El formulario se muestra correctamente |
| PM-12 | Responsive PC | Editar en escritorio | El formulario se muestra correctamente |

## 8. Criterios de aprobación

- La edición de residentes y técnicos funciona correctamente.
- Las validaciones se cumplen.
- La lista se actualiza inmediatamente.
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
