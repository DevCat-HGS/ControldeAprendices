Análisis de Requisitos
Gestión de Asistencia y Evaluaciones en el SENA

1. Introducción
El proyecto consiste en desarrollar una aplicación móvil utilizando Flutter, destinada a la gestión de asistencia y evaluaciones en el SENA. La aplicación está orientada a dos tipos de usuarios: instructores y aprendices.

2. Objetivos del Proyecto
Desarrollar una aplicación móvil que facilite el registro y seguimiento de la asistencia y evaluaciones.

Implementar la diferenciación de roles (instructor y aprendiz) para mostrar la información relevante según el usuario.

Diseñar y programar las rutas y el frontend de la aplicación.

Garantizar la usabilidad en la gestión de evaluaciones, evidencias y el historial académico.

3. Requerimientos Funcionales
Pantallas y Funcionalidades Principales
Pantalla de Inicio de Sesión (LoginPage):

Autenticación mediante correo y contraseña.

Diferenciación de roles (instructor y aprendiz).

Pantalla de Registro de Usuario (RegisterPage):

Registro de nuevos usuarios con datos: nombre, apellido, número de documento, correo y rol (aprendiz o instructor).
 
Pantalla Principal (HomePage):

Para instructores: Visualización de lista de cursos a cargo, asistencias recientes y evaluaciones pendientes.

Para aprendices: Visualización de materias inscritas y calificaciones recientes.

Pantalla de Registro de Asistencia (AttendancePage):

Permite al instructor seleccionar un curso y registrar la asistencia de los aprendices.

Visualización del historial de asistencia por estudiante.

Pantalla de Registro de Evaluaciones (EvaluationPage):

Permite al instructor asignar evaluaciones especificando nombre, fecha y puntaje máximo.

Los aprendices pueden consultar las evaluaciones asignadas y subir evidencias cuando sea necesario.

Pantalla de Historial de Evaluaciones (GradesPage):

Visualización de las calificaciones obtenidas en las diferentes evaluaciones.

Funcionalidad para que los instructores puedan modificar calificaciones si fuese necesario.

Pantalla de Perfil del Usuario (ProfilePage):

Visualización de los datos personales del usuario autenticado.

Para aprendices: Acceso al resumen de asistencia y calificaciones.

Para instructores: Opción para modificar información de los cursos asignados.

4. Requerimientos No Funcionales
Usabilidad:
La aplicación debe ser intuitiva y fácil de navegar para los distintos perfiles de usuario.

Rendimiento:
Respuesta rápida en el registro y visualización de datos, especialmente en la consulta de historial y actualizaciones en evaluaciones.

Seguridad:
Autenticación segura para proteger la información sensible de los usuarios (correo, datos personales y calificaciones).

Compatibilidad:
La aplicación debe ser compatible con dispositivos Android, considerando que se desarrollará en Flutter y se emulará en Android Studio.

Mantenibilidad:
Código fuente estructurado y documentado para facilitar futuras mejoras y mantenimiento.

5. Entregables y Evaluación
Código Fuente:
Proyecto en Flutter con todas las funcionalidades implementadas y emulado en Android Studio.

Documentación:
Explicación detallada del flujo de la aplicación y de las rutas (navegación entre pantallas).

Evaluación de Conocimientos:
Se evaluará el dominio de las tecnologías utilizadas y la correcta implementación de las funcionalidades requeridas.

Cronograma:
Fecha de entrega: 31 de marzo de 2025.