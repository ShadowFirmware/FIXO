---
| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.6 Dar de baja perfiles de residentes y técnicos |
| Rama | `FEATURE/HU-4.6-Dar-de-baja` |
| Fecha | 01/11/2026 |
---

# Plan de pruebas — HU 4.6 Dar de baja perfiles de residentes y técnicos

## 1. Objetivo

Verificar que el administrador pueda dar de baja (inhabilitar) y habilitar cuentas de residentes y técnicos, solicitando confirmación, impidiendo el acceso y conservando la información histórica, liberando la vivienda en el caso de residentes.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción de inhabilitar/habilitar en la lista |
| Confirmación | Diálogos de confirmación |
| Estado | Cuenta pasa a baja/deshabilitada y no puede iniciar sesión |
| Histórico | Incidencias y registros se conservan |
| Vivienda | La vivienda queda disponible al dar de baja a un residente |
| Reactivación | Habilitar una cuenta inactiva |

**No incluye**

- Eliminación física de datos.
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.6 | Pruebas |
|---|---|---|
| CA-1 | Confirmación antes de dar de baja | PM-02, PM-06 |
| CA-2 | Cuenta dada de baja no inicia sesión | PM-04 |
| CA-3 | Conservar incidencias, reportes y sanciones | PM-10 |
| CA-4 | Referencia al usuario en histórico | PM-10 |
| CA-5 | Vivienda disponible al dar de baja a residente | PM-09 |

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
| Residente activo | Residente con vivienda asignada |
| Técnico activo | Técnico con especialidad |
| Residente inactivo | Residente dado de baja |
| Técnico inactivo | Técnico dado de baja |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso a inhabilitar | En la lista pulsar "Inhabilitar" en un residente o técnico activo | Se abre el modal de confirmación |
| PM-02 | Confirmar inhabilitación | En el modal pulsar "Confirmar" | La cuenta se inhabilita y se muestra mensaje de éxito |
| PM-03 | Cancelar inhabilitación | En el modal pulsar "Cancelar" | No se realizan cambios |
| PM-04 | Inicio de sesión bloqueado | Intentar iniciar sesión con cuenta inhabilitada | El sistema impide el acceso |
| PM-05 | Acceso a habilitar | En la lista pulsar "Habilitar" en una cuenta inactiva | Se abre el modal de confirmación |
| PM-06 | Confirmar habilitación | En el modal pulsar "Confirmar" | La cuenta se habilita y se muestra mensaje de éxito |
| PM-07 | Cancelar habilitación | En el modal pulsar "Cancelar" | No se realizan cambios |
| PM-08 | Vivienda disponible | Dar de baja a un residente con vivienda | La vivienda queda disponible para otro residente |
| PM-09 | Lista actualizada | Dar de baja o habilitar una cuenta | La lista refleja el nuevo estado |
| PM-10 | Histórico conservado | Dar de baja a un usuario con incidencias o sanciones | Los registros históricos se conservan con referencia al usuario |
| PM-11 | Responsive móvil | Inhabilitar/habilitar en teléfono | El modal se muestra correctamente |
| PM-12 | Responsive PC | Inhabilitar/habilitar en escritorio | El modal se muestra correctamente |

## 8. Criterios de aprobación

- La inhabilitación y habilitación funcionan correctamente.
- Las confirmaciones se muestran.
- El acceso se bloquea y se restaura correctamente.
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
