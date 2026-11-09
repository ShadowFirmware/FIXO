# Plan de pruebas — Mejoras generales de la interfaz

| Dato | Valor |
|---|---|
| Módulos | 2. Residente, 3. Técnico y 4. Administrador |
| Rama | `feature/mejoras-generales` |
| Fecha | 09/11/2026 |

## 1. Objetivo

Verificar las mejoras de interfaz pedidas después de terminar las HU:

1. El menú del administrador muestra siempre las mismas secciones.
2. El texto del filtro seleccionado se lee sobre el fondo azul.
3. Residentes y Técnicos están juntos en la sección **Usuarios**, con un formulario que se adapta al rol.
4. En el teléfono, los formularios y detalles se abren como pantalla completa que entra deslizándose desde abajo; en la web, como ventana.
5. Los formularios marcan cada dato que falta o no es válido y avisan al intentar enviarlos.
6. En la web, el panel del administrador tiene una barra lateral fija y tablas a todo lo ancho.
7. Se agregaron las pruebas que faltaban (HU 2.1, 4.2, 4.3 a 4.7) y se actualizaron sus planes.

## 2. Alcance

**Incluye**

| Mejora | Qué se prueba |
|---|---|
| Menú | Las nueve pantallas del administrador usan el mismo menú; "Inicio" siempre aparece y la sección abierta se marca |
| Filtros | Texto, palomita e ícono en blanco cuando el filtro está seleccionado |
| Usuarios | Lista conjunta, filtro por rol, búsqueda, registro con rol Residente o Técnico, edición, baja y habilitación |
| Pantalla completa | Usuarios, Residencias, Asignar, Rechazar, detalle de pendientes y detalle del historial |
| Validaciones | Mensaje por campo y aviso "Revisa los campos marcados en rojo." en Usuarios, Residencias, registro de incidencia, perfiles y login |
| Web | Barra lateral, encabezado con acciones y tablas en tarjetas |

**No incluye**

- Las confirmaciones de sí o no (por ejemplo, "¿Dar de baja?"): siguen como ventana pequeña también en el teléfono.
- Los selectores de fecha y hora, y la hoja para elegir cámara o galería, que ya son el patrón del sistema.

## 3. Casos de prueba unitarios

```bash
flutter test test/unitarias/admin/admin_users_test.dart test/unitarias/admin/admin_navigation_test.dart test/unitarias/admin/housing_admin_test.dart test/unitarias/admin/admin_edit_profile_screen_test.dart test/unitarias/shared/ui_improvements_test.dart
```

| ID | Mejora | Caso | Resultado esperado |
|---|---|---|---|
| PU-574 a PU-581 | Usuarios | Lista, filtros, registro, validación, web y baja | Ver el plan de las HU 4.3 a 4.6 |
| PU-582 a PU-584 | Validaciones | Editar perfil del administrador | Ver el plan de la HU 4.2 |
| PU-585 a PU-589 | Pantalla completa, web | Residencias | Ver el plan de la HU 4.7 |
| PU-590, PU-596 | Usuarios | Editar con confirmación y descartar cambios | Ver el plan de la HU 4.5 |
| PU-591 | Menú | Usuarios y Residencias en el teléfono | El menú tiene las siete secciones y Cerrar sesión; la sección abierta está marcada |
| PU-592 | Web | Usuarios en pantalla ancha | Sin botón de menú; barra lateral con todas las secciones y la actual marcada |
| PU-593 | Filtros | Estilo del filtro seleccionado | Fondo azul con texto y palomita en blanco; sin seleccionar, texto oscuro |
| PU-594 | Pantalla completa | Abrir un formulario en el teléfono y en la web | Teléfono: pantalla completa con botones abajo y botón Cerrar. Web: ventana |
| PU-595 | Validaciones | Registrar incidencia sin datos | Mensaje en cada campo y aviso "Revisa los campos marcados en rojo."; no se registra |

## 4. Casos de prueba manuales

| ID | Mejora | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Menú | Como administrador, abrir el menú desde cada sección (Inicio, Reportes pendientes, Historial, Estadísticas, Usuarios, Residencias, Ver perfil) | Siempre aparecen las mismas secciones, el nombre del administrador y Cerrar sesión; la sección abierta se marca |
| PM-02 | Menú | Navegar por varias secciones y pulsar Atrás | Atrás regresa a Inicio, no a todas las secciones visitadas |
| PM-03 | Filtros | Seleccionar filtros en Reportes pendientes, Historial (administrador, residente y técnico), Usuarios y Registrar incidencia | El texto y el ícono del filtro seleccionado se leen en blanco sobre azul |
| PM-04 | Usuarios | Abrir "Usuarios", cambiar entre Todos, Residentes y Técnicos y buscar por nombre | La lista se filtra y los conteos coinciden |
| PM-05 | Usuarios | Pulsar "Agregar" y cambiar el rol | Con Residente pide vivienda; con Técnico pide especialidad |
| PM-06 | Pantalla completa | En el teléfono, abrir Agregar usuario, Agregar residencia, Asignar, Rechazar y el detalle de un reporte | Cada uno entra deslizándose desde abajo, ocupa la pantalla y se cierra con la X |
| PM-07 | Pantalla completa | En la PC, abrir los mismos formularios | Se abren como ventana |
| PM-08 | Validaciones | Enviar vacíos los formularios de Usuarios, Residencias, Registrar incidencia, Modificar perfil (los tres roles) e Iniciar sesión | Cada campo muestra su mensaje y aparece "Revisa los campos marcados en rojo." |
| PM-09 | Validaciones | Registrar un usuario con correo repetido y una residencia repetida | El error del servidor aparece arriba del formulario, sin cerrarlo |
| PM-10 | Web | Abrir el panel del administrador en la PC | Barra lateral fija con FIXO y las secciones; encabezado con título y botones; tablas a todo lo ancho |
| PM-11 | Teléfono | Usar la app de residente, técnico y administrador en un teléfono pequeño | No hay textos cortados ni franjas amarillas de desborde |

## 5. Resultados

### Automatizadas — 09/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| Mejoras (PU-574 a PU-596) | 23 | Aprobadas |
| Proyecto completo (`flutter test`) | 302 | Aprobadas |

### Manuales

Las observaciones indican qué prueba automatizada ya cubre el caso. Aun así, cada caso debe ejecutarse en el dispositivo.

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Pendiente | | | Automatizada en PU-591 (Usuarios y Residencias) |
| PM-02 | Pendiente | | | |
| PM-03 | Pendiente | | | Automatizada en PU-593 (estilo del tema) |
| PM-04 | Pendiente | | | Automatizada en PU-574 y PU-577 |
| PM-05 | Pendiente | | | Automatizada en PU-577 |
| PM-06 | Pendiente | | | Automatizada en PU-577, PU-587 y PU-594 |
| PM-07 | Pendiente | | | Automatizada en PU-580, PU-589 y PU-594 |
| PM-08 | Pendiente | | | Automatizada en PU-578, PU-583, PU-587 y PU-595 |
| PM-09 | Pendiente | | | Automatizada en PU-579 y PU-587 |
| PM-10 | Pendiente | | | Automatizada en PU-580, PU-589 y PU-592 |
| PM-11 | Pendiente | | | |
