import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/models/local_chat.dart';
import 'package:flutter_app/services/local_chat_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocalChatView extends StatefulWidget {
  final LocalChat chat;
  const LocalChatView({super.key, required this.chat});
  @override
  State<LocalChatView> createState() => _LocalChatViewState();
}

class _LocalChatViewState extends State<LocalChatView> {
  final _textController = TextEditingController();
  final _store = LocalChatStore();
  @override
  void initState() {
    super.initState();
    _store.markRead(widget.chat.chatId);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _store.messages(widget.chat.chatId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.fieldBackground,
              child: Icon(Icons.person, color: AppColors.accent),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat de adopción',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  widget.chat.otherUserName.isEmpty
                      ? 'Usuario'
                      : widget.chat.otherUserName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.local_florist_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.chat.plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                _pill(widget.chat.status, pink: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const _PrivacyBanner(
                  icon: Icons.shield_outlined,
                  text: 'Espacio de Adopción Seguro. La ubicación exacta solo se comparte si ambos acuerdan la entrega.',
                ),
                const SizedBox(height: 6),
                const _PrivacyBanner(
                  icon: Icons.lock_outline,
                  text: 'Los mensajes de esta conversación quedan guardados en tu historial de adopción.',
                  muted: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              itemCount: messages.length,
              itemBuilder: (context, index) => _MessageBubble(
                message: messages[index],
                onDirections: _openDirections,
              ),
            ),
          ),
          _Composer(
            controller: _textController,
            onSend: _sendText,
            onLocation: _chooseLocation,
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {bool pink = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: pink ? const Color(0xFFF5DDE5) : const Color(0xFFDCE9DF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: pink ? Colors.pink.shade700 : AppColors.primary,
      ),
    ),
  );
  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await _store.saveMessage(
      LocalMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        chatId: widget.chat.chatId,
        senderId: 0,
        textContent: text,
        locationData: null,
        timestamp: DateTime.now(),
        isMine: true,
      ),
    );
    _textController.clear();
    setState(() {});
  }

  Future<void> _chooseLocation() async {
    final location = await showModalBottomSheet<LocalLocation>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _LocationPicker(),
    );
    if (location == null) return;
    await _store.saveMessage(
      LocalMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        chatId: widget.chat.chatId,
        senderId: 0,
        textContent: '',
        locationData: location,
        timestamp: DateTime.now(),
        isMine: true,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDirections(LocalLocation location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PrivacyBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;
  const _PrivacyBanner({
    required this.icon,
    required this.text,
    this.muted = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: muted ? Colors.grey.shade200 : const Color(0xFFDCE9DF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: muted ? AppColors.textDisabled : AppColors.accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final LocalMessage message;
  final Future<void> Function(LocalLocation) onDirections;
  const _MessageBubble({required this.message, required this.onDirections});
  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.timestamp).format(context);
    final bubble = message.locationData == null
        ? Text(
            message.textContent,
            style: TextStyle(
              color: message.isMine ? Colors.white : AppColors.textPrimary,
            ),
          )
        : _MapCard(location: message.locationData!, onDirections: onDirections);
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.locationData != null || !message.isMine
              ? Colors.white
              : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMine ? 16 : 3),
            bottomRight: Radius.circular(message.isMine ? 3 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            bubble,
            const SizedBox(height: 4),
            Text(
              '$time  ${message.isMine ? '✓' : ''}',
              style: TextStyle(
                fontSize: 9,
                color: message.isMine && message.locationData == null
                    ? Colors.white70
                    : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final LocalLocation location;
  final Future<void> Function(LocalLocation) onDirections;
  const _MapCard({required this.location, required this.onDirections});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.accent, size: 18),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Punto de encuentro compartido',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 105,
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.map_outlined, size: 42, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          location.placeName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const Text(
          'Punto seguro · ubicación estática',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => onDirections(location),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.fieldBackground,
            ),
            child: const Text('Cómo llegar'),
          ),
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onLocation;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onLocation,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: AppColors.fieldBackground,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.accent,
            ),
            onPressed: onLocation,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: onSend,
          ),
        ],
      ),
    ),
  );
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker();
  @override
  Widget build(BuildContext context) {
    const options = [
      LocalLocation(
        latitude: 13.7167,
        longitude: -89.7167,
        placeName: 'Parque Central de Sonsonate',
      ),
      LocalLocation(
        latitude: 13.9942,
        longitude: -89.5597,
        placeName: 'Parque Central de Santa Ana',
      ),
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Selecciona un punto seguro',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          ...options.map(
            (location) => ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.accent,
              ),
              title: Text(location.placeName),
              subtitle: const Text('Ubicación estática'),
              onTap: () => Navigator.pop(context, location),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Punto personalizado'),
            subtitle: const Text('Toca un punto en el mapa'),
            onTap: () async {
              final location = await showDialog<LocalLocation>(
                context: context,
                builder: (_) => const MapLocationPicker(),
              );
              if (location != null && context.mounted) {
                Navigator.pop(context, location);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CustomLocationDialog extends StatefulWidget {
  const _CustomLocationDialog();

  @override
  State<_CustomLocationDialog> createState() => _CustomLocationDialogState();
}

class _CustomLocationDialogState extends State<_CustomLocationDialog> {
  final _placeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _placeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _save() {
    final place = _placeController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (place.isEmpty || latitude == null || longitude == null) {
      setState(() => _error = 'Completa el lugar, latitud y longitud.');
      return;
    }
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      setState(() => _error = 'Las coordenadas no son válidas.');
      return;
    }
    Navigator.pop(
      context,
      LocalLocation(latitude: latitude, longitude: longitude, placeName: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Punto personalizado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agrega un punto fijo. No se compartirá tu ubicación en tiempo real.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _placeController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nombre del lugar'),
            ),
            TextField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitud (ej. 13.7167)',
              ),
            ),
            TextField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitud (ej. -89.7167)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Usar punto'),
        ),
      ],
    );
  }
}

class MapLocationPicker extends StatefulWidget {
  final LocalLocation? initial;
  const MapLocationPicker({super.key, this.initial});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  static const _defaultPoint = LatLng(13.7167, -89.7167);
  final _placeController = TextEditingController();
  final _mapController = MapController();
  LatLng? _selectedPoint;
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _selectedPoint = LatLng(initial.latitude, initial.longitude);
      _placeController.text = initial.placeName;
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _confirm() {
    final point = _selectedPoint;
    if (point == null) return;
    Navigator.pop(
      context,
      LocalLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        placeName: _placeController.text.trim().isEmpty
            ? 'Punto de encuentro personalizado'
            : _placeController.text.trim(),
      ),
    );
  }

  Future<void> _searchPlace() async {
    final query = _placeController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchError = 'Escribe primero el nombre de un lugar.');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$query, El Salvador',
        'format': 'jsonv2',
        'limit': '1',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'PlantHaven/1.0'})
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final results = jsonDecode(response.body);
      if (response.statusCode != 200 || results is! List || results.isEmpty) {
        throw const FormatException('Lugar no encontrado');
      }

      final result = results.first as Map<String, dynamic>;
      final latitude = double.tryParse('${result['lat']}');
      final longitude = double.tryParse('${result['lon']}');
      if (latitude == null || longitude == null) {
        throw const FormatException('Coordenadas no disponibles');
      }

      setState(() {
        _selectedPoint = LatLng(latitude, longitude);
        if (_placeController.text.trim().isEmpty) {
          _placeController.text = '${result['display_name'] ?? query}';
        }
      });
      _mapController.move(LatLng(latitude, longitude), 15);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'No se encontró el lugar. También puedes tocar el mapa.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un punto seguro'),
        actions: [
          TextButton(
            onPressed: _selectedPoint == null ? null : _confirm,
            child: const Text('Usar punto'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _selectedPoint == null ? null : _confirm,
          icon: const Icon(Icons.send),
          label: const Text('Confirmar ubicación y enviar'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _placeController,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar (opcional)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSearching ? null : _searchPlace,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'Buscando...' : 'Buscar lugar'),
              ),
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Toca el mapa para marcar el punto. Solo se guardará este punto fijo.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint ?? _defaultPoint,
                initialZoom: 13,
                onTap: (_, point) => setState(
                  () => _selectedPoint = LatLng(
                    point.latitude,
                    ((point.longitude + 180) % 360) - 180,
                  ),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.planthaven.app',
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
                if (_selectedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPoint!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
