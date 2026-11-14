# Plan de pruebas — HU 5.1 Comunicarse mediante chat dentro de una incidencia

| Dato | Valor |
|---|---|
| Módulo | 5. Comunicación |
| Historia de usuario | HU 5.1 Comunicarse mediante chat dentro de una incidencia (#283) |
| Tarea | T 5.1.11 Probar el chat de la incidencia |
| Rama | `feature/HU-5.1-Comunicarse-mediante-chat-dentro-de-una-incidencia` |
| Fecha | 12/11/2026 |

## 1. Objetivo

Verificar que el residente y el técnico de una incidencia puedan comunicarse por un chat dentro de ella. Los mensajes deben llegar en tiempo real y mostrar quién los envió y cuándo. El historial debe conservarse. El acceso debe limitarse al técnico asignado y al residente activo de la vivienda, y actualizarse cuando cambie alguno de los dos. Cuando la incidencia termine, el chat debe quedar de solo lectura.

## 2. Alcance

**Incluye**

| Tarea | Qué se prueba |
|---|---|
| T 5.1.1 | Pantalla del chat: burbujas propias y de la otra persona, campo para escribir, avisos y botón "Chat" en el detalle de la incidencia (residente y técnico) |
| T 5.1.2 | Subcolección `incidencias/{id}/mensajes` con `autorId`, `autorNombre`, `autorRol`, `texto` y `fecha` del servidor |
| T 5.1.3 | Consulta de los mensajes del más antiguo al más reciente |
| T 5.1.4 | Acceso: técnico asignado y residente activo de la vivienda, con la cuenta activa |
| T 5.1.5 | Envío en una transacción que vuelve a revisar el acceso con los datos actuales |
| T 5.1.6 | Recepción en tiempo real |
| T 5.1.7 | Nombre y rol de quien envió el mensaje, hora y separadores por día ("Hoy", "Ayer" o la fecha) |
| T 5.1.8 | Historial: los mensajes no se editan ni se borran y guardan el nombre y rol del autor |
| T 5.1.9 | El acceso se actualiza en cuanto cambia el residente de la vivienda o el técnico asignado |
| T 5.1.10 | Solo lectura cuando la incidencia está resuelta (o con `chatCerrado`), rechazada, o todavía sin técnico |

**No incluye**

- Notificaciones de mensajes nuevos.
- Archivos o imágenes en el chat.
- Reglas de seguridad de Firestore (entorno de desarrollo): las reglas actuales permiten leer y escribir a cualquier usuario con sesión, así que la restricción se hace en la app.

## 3. Criterios de aceptación cubiertos

| # | Criterio | Pruebas |
|---|---|---|
| CA-1 | El residente y el técnico de la incidencia pueden intercambiar mensajes dentro de ella | PU-611, PU-615, PU-618, PM-01, PM-02 |
| CA-2 | Solo el técnico asignado y el residente activo de la vivienda pueden ver el chat | PU-604, PU-607, PU-617, PM-05 |
| CA-3 | Los mensajes se reciben en tiempo real | PU-608, PM-02 |
| CA-4 | Cada mensaje muestra quién lo envió y la fecha y hora | PU-603, PU-613, PU-615, PM-03 |
| CA-5 | El historial de mensajes se conserva | PU-603, PU-610, PM-04 |
| CA-6 | Si cambia el residente de la vivienda, el nuevo residente continúa el chat y el anterior deja de tener acceso | PU-605, PU-610, PM-05 |
| CA-7 | Al finalizar la incidencia, el chat queda en modo de solo lectura | PU-606, PU-612, PU-616, PM-06 |

## 4. Tipos de prueba

| Tipo | Herramienta | Ubicación | Firebase |
|---|---|---|---|
| Unitarias y de widgets (PU) | `flutter_test` | `test/unitarias/communication/` | Simulado con fakes, sin conexión |
| Manuales (PM) | App en navegador, emulador o teléfono | — | Proyecto real `fixo-a7763` |

## 5. Entorno

- Flutter 3.47.4 / Dart 3.13.3
- Web (Chrome), Android (emulador o dispositivo físico)
- Firebase: proyecto `fixo-a7763` (plan Spark), Firestore con reglas de desarrollo.

## 6. Datos de prueba

| Dato | Valor |
|---|---|
| Residente | Residente activo de una vivienda, con una incidencia Asignada o En proceso |
| Técnico | Técnico asignado a esa incidencia, con sesión abierta en otro dispositivo o navegador |
| Otro residente | Residente activo sin vivienda asignada, para el cambio de residente |
| Incidencias | Una Resuelta y una Pendiente sin técnico del mismo residente |

## 7. Casos de prueba unitarios

Para ejecutarlos:

```bash
flutter test test/unitarias/communication/chat_test.dart
```

| ID | Tarea | Caso | Resultado esperado |
|---|---|---|---|
| PU-602 | T 5.1.2, T 5.1.5 | Texto vacío, solo espacios, de 1000 y de 1001 caracteres | Se piden "Escribe un mensaje" y el límite de 1000 caracteres; los espacios de los extremos no cuentan |
| PU-603 | T 5.1.2, T 5.1.7, T 5.1.8 | Leer documentos válidos, sin fecha e inválidos; crear uno nuevo | Se leen autor, nombre, rol, texto y fecha; sin fecha está "Enviando"; los inválidos se rechazan; el nuevo guarda el texto sin espacios y la fecha del servidor |
| PU-604 | T 5.1.4 | Técnico asignado, otro técnico, residente activo, administrador, sin sesión y cuentas suspendida, deshabilitada o dada de baja | Solo el técnico asignado y el residente activo con la cuenta activa ven el chat; cada caso tiene su mensaje |
| PU-605 | T 5.1.9 | La vivienda cambia de residente o se queda sin residente | El nuevo residente usa el chat aunque no haya registrado la incidencia; el anterior lo pierde |
| PU-606 | T 5.1.10 | Incidencia Resuelta, con `chatCerrado`, Rechazada, Pendiente sin técnico, Asignada y En proceso | Las tres primeras y la Pendiente son de solo lectura con su motivo; Asignada y En proceso permiten escribir |
| PU-607 | T 5.1.3, T 5.1.4 | Abrir el chat sin acceso o de una incidencia que no existe | Se muestra el motivo y no se consultan los mensajes |
| PU-608 | T 5.1.3, T 5.1.6 | Llegan mensajes del técnico y del residente | Se muestran en orden al llegar, sin volver a consultar; un cambio en la incidencia no reinicia los mensajes |
| PU-609 | T 5.1.3 | Falla la carga del chat o de los mensajes; reintentar | Se muestra el error y "Reintentar" vuelve a cargar |
| PU-610 | T 5.1.8, T 5.1.9 | Con el chat abierto, la vivienda pasa a otro residente y regresa; reasignan al técnico | Se cierra el chat al perder el acceso y, al recuperarlo, vuelve a verse el historial; el técnico reasignado lo pierde |
| PU-611 | T 5.1.5 | Enviar vacío, un mensaje correcto, dos seguidos y con errores | Se valida el texto; se envía sin espacios con el UID de la sesión; no se envía otro mientras tanto; cada error tiene su mensaje |
| PU-612 | T 5.1.10 | El técnico finaliza la incidencia con el chat abierto | Los mensajes siguen visibles, ya no se puede enviar y se explica por qué |
| PU-613 | T 5.1.7 | Etiquetas del autor, del día y de la hora | "Nombre · Técnico", "Hoy", "Ayer" o la fecha, "4:05 p. m."; el separador solo aparece en el primer mensaje de cada día |
| PU-614 | T 5.1.5, T 5.1.6 | Errores de Firestore al enviar y al escuchar | Sin acceso se muestra el motivo; sin conexión, el aviso de conexión; los demás, un mensaje general |
| PU-615 | T 5.1.1, T 5.1.5, T 5.1.7, T 5.1.8 | Pantalla con y sin mensajes; escribir y enviar; envío fallido | Se ven el folio y el título, los mensajes con autor, hora y día, y el aviso del historial; el botón se habilita al escribir; al enviar se limpia el campo; si falla, se conserva el texto y se avisa |
| PU-616 | T 5.1.10 | Pantalla de una incidencia Resuelta | Se ven los mensajes y el aviso de solo lectura en lugar del campo |
| PU-617 | T 5.1.4 | Pantalla sin acceso y con error | Sin acceso se ve el candado y el motivo, sin campo; con error se puede reintentar |
| PU-618 | T 5.1.1 | Tocar "Chat" en el detalle de la incidencia del técnico | Se abre el chat de esa incidencia |

## 8. Casos de prueba manuales

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| PM-01 | Abrir el chat | Como residente y como técnico, abrir el detalle de la incidencia y tocar "Chat" | Se abre el chat con el folio y el título; sin mensajes, invita a escribir |
| PM-02 | Enviar y recibir | Con el residente y el técnico en dispositivos distintos, enviar mensajes de ida y vuelta | Cada mensaje aparece en el otro dispositivo sin recargar; los propios a la derecha y los del otro a la izquierda |
| PM-03 | Autor y fecha | Revisar los mensajes recibidos y los de días anteriores | Muestran "Nombre · Rol" y la hora; los días se separan con "Hoy", "Ayer" o la fecha |
| PM-04 | Historial | Salir del chat y volver; revisar `incidencias/{id}/mensajes` en Firestore | Siguen todos los mensajes; cada documento tiene `autorId`, `autorNombre`, `autorRol`, `texto` y `fecha` |
| PM-05 | Cambio de residente | Con el chat abierto, el administrador asigna la vivienda a otro residente | El residente anterior pierde el chat en ese momento; el nuevo lo abre y ve todo el historial |
| PM-06 | Solo lectura | Con el chat abierto, el técnico finaliza la incidencia; abrir también una Pendiente sin técnico | Se cambia el campo por el aviso de solo lectura y los mensajes siguen visibles; en la Pendiente se avisa que se podrá escribir al asignar un técnico |
| PM-07 | Sin conexión | Desactivar la conexión e intentar enviar | Se muestra el aviso de conexión y el texto no se borra |

## 9. Criterios de aprobación

- Todas las pruebas unitarias pasan (`flutter test`).
- Los casos manuales PM-01 a PM-07 se cumplen.
- No hay defectos abiertos de severidad alta.

## 10. Resultados

### Automatizadas — 12/11/2026

| Conjunto | Pruebas | Resultado |
|---|---|---|
| HU 5.1 (PU-602 a PU-618) | 17 | Aprobadas |
| Proyecto completo (`flutter test`) | 324 | Aprobadas |

### Manuales

| ID | Resultado | Fecha | Responsable | Observaciones |
|---|---|---|---|---|
| PM-01 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-02 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-03 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-04 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-05 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-06 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
| PM-07 | Aprobada | 12/11/2026 | Luis Pablo Pérez Fuentes | Sin observaciones |
