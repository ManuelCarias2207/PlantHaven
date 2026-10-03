# Integración móvil del 3 de octubre

Rama de prueba: `integracion-movil-scrum-5-7`.
Combina `scrum-5-imagenes-movil` (2ea9893) con los commits de las ramas
SCRUM-10, SCRUM-11, SCRUM-6 y SCRUM-8 del compañero. Estas ramas forman una
cadena, cuyo último commit es 4bc2c32; el merge conserva toda su historia.

## Resolución

- Se conservan búsqueda, filtros, paginación, consulta privada, edición y retiro
  de publicaciones propias de SCRUM-5.
- Se incorporan catálogo, detalle y envío/listado de solicitudes del compañero.
- Se corrigen las consultas de solicitudes a `/api/solicitudes?tipo=enviadas`
  y `tipo=recibidas`; `/mias` y `/recibidas` no existen en la API actual.
- Se conserva el motivo de error que devuelve la API y se impide solicitar
  una publicación propia desde el detalle.
- El chat recibido es una demostración local con Hive. Se conserva su código,
  pero se deshabilitan los accesos desde la app integrada hasta conectarlo con
  la API y aplicar los permisos posteriores a la aceptación. No comunica teléfonos.

## Pendientes comprobados en código

- SCRUM-7: implementada la bandeja del donante desde Mis publicaciones →
  Solicitudes recibidas, con filtros, paginación, detalle y confirmación de decisiones.
  Requiere desplegar la actualización del backend: PATCH `/api/solicitudes/{id}`
  admite `estado: ACEPTADA/RECHAZADA` además del mensaje del adoptante por separado.
  Pendiente la prueba manual publicada para cerrar la integración con SCRUM-5.
- SCRUM-6: completar edición y retiro de solicitudes en la interfaz y revisión
  de paginación (el listado integrado consulta hasta 100 solicitudes).
- SCRUM-10: filtros de tamaño y cuidado y paginación real del servidor;
  el catálogo recibido filtra ubicación/categoría y muestra progresivamente
  una sola respuesta de la API.
- SCRUM-11: revisar todas las fotos y actualización del detalle desde el servidor.
- SCRUM-8: conectar chat real con la API; el almacenamiento local no cumple
  comunicación entre participantes ni autorización de chat.

No marcar estas historias como terminadas solo por integrar sus ramas.
Catálogo, detalle, publicaciones propias y envío de solicitud con dos teléfonos
fueron confirmados por Krisler. Ahora probar aceptación/rechazo tras desplegar
SCRUM-7 y reinstalar la APK. La aceptación bloquea edición/retiro; otras solicitudes
pendientes quedan rechazadas. Para verificar ese último caso hacen falta dos
adoptantes y un donante para la misma planta.
