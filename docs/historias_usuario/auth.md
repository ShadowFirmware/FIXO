# Módulo 1. Autenticación

## 1.1 Iniciar sesión

**Prioridad:** Alta

Como usuario, quiero iniciar sesión en el sistema mediante mis credenciales para acceder a las funcionalidades correspondientes a mi rol.

### Criterios de aceptación

- El usuario debe poder ingresar su correo electrónico y contraseña.
- El sistema debe validar que las credenciales ingresadas correspondan a un usuario registrado.
- Si las credenciales son correctas, el sistema debe permitir el acceso.
- El usuario debe ser dirigido a las funcionalidades correspondientes a su rol: Residente, Técnico o Administrador.
- Si el correo electrónico o la contraseña son incorrectos, el sistema debe mostrar un mensaje indicando que las credenciales no son válidas.
- El sistema no debe permitir el acceso a usuarios que no se encuentren registrados.

## 1.2 Recuperar contraseña

**Prioridad:** Alta

Como usuario, quiero recuperar mi contraseña mediante un código de verificación enviado a mi correo electrónico registrado, para restablecer de forma segura el acceso a mi cuenta.

### Criterios de aceptación

- El usuario debe poder seleccionar la opción “Olvidé mi contraseña” desde la pantalla de inicio de sesión.
- El sistema debe solicitar el correo electrónico asociado a la cuenta.
- Si el correo corresponde a una cuenta registrada, el sistema debe enviar un código de verificación a dicho correo.
- El código de verificación debe tener una vigencia limitada y no podrá utilizarse después de haber expirado.
- El código deberá ser válido para un solo proceso de recuperación.
- El usuario deberá ingresar correctamente el código recibido antes de poder establecer una nueva contraseña.
- Si el código es incorrecto o ha expirado, el sistema deberá informar que no es válido y no permitirá modificar la contraseña.
- El usuario debe poder establecer una nueva contraseña que cumpla con los requisitos definidos por el sistema.
- La nueva contraseña deberá contener como mínimo 8 caracteres.
- El sistema debe solicitar la confirmación de la nueva contraseña.
- Ambas contraseñas deben coincidir antes de permitir el cambio.
- Una vez modificada correctamente, la nueva contraseña debe ser utilizada por los siguientes inicios de sesión.
