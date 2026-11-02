---
| Dato | Valor |
|---|---|
| Módulo | 4. Administrador |
| Historia de usuario | HU 4.7 Gestionar lugares de residencia |
| Rama | `FEATURE/HU-4.7-Gestionar-lugares-de-residencia` |
| Fecha | 01/11/2026 |
---

# Plan de pruebas — HU 4.7 Gestionar lugares de residencia

## 1. Objetivo

Verificar que el administrador pueda consultar, registrar, modificar y marcar como activas o inactivas las viviendas del sistema, que no se registren viviendas duplicadas dentro del mismo edificio o sección, que una vivienda inactiva no admita incidencias nuevas sin afectar las abiertas, y que al registrar o modificar un residente solo se puedan seleccionar viviendas disponibles.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| Acceso | Opción "Residencias" en el menú de hamburguesa |
| Consulta | Tabla de residencias con tipo, edificio/sección, número, estado y ocupación |
| Registro | Botón para agregar y formulario de registro |
| Validación | Campos obligatorios y viviendas duplicadas |
| Edición | Modificar la información de una vivienda |
| Estado | Marcar una vivienda como activa o inactiva |
| Incidencias | Bloqueo de incidencias nuevas en viviendas inactivas |
| Residentes | Selección de viviendas disponibles al registrar o modificar un residente |

**No incluye**

- Eliminación de viviendas (no forma parte de la historia).
- Reglas de seguridad de Firestore (entorno de desarrollo).

## 3. Criterios de aceptación cubiertos

| # | Criterio de la HU 4.7 | Pruebas |
|---|---|---|
| CA-1 | Consultar los lugares de residencia registrados | PM-01, PM-02, PM-03 |
| CA-2 | Registrar nuevas viviendas | PM-04, PM-05, PM-06 |
| CA-3 | Cada vivienda contiene tipo, edificio/torre/sección (cuando corresponda) y número | PM-05, PM-06, PM-07, PM-08 |
| CA-4 | No registrar dos viviendas con la misma identificación en el mismo edificio o sección | PM-09, PM-10, PM-11, PM-15 |
| CA-5 | Modificar la información de una vivienda | PM-12, PM-13, PM-14 |
| CA-6 | Marcar una vivienda como activa o inactiva | PM-16, PM-17, PM-18, PM-19 |
| CA-7 | Las incidencias abiertas de una vivienda inactiva continúan su flujo | PM-20 |
| CA-8 | No se permiten incidencias nuevas en una vivienda inactiva | PM-21, PM-22 |
| CA-9 | Al registrar o modificar un residente se selecciona una vivienda disponible y registrada | PM-23, PM-24, PM-25 |

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
| Departamento existente | Tipo `departamento`, edificio "Torre A", número "4B", activa |
| Casa existente | Tipo `casa`, sin edificio, número "12", activa |
| Vivienda ocupada | Vivienda activa con un residente asignado |
| Vivienda con incidencia abierta | Vivienda activa con una incidencia en estado "Pendiente" o "En proceso" |
| Residente de prueba | Residente activo con vivienda asignada, para registrar incidencias |

## 7. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Acceso desde el menú | Iniciar sesión como administrador, abrir el menú de hamburguesa y pulsar "Residencias" | Se abre la pantalla "Residencias" |
| PM-02 | Consultar residencias | Abrir la pantalla "Residencias" con viviendas registradas | La tabla muestra tipo, edificio/sección, número, estado (Activa/Inactiva), ocupación (Disponible/Ocupada) y opciones Ver, Editar e Inactivar/Activar |
| PM-03 | Ver detalle | Pulsar "Ver" en una vivienda | Se muestra un modal con tipo, edificio/sección, número, estado y ocupación |
| PM-04 | Abrir formulario de registro | Pulsar el botón de agregar residencia en la parte derecha de la barra superior | Se abre el formulario "Registrar residencia" |
| PM-05 | Registrar departamento | Elegir "Departamento", escribir edificio "Torre B" y número "101", pulsar "Registrar" | Se cierra el formulario, se muestra "Residencia registrada correctamente." y la vivienda aparece en la tabla como Activa y Disponible |
| PM-06 | Registrar casa sin edificio | Elegir "Casa", dejar el edificio vacío, escribir número "15" y pulsar "Registrar" | Se registra la vivienda y en la tabla el edificio aparece como "—" |
| PM-07 | Tipo obligatorio | Dejar el tipo sin seleccionar y pulsar "Registrar" | Se muestra "Selecciona el tipo de residencia" y no se registra |
| PM-08 | Número obligatorio | Dejar el número vacío (o solo espacios) y pulsar "Registrar" | Se muestra "Ingresa el número o identificador" y no se registra |
| PM-09 | Duplicado en el mismo edificio | Registrar un departamento en "Torre A" con número "4B" | Se muestra "Ya existe una vivienda con ese número en el mismo edificio o sección." dentro del formulario y no se registra |
| PM-10 | Duplicado sin distinguir mayúsculas ni espacios | Registrar edificio " torre a " con número "4b" | Se rechaza por duplicado |
| PM-11 | Mismo número en otro edificio | Registrar un departamento en "Torre C" con número "4B" | Se registra correctamente |
| PM-12 | Abrir edición | Pulsar "Editar" en una vivienda | Se abre "Editar residencia" con los datos actuales cargados |
| PM-13 | Guardar cambios | Cambiar el número de la vivienda a uno libre y pulsar "Guardar" | Se muestra "Residencia actualizada correctamente." y la tabla refleja el cambio |
| PM-14 | Descartar cambios | Modificar un campo y pulsar "Cancelar", luego "Descartar" | Se cierra el formulario sin guardar cambios |
| PM-15 | Edición duplicada | Editar una vivienda para que quede con el mismo edificio y número que otra existente | Se muestra el mensaje de duplicado y no se guarda |
| PM-16 | Inactivar vivienda | Pulsar "Inactivar" en una vivienda activa y confirmar | Se muestra "Residencia marcada como inactiva." y el estado cambia a Inactiva |
| PM-17 | Cancelar inactivación | Pulsar "Inactivar" y luego "Cancelar" | No se realizan cambios |
| PM-18 | Activar vivienda | Pulsar "Activar" en una vivienda inactiva y confirmar | Se muestra "Residencia activada correctamente." y el estado cambia a Activa |
| PM-19 | Mensaje de confirmación | Pulsar "Inactivar" en una vivienda activa | El modal avisa que las incidencias abiertas seguirán su atención y que no se podrán registrar nuevas |
| PM-20 | Incidencias abiertas continúan | Inactivar la vivienda con incidencia abierta y revisar la incidencia como residente | La incidencia conserva su estado, se puede consultar y sigue su flujo normal de atención |
| PM-21 | Incidencia nueva bloqueada | Inactivar la vivienda del residente de prueba e intentar registrar una incidencia como ese residente | Se muestra "Tu vivienda está inactiva, así que no se pueden registrar incidencias nuevas. Contacta al administrador." y no se registra |
| PM-22 | Incidencia permitida tras reactivar | Activar de nuevo la vivienda y registrar una incidencia | La incidencia se registra correctamente |
| PM-23 | Viviendas disponibles al registrar residente | En "Residentes", abrir el formulario de registro y desplegar "Vivienda" | Solo aparecen viviendas activas y sin residente asignado |
| PM-24 | Viviendas disponibles al modificar residente | Editar un residente y desplegar "Vivienda" | Aparecen su vivienda actual y las viviendas activas disponibles; no aparecen inactivas ni ocupadas por otros |
| PM-25 | Residente con vivienda inactiva | Inactivar la vivienda de un residente y abrir su edición en "Residentes" | El formulario abre sin errores mostrando su vivienda actual, y en la tabla de residentes se ve el nombre de la vivienda |
| PM-26 | Ocupación actualizada | Registrar un residente en una vivienda disponible y volver a "Residencias" | La vivienda aparece como Ocupada |
| PM-27 | Lista vacía | Abrir "Residencias" sin viviendas registradas | Se muestra "No hay residencias registradas" |
| PM-28 | Responsive móvil | Abrir "Residencias" en teléfono | Se muestran tarjetas con menú de opciones Ver detalles, Editar e Inactivar/Activar |
| PM-29 | Responsive PC | Abrir "Residencias" en escritorio | Se muestra la tabla completa con sus columnas y opciones |

## 8. Criterios de aprobación

- El registro, la consulta, la edición y el cambio de estado funcionan correctamente.
- No es posible registrar ni editar viviendas duplicadas en el mismo edificio o sección.
- Una vivienda inactiva conserva sus incidencias abiertas y bloquea las nuevas.
- Al registrar o modificar residentes solo se ofrecen viviendas disponibles.
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
| PM-13 | Pendiente | | | |
| PM-14 | Pendiente | | | |
| PM-15 | Pendiente | | | |
| PM-16 | Pendiente | | | |
| PM-17 | Pendiente | | | |
| PM-18 | Pendiente | | | |
| PM-19 | Pendiente | | | |
| PM-20 | Pendiente | | | |
| PM-21 | Pendiente | | | |
| PM-22 | Pendiente | | | |
| PM-23 | Pendiente | | | |
| PM-24 | Pendiente | | | |
| PM-25 | Pendiente | | | |
| PM-26 | Pendiente | | | |
| PM-27 | Pendiente | | | |
| PM-28 | Pendiente | | | |
| PM-29 | Pendiente | | | |
