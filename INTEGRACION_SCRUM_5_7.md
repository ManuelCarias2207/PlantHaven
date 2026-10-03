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
  Prueba manual publicada de aceptación/rechazo y rechazo automático confirmada
  por Krisler: comprobación conjunta con SCRUM-5 completada.
- SCRUM-6: implementadas edición, retiro con confirmación, detalle, fecha, filtros
  por estado/ID de planta y páginas de 20 solicitudes. Solo las pendientes ofrecen
  acciones; la API comprueba otra vez el estado al guardar. Pruebas manuales
  confirmadas por Krisler; SCRUM-6 completado. No requiere un despliegue nuevo del backend.
- SCRUM-10: implementados filtros combinados de tamaño, cuidado, categoría,
  ubicación y nombre, cuadrícula y carga automática de páginas de 12 desde la API.
  Las opciones proceden de todas las publicaciones disponibles, no solo la primera
  página. Pendiente comprobar en teléfono tras desplegar la API.
- SCRUM-11: detalle y fotografías confirmados por Krisler; completado.
- SCRUM-8: conectar chat real con la API; el almacenamiento local no cumple
  comunicación entre participantes ni autorización de chat.

No marcar estas historias como terminadas solo por integrar sus ramas.
Catálogo, detalle, publicaciones propias, envío y aceptación/rechazo con varios
teléfonos fueron confirmados por Krisler. La aceptación bloquea edición/retiro;
otras solicitudes pendientes quedan rechazadas.

Para probar SCRUM-6: abrir Mis solicitudes (carta), editar una pendiente, cancelar
y luego confirmar su retiro, filtrar estado/planta y abrir detalle. Una aceptada
o rechazada no debe ofrecer editar/retirar. Si el donante acepta mientras el
adoptante escribe, guardar debe mostrar un error y refrescar el estado sin alterar
la adopción. Pedir otra vez la misma planta tras retirar una pendiente sigue
permitido mientras la planta esté disponible.

## Fotografías múltiples

Publicar y editar permiten agregar imágenes de galería o cámara, hasta cinco,
con vista previa y eliminación de la selección antes de guardar. La primera es
la principal. Editar conserva las URLs elegidas y envía las fotos nuevas en una
sola solicitud, manteniendo al menos una. Primero desplegar el backend con soporte
multipart múltiple; después generar e instalar la APK. Pendiente prueba en teléfono.
