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
- El chat de demostración local con Hive se conserva como código anterior.
  Los accesos actuales usan el chat de la API compartida, no las conversaciones de ejemplo.

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
- SCRUM-8: chat real conectado a la API, entrada desde solicitudes aceptadas
  (enviadas y recibidas) y Mis conversaciones. Actualiza cada tres segundos en
  primer plano, conserva historial en PostgreSQL y recupera mensajes tras reconexión.
  Validación de texto e historial en teléfonos confirmada por Krisler.
  El punto de encuentro se completa con SCRUM-9.

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
multipart múltiple; después generar e instalar la APK. Pruebas de fotografías múltiples
confirmadas por Krisler.

### Recuperación al volver de la cámara — 03/10/2026

Antes de abrir cámara/galería se guarda temporalmente el formulario con sus fotos
y el ID del dueño en Hive. Al reiniciar, `retrieveLostData` recupera la selección
pendiente de Android; la sesión guardada dirige al formulario y la API vuelve a
validarla. Si venció, iniciar sesión con la misma cuenta recupera el borrador.
No se guardan credenciales en el borrador ni se publica automáticamente. Al cerrar
sesión se elimina. Pruebas de cámara confirmadas por Krisler.

## SCRUM-9 y entrega de la base al equipo

El chat permite seleccionar un punto fijo en mapa, enviarlo mediante la API,
consultarlo, abrir «Cómo llegar», corregirlo y retirarlo. Ambas personas reciben
las correcciones y retiros de puntos existentes. Solo el autor puede cambiarlos
y solo durante una adopción EN_PROCESO; la API vuelve a comprobarlo siempre.
No usa GPS ni seguimiento de personas. Requiere desplegar el backend de SCRUM-9.
Las pruebas automatizadas pasaron; falta la prueba manual del mapa en dos teléfonos.

La rama principal de este repositorio se llama `principal` (la API usa `Main`).
Para obtener esta base, desde una copia sin cambios locales pendientes:

```powershell
git fetch origin
git switch principal
git pull --ff-only origin principal
flutter pub get
```

Si Git avisa de cambios locales o ramas divergentes, conservar ese trabajo y
revisarlo antes de seguir; no aplicar un reset ni forzar el push. Para continuar
una tarea nueva, crear una rama desde esta base. El código usa la API de Render.
Cada compañero genera su APK con `flutter build apk --release`.

Trabajo siguiente acordado: el compañero implementará SCRUM-16, administración
básica y notificaciones si hay tiempo. Historial de adopciones fuera de esta etapa.
