# Plan de pruebas — HU 2.1 Consultar perfil del residente

| Dato | Valor |
|---|---|
| Módulo | 2. Residente |
| Historia de usuario | HU 2.1 Consultar perfil |
| Rama | `feature/HU-2.1-consultar-perfil` (plan agregado en `feature/mejoras-generales`) |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar que el residente pueda consultar su perfil con su nombre, correo, teléfono, vivienda asignada, estado de la cuenta y fecha de registro, que los datos faltantes se indiquen como "Sin registrar" y que nunca se muestren datos de otra sesión.

> Este plan se agregó el 09/11/2026: la HU 2.1 ya tenía pruebas automatizadas, pero no tenía plan de pruebas.

## 2. Alcance

**Incluye**

| Qué se prueba |
|---|
| Pestaña "Perfil" del residente con su información personal y su vivienda |
| Iniciales del avatar, estado de la cuenta y fecha de registro en español |
| Datos vacíos, vivienda inexistente o que no se puede consultar |
| Cambio o cierre de sesión |
| Botones "Modificar perfil" (HU 2.2) y "Cerrar sesión" |

**No incluye**

- La modificación del perfil (HU 2.2).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | El residente consulta su información personal | PU-36, PU-37, PM-01, PM-02 |
| CA-2 | Se muestra la vivienda asignada | PU-36, PU-43, PU-44, PU-47 a PU-50, PM-03 |
| CA-3 | Los datos faltantes se indican claramente | PU-38, PU-48, PU-49, PM-04 |
| CA-4 | Se muestran el estado de la cuenta y la fecha de registro | PU-39, PU-40, PM-02 |
| CA-5 | Solo se ven los datos del residente en sesión | PU-41, PU-42, PU-51, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias (PU) | `flutter_test` | `test/unitarias/resident/profile_view_model_test.dart`, `test/unitarias/housing/housing_test.dart` | Simulado con fakes |
| Manuales (PM) | App en emulador, teléfono o navegador | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Android (emulador o dispositivo físico) y web (Chrome)
- Firebase: proyecto `fixo-a7763`

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente con vivienda | Residente activo con vivienda "Torre A – 4B" |
| Residente sin teléfono | Residente activo con el campo `telefono` vacío |
| Residente sin vivienda | Residente activo sin `viviendaId` |

## 7. Casos de prueba unitarios

```bash
flutter test test/unitarias/resident/profile_view_model_test.dart test/unitarias/housing/housing_test.dart
```

| ID | Caso | Resultado esperado |
|---|---|---|
| PU-36 | Residente con todos sus datos | Nombre, correo, teléfono y vivienda |
| PU-37 | Iniciales del avatar | Usan las dos primeras palabras del nombre |
| PU-38 | Datos vacíos | Se muestran como "Sin registrar" |
| PU-39 | Estado de la cuenta | Se muestra en español |
| PU-40 | Fecha de registro | Se muestra en español |
| PU-41 | Sin sesión | No se muestran datos de ningún usuario |
| PU-42 | Cambio o cierre de sesión | Se actualizan los datos mostrados |
| PU-43, PU-44 | Nombre de la vivienda | "Edificio – Número", o el tipo y el número si no hay edificio |
| PU-47 a PU-49 | Consulta de la vivienda | "Cargando…" mientras consulta; "No disponible" si no existe o falla |
| PU-50, PU-51 | Cambio de residente | Se consulta la vivienda nueva y se ignora la respuesta de la sesión anterior |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el perfil | Como residente, abrir la pestaña "Perfil" | Se ven el avatar con las iniciales, el nombre y el correo |
| PM-02 | Información personal | Revisar las secciones | Nombre completo, correo, teléfono, estado de la cuenta y "Miembro desde" en español |
| PM-03 | Vivienda | Revisar "Vivienda asignada" | Muestra "Torre A – 4B" |
| PM-04 | Datos faltantes | Entrar con el residente sin teléfono y con el residente sin vivienda | Los datos faltantes aparecen como "Sin registrar" |
| PM-05 | Modificar perfil | Pulsar "Modificar perfil" | Se abre el formulario de la HU 2.2 |
| PM-06 | Cerrar sesión | Pulsar "Cerrar sesión" y entrar con otro residente | Regresa al inicio de sesión; el perfil del segundo residente no muestra datos del primero |
| PM-07 | Diseño | Abrir el perfil en el teléfono y en la PC | En el teléfono ocupa el ancho de la pantalla; en la PC queda centrado |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-07 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 2.1 (PU-36 a PU-44 y PU-47 a PU-51) | 14 | Aprobadas |
| Proyecto completo (`flutter test`) | 307 | Aprobadas |

### Manuales

Las observaciones indican qué prueba automatizada ya cubre el caso con datos simulados. Aun así, cada caso debe ejecutarse en el dispositivo con Firebase real.

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Pendiente | | | Automatizada en PU-36 y PU-37 (ViewModel) |
| PM-02 | Pendiente | | | Automatizada en PU-36, PU-39 y PU-40 (ViewModel) |
| PM-03 | Pendiente | | | Automatizada en PU-36 y PU-43 |
| PM-04 | Pendiente | | | Automatizada en PU-38 |
| PM-05 | Pendiente | | | |
| PM-06 | Pendiente | | | Automatizada en PU-42 y PU-51 |
| PM-07 | Pendiente | | | |
