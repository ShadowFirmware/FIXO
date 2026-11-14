# Plan de pruebas — HU 4.6 Dar de baja perfiles de residentes y técnicos

| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.6 Dar de baja perfiles de residentes y técnicos |
| Rama | `FEATURE/HU-4.6-Dar-de-baja` (actualizado en `feature/mejoras-generales`) |
| Fecha | 01/11/2026 — actualizado el 09/11/2026 |

## 1. Objetivo

Verificar que el administrador pueda dar de baja (y volver a habilitar) a residentes y técnicos con confirmación previa, que una cuenta dada de baja no pueda iniciar sesión, que se conserve su histórico y que la vivienda del residente quede disponible.

> **Cambio del 09/11/2026:** la baja se hace desde la sección **Usuarios** con la opción "Dar de baja" (antes "Inhabilitar") del menú de cada usuario. La cuenta aparece como "Dada de baja" y la opción cambia a "Habilitar".

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Baja | Opción "Dar de baja" con confirmación |
| Habilitar | Opción "Habilitar" con confirmación |
| Acceso | Una cuenta dada de baja no inicia sesión |
| Vivienda | Queda disponible al dar de baja a un residente |

**No incluye**

- Registro (HU 4.3 y 4.4) y edición (HU 4.5).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.6 | Pruebas |
|---|---|---|
| CA-1 | Confirmación antes de dar de baja | PU-581, PM-02, PM-06 |
| CA-2 | Cuenta dada de baja no inicia sesión | PM-04 |
| CA-3 | Conservar incidencias, reportes y sanciones | PM-10 |
| CA-4 | Referencia al usuario en histórico | PM-10 |
| CA-5 | Vivienda disponible al dar de baja a residente | PU-576, PM-08 |

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
| PU-576 | Dar de baja a un residente y habilitar a un técnico | Cada acción usa el repositorio de su rol y avisa con su mensaje |
| PU-580 | Ver la lista en la web | La cuenta dada de baja aparece como "Dada de baja" |
| PU-581 | Pulsar "Dar de baja" y confirmar | Explica que ya no podrá iniciar sesión; al confirmar se da de baja y avisa "Técnico dado de baja correctamente." |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso a dar de baja | En "Usuarios", abrir el menú de un usuario activo y pulsar "Dar de baja" | Se pide confirmación |
| PM-02 | Confirmar baja | Pulsar "Dar de baja" en la confirmación | La cuenta queda "Dada de baja" y se muestra el mensaje de éxito |
| PM-03 | Cancelar baja | Pulsar "Cancelar" en la confirmación | No se realizan cambios |
| PM-04 | Inicio de sesión bloqueado | Intentar iniciar sesión con la cuenta dada de baja | El sistema impide el acceso |
| PM-05 | Acceso a habilitar | Abrir el menú de una cuenta dada de baja y pulsar "Habilitar" | Se pide confirmación |
| PM-06 | Confirmar habilitación | Pulsar "Habilitar" en la confirmación | La cuenta vuelve a "Activa" y se muestra el mensaje de éxito |
| PM-07 | Cancelar habilitación | Pulsar "Cancelar" en la confirmación | No se realizan cambios |
| PM-08 | Vivienda disponible | Dar de baja a un residente con vivienda | La vivienda queda disponible para otro residente |
| PM-09 | Lista actualizada | Dar de baja o habilitar una cuenta | La etiqueta de la cuenta cambia en la lista |
| PM-10 | Histórico conservado | Dar de baja a un usuario con incidencias | Las incidencias se conservan con su nombre en el historial |

## 8. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-10 se cumplen.
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
