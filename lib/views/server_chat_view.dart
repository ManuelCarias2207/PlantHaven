import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/controllers/chat_controller.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/local_chat.dart';
import 'package:flutter_app/views/local_chat_view.dart' show MapLocationPicker;
import 'package:url_launcher/url_launcher.dart';

class ServerChatView extends StatefulWidget {
  final int plantId;
  final String plantName;
  final ChatService? service;
  const ServerChatView({
    super.key,
    required this.plantId,
    required this.plantName,
    this.service,
  });
  @override
  State<ServerChatView> createState() => _ServerChatViewState();
}

class _ServerChatViewState extends State<ServerChatView>
    with WidgetsBindingObserver {
  late final ChatController _chat;
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  int? _userId;
  int _count = 0;
  bool _starting = true;
  String? _sessionError;
  bool _choosingPoint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chat = ChatController(
      plantId: widget.plantId,
      service: widget.service ?? ChatService(),
    );
    _chat.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<AuthController>();
    try {
      final ok = await auth.ensureAuthenticated();
      if (!mounted) return;
      _userId = auth.currentUser?.idUsuario;
      if (!ok || _userId == null) {
        setState(() {
          _starting = false;
          _sessionError =
              auth.errorMessage ??
              'Vuelve a iniciar sesión para abrir el chat.';
        });
        return;
      }
      setState(() => _starting = false);
      _resume();
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _sessionError =
              'No se pudo recuperar tu sesión. Vuelve a iniciar sesión.';
        });
      }
    }
  }

  void _resume() {
    if (_userId == null || !mounted || _choosingPoint) return;
    _timer?.cancel();
    _chat.sync();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _chat.sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _timer?.cancel();
    }
  }

  void _changed() {
    if (!mounted) return;
    final count = _chat.messages.length;
    final nearBottom =
        !_scroll.hasClients || _scroll.position.extentAfter < 120;
    if (count > _count && nearBottom) _toBottom();
    _count = count;
    if (_chat.denied) _timer?.cancel();
    setState(() {});
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  });

  Future<void> _send() async {
    if (await _chat.send(_text.text) && mounted) {
      _text.clear();
      _toBottom();
      _chat.sync();
    }
  }

  Future<void> _choosePoint([ServerPoint? initial]) async {
    _choosingPoint = true;
    _timer?.cancel();
    final location = await Navigator.of(context).push<LocalLocation>(
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initial: initial == null
              ? null
              : LocalLocation(
                  latitude: initial.latitude,
                  longitude: initial.longitude,
                  placeName: initial.description,
                ),
        ),
      ),
    );
    _choosingPoint = false;
    if (!mounted) return;
    if (location != null) {
      final ok = await _chat.changePoint((id) async {
        if (initial == null) {
          await _chat.service.sendPoint(
            id,
            location.latitude,
            location.longitude,
            location.placeName,
          );
        } else {
          await _chat.service.editPoint(
            initial.id,
            location.latitude,
            location.longitude,
            location.placeName,
          );
        }
      });
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_chat.error ?? 'No se pudo guardar el punto.'),
          ),
        );
      }
    }
    if (mounted) _resume();
  }

  Future<void> _removePoint(ServerPoint point) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Retirar punto de encuentro?'),
        content: const Text(
          'Se quitarán las coordenadas de ambos teléfonos. El mensaje quedará como aviso de retiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await _chat.changePoint(
        (_) => _chat.service.removePoint(point.id),
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_chat.error ?? 'No se pudo retirar el punto.'),
          ),
        );
      }
    }
  }

  Future<void> _directions(ServerPoint point) async {
    try {
      // Consulta vigente: evita abrir coordenadas que el autor ya retiró o corrigió.
      final current = await _chat.service.point(point.id);
      final uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${current.latitude},${current.longitude}',
      });
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ChatFailure
                  ? e.message
                  : 'No se pudo abrir el mapa externo. Revisa tu conexión.',
            ),
          ),
        );
        _chat.sync();
      }
    }
  }

  Widget _pointCard(ServerPoint point) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place, color: AppColors.primary),
            SizedBox(width: 6),
            Flexible(child: Text('Punto de encuentro')),
          ],
        ),
        if (point.description.isNotEmpty) Text(point.description),
        Text(
          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
        ),
        const Text(
          'Ubicación fija, sin rastreo.',
          style: TextStyle(fontSize: 11),
        ),
        TextButton.icon(
          onPressed: () => _directions(point),
          icon: const Icon(Icons.directions),
          label: const Text('Cómo llegar'),
        ),
        if (point.canEdit)
          Wrap(
            children: [
              TextButton(
                onPressed: _chat.sending ? null : () => _choosePoint(point),
                child: const Text('Corregir'),
              ),
              TextButton(
                onPressed: _chat.sending ? null : () => _removePoint(point),
                child: const Text('Retirar'),
              ),
            ],
          ),
      ],
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _chat.removeListener(_changed);
    _chat.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chat.messages;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plantName.isEmpty
              ? 'Chat de la planta #${widget.plantId}'
              : widget.plantName,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_starting || _chat.loading) const LinearProgressIndicator(),
            if (_sessionError != null || _chat.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _sessionError ?? _chat.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (_chat.error != null && !_chat.denied)
              TextButton(
                onPressed: _chat.loading ? null : _chat.sync,
                child: const Text('Reintentar'),
              ),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        _starting || _chat.loading
                            ? 'Cargando conversación…'
                            : 'Coordina aquí la entrega de la planta.',
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message.userId == _userId;
                        final date = message.date.toLocal();
                        final stamp =
                            '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .8,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.point != null)
                                  _pointCard(message.point!)
                                else
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: mine
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  stamp,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mine
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Compartir punto de encuentro',
                    onPressed:
                        _chat.sending || _chat.denied || _chat.chatId == null
                        ? null
                        : () => _choosePoint(),
                    icon: const Icon(Icons.add_location_alt_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      enabled:
                          !_chat.sending &&
                          !_chat.denied &&
                          _userId != null &&
                          _chat.chatId != null,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje…',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar',
                    onPressed:
                        _chat.sending ||
                            _chat.denied ||
                            _chat.chatId == null ||
                            _text.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: _chat.sending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
