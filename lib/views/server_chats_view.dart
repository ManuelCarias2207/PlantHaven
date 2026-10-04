import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/views/server_chat_view.dart';

class ServerChatsView extends StatefulWidget {
  const ServerChatsView({super.key});
  @override
  State<ServerChatsView> createState() => _ServerChatsViewState();
}

class _ServerChatsViewState extends State<ServerChatsView>
    with WidgetsBindingObserver {
  final _service = ChatService();
  List<ServerChat> _chats = [];
  bool _loading = false, _opening = false;
  String? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  void _resume() {
    _timer?.cancel();
    if (_opening) return;
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _load() async {
    if (_loading || !mounted) return;
    setState(() => _loading = true);
    try {
      final chats = await _service.list();
      if (mounted) {
        setState(() {
          _chats = chats;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ChatFailure
              ? e.message
              : 'No se pudieron cargar los chats. Revisa tu conexión.',
        );
      }
      if (e is ChatFailure && e.denied) _timer?.cancel();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ServerChat chat) async {
    _opening = true;
    _timer?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ServerChatView(plantId: chat.plantId, plantName: chat.plantName),
      ),
    );
    _opening = false;
    if (mounted) _resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mis conversaciones')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
          if (!_loading && _error == null && _chats.isEmpty)
            const Text(
              'Todavía no tienes conversaciones. Abre una solicitud aceptada y pulsa «Abrir chat».',
            ),
          for (final chat in _chats)
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(chat.plantName),
                subtitle: Text(chat.otherName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(chat),
              ),
            ),
        ],
      ),
    ),
  );
}
