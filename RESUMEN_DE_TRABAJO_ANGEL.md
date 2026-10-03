# Resumen de trabajo Angel - PlantHaven

## Contexto del proyecto

PlantHaven es una aplicación Flutter para adopción comunitaria de plantas. La aplicación utiliza una API remota para autenticación, plantas y solicitudes de adopción. El chat y sus ubicaciones son exclusivamente locales y no se envían al backend.

## Funcionalidades implementadas

### Catálogo de plantas

- El catálogo consume plantas reales desde la API.
- Solo se muestran plantas con estado `DISPONIBLE`.
- Búsqueda por nombre en tiempo real.
- Filtros por ubicación y tipo de planta.
- Paginación/scroll infinito simulado mediante `ScrollController`.
- Tarjetas con imagen, estado, precio, características y favoritos.
- El corazón de favoritos cambia visualmente de estado localmente.
- Botón de ordenamiento y navegación inferior.

Archivo principal:

- `lib/views/catalog_view.dart`

### Modelo y API de plantas

- Modelo principal: `PlantModel`.
- Servicio de plantas: `PlantService`.
- Controlador de estado: `PlantController`.
- El catálogo utiliza `/api/plantas`.
- Mis publicaciones utiliza `/api/plantas/mias/`.
- El parser acepta respuestas en formato lista, `items`, `plantas` o `data`.

Archivos principales:

- `lib/models/plant_model.dart`
- `lib/services/plant_service.dart`
- `lib/controllers/plant_controller.dart`

### Detalle de planta

- Recibe un `PlantModel` por constructor.
- Incluye galería visual, características, descripción, cuidados, donante y estado.
- El botón de adopción cambia según el estado de la planta.
- Si está disponible permite enviar solicitud.
- Si está solicitada/adoptada queda deshabilitado.
- La campana cambia visualmente al presionarse.
- La pantalla mantiene una barra inferior fija.

Archivo:

- `lib/views/plant_detail_view.dart`

### Solicitudes de adopción

- Modal para escribir el motivo/mensaje.
- Límite estricto de 500 caracteres.
- El backend requiere el campo `mensaje`.
- Se muestra Snackbar con el texto exacto cuando falla:

```text
Exception: No se pudo enviar la solicitud.
```

- Tras enviar correctamente se muestra la pantalla `¡Solicitud enviada!`.
- El servicio intenta manejar respuestas HTTP 307/308.
- El adoptante puede consultar sus solicitudes.
- El donante puede consultar solicitudes recibidas por publicación.

Archivos principales:

- `lib/models/adoption_request_model.dart`
- `lib/services/adoption_request_service.dart`
- `lib/controllers/adoption_request_controller.dart`
- `lib/views/adoption_success_view.dart`
- `lib/views/my_requests_view.dart`
- `lib/views/my_plants_view.dart`

Endpoints configurados:

- `POST /api/solicitudes`
- `GET /api/solicitudes/mias`
- `GET /api/solicitudes/recibidas`

### Mis publicaciones

- Muestra las publicaciones del usuario autenticado.
- Muestra las solicitudes recibidas debajo de cada planta.
- Cada solicitud tiene botón `Mensajes`.
- Se agregó manejo de errores y botón `Reintentar`.
- La carga de plantas y solicitudes se ejecuta en paralelo.
- Tiene navegación inferior con Inicio, Publicar y Mensajes.

Archivo:

- `lib/views/my_plants_view.dart`

### Chat local

El chat no utiliza la API. Todos los datos viven en Hive dentro del dispositivo.

Modelos:

- `LocalChat`:
  - `chatId`
  - `plantId`
  - `plantName`
  - `otherUserName`
  - `otherUserRole`
  - `status`
  - `lastMessage`
  - `lastMessageTime`
  - `unreadCount`
- `LocalMessage`:
  - `id`
  - `chatId`
  - `senderId`
  - `textContent`
  - `locationData`
  - `timestamp`
  - `isMine`
- `LocalLocation`:
  - latitud
  - longitud
  - nombre del lugar

Archivos:

- `lib/models/local_chat.dart`
- `lib/services/local_chat_store.dart`
- `lib/views/messages_view.dart`
- `lib/views/local_chat_view.dart`

Almacenamiento:

- Box Hive `local_chats`.
- Box Hive `local_messages`.
- Inicialización en `lib/main.dart` mediante `LocalChatStore.initialize()`.

### Bandeja de mensajes

- Lista las conversaciones locales.
- Buscador local.
- Badge de mensajes no leídos.
- Estado vacío cuando no hay conversaciones.
- Banner de privacidad.
- Navegación inferior visible con Mensajes seleccionado.

Archivo:

- `lib/views/messages_view.dart`

### Chat individual

- Flecha explícita para regresar.
- Muestra nombre del otro usuario.
- Muestra nombre y estado de la planta.
- Banners de privacidad.
- Burbujas para mensajes enviados y recibidos.
- Hora y estado de lectura.
- Los mensajes de texto se guardan localmente.
- El botón de ubicación no comparte ubicación en tiempo real.

Archivo:

- `lib/views/local_chat_view.dart`

### Ubicación estática en el chat

- Incluye puntos predeterminados de Sonsonate y Santa Ana.
- Incluye opción `Punto personalizado`.
- El usuario puede escribir un lugar y presionar `Buscar lugar`.
- Se muestra un mapa visual con `flutter_map`.
- El usuario puede tocar o mover el marcador.
- Botón visible al pie: `Confirmar ubicación y enviar`.
- Al confirmar se envía una tarjeta local al chat.
- El botón `Cómo llegar` abre Google Maps con las coordenadas guardadas.
- No se guarda ubicación en la API.
- No se comparte ubicación en tiempo real.

Dependencias relacionadas:

- `hive`
- `hive_flutter`
- `url_launcher`
- `flutter_map`
- `latlong2`

### Navegación

Rutas principales en `lib/core/constants/app_routes.dart`:

- `/` catálogo.
- `/mensajes` bandeja local.
- `/publicar-planta` publicar planta.
- `/mis-publicaciones` publicaciones del usuario.
- `/planta/:id` detalle de planta.
- `/editar-planta/:id` editar planta.

Router principal:

- `lib/core/routes/app_router.dart`

La navegación inferior está presente en catálogo, mis publicaciones y mensajes.

## Dependencias agregadas

En `pubspec.yaml`:

```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
url_launcher: ^6.3.1
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

## Correcciones importantes realizadas

- Se corrigió el payload de solicitudes de `motivo` a `mensaje` porque el backend rechazaba `motivo` con HTTP 422.
- Se agregó soporte para respuestas HTTP 307/308 en solicitudes.
- Se corrigieron errores de `const` y callbacks con múltiples guiones bajos.
- Se eliminó el uso de mocks del catálogo.
- Se mejoró el manejo de estados de carga, error y lista vacía.
- Se agregaron botones de navegación inferior en las vistas que no los tenían.
- Se agregaron logs para diagnosticar la carga de Mis publicaciones:

```text
[PlantService] GET MIS PLANTAS
[AdoptionRequestService] GET /api/solicitudes/recibidas
```

## Estado actual conocido

- El APK debug ha sido compilado correctamente varias veces.
- `dart format` se ejecuta correctamente sobre los archivos modificados.
- El analizador `dart analyze` del entorno puede fallar por permisos del sistema Windows (`CreateFile failed 5`), no por un error del proyecto.
- La API remota puede tardar cuando Render está iniciando. La pantalla de Mis publicaciones muestra carga y errores en lugar de romperse.
- Para diagnosticar problemas de carga, revisar los logs inmediatamente después de navegar a `/mis-publicaciones`.

## Recomendaciones para continuar

1. Probar Mis publicaciones con sesión autenticada.
2. Revisar si aparecen:

```text
[PlantService] GET MIS PLANTAS respuesta: 200
[AdoptionRequestService] GET respuesta: 200
```

3. Si la API tarda, considerar agregar una pantalla de reintento con timeout visual de 20-30 segundos.
4. Si se desea geocodificación completamente basada en Google, será necesario configurar Google Maps SDK y una API Key. Actualmente el mapa usa `flutter_map` y las rutas se abren en Google Maps.
5. El chat local está preparado para recibir navegación futura con `request_id`, `plant_id` y datos del usuario.
