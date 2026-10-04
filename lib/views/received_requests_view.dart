import 'package:flutter/material.dart';
import 'package:flutter_app/views/server_chat_view.dart';
import 'package:flutter_app/controllers/auth_controller.dart';
import 'package:flutter_app/core/constants/app_routes.dart';
import 'package:flutter_app/models/adoption_request_model.dart';
import 'package:flutter_app/services/adoption_request_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ReceivedRequestsView extends StatefulWidget {
  final AdoptionRequestService? service;
  const ReceivedRequestsView({super.key, this.service});
  @override
  State<ReceivedRequestsView> createState() => _ReceivedRequestsViewState();
}

class _ReceivedRequestsViewState extends State<ReceivedRequestsView> {
  late final _service = widget.service ?? AdoptionRequestService();
  final _plant = TextEditingController();
  List<AdoptionRequest> _requests = [];
  String? _state, _error;
  int _offset = 0;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _plant.dispose();
    super.dispose();
  }

  Future<void> _load({int offset = 0}) async {
    setState(() {
      _busy = true;
      _error = null;
      _requests = [];
    });
    try {
      if (!await context.read<AuthController>().ensureAuthenticated()) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }
      final raw = _plant.text.trim();
      final id = raw.isEmpty ? null : int.tryParse(raw);
      if (raw.isNotEmpty && (id == null || id <= 0)) {
        throw Exception('Escribe un ID de planta válido.');
      }
      final result = await _service.received(
        offset: offset,
        estado: _state,
        plantId: id,
      );
      if (mounted) {
        setState(() {
          _requests = result;
          _offset = offset;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(AdoptionRequest request, String state) async {
    final accepted = state == 'ACEPTADA';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          accepted ? '¿Aceptar esta solicitud?' : '¿Rechazar esta solicitud?',
        ),
        content: Text(
          accepted
              ? 'Se asignará la planta a esta persona y se rechazarán las demás solicitudes pendientes. Después no podrás editar ni retirar la publicación.'
              : 'Solo se rechazará esta solicitud; las demás seguirán pendientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(accepted ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.decide(request.id, state);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted ? 'Solicitud aceptada.' : 'Solicitud rechazada.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _detail(AdoptionRequest request) async {
    setState(() => _busy = true);
    try {
      final current = await _service.detail(request.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Solicitud #${current.id}'),
          content: SingleChildScrollView(
            child: Text(
              'Planta #${current.plantId}\n${request.plantName}\n${request.adopterName}\nEstado: ${current.status}\nFecha: ${current.createdAt?.toLocal() ?? "No indicada"}\n\n${current.reason}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitudes recibidas')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _state ?? 'TODAS',
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ['TODAS', 'PENDIENTE', 'ACEPTADA', 'RECHAZADA']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        _state = value == 'TODAS' ? null : value;
                        _load();
                      },
              ),
              TextField(
                controller: _plant,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'ID de planta (opcional)',
                  suffixIcon: IconButton(
                    onPressed: _busy ? null : () => _load(),
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => _load(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _load(offset: _offset),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null) ...[
                        Text(_error!),
                        TextButton(
                          onPressed: () => _load(),
                          child: const Text('Reintentar'),
                        ),
                      ] else if (_requests.isEmpty)
                        const Text('No hay solicitudes con estos filtros.'),
                      for (final request in _requests)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.plantName} · Planta #${request.plantId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  request.adopterName.isEmpty
                                      ? 'Solicitante de la solicitud #${request.id}'
                                      : request.adopterName,
                                ),
                                Text(request.status),
                                Text('${request.createdAt?.toLocal() ?? ""}'),
                                const SizedBox(height: 8),
                                Text(request.reason),
                                TextButton(
                                  onPressed: () => _detail(request),
                                  child: const Text('Ver detalle'),
                                ),
                                if (request.status == 'ACEPTADA')
                                  FilledButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('Abrir chat'),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ServerChatView(
                                          plantId: request.plantId,
                                          plantName: request.plantName,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (request.status == 'PENDIENTE')
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      FilledButton(
                                        onPressed: () =>
                                            _decide(request, 'ACEPTADA'),
                                        child: const Text('Aceptar'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () =>
                                            _decide(request, 'RECHAZADA'),
                                        child: const Text('Rechazar'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _busy || _offset == 0
                  ? null
                  : () => _load(offset: _offset - 100),
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Página ${_offset ~/ 100 + 1}'),
            IconButton(
              onPressed: _busy || _requests.length < 100
                  ? null
                  : () => _load(offset: _offset + 100),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ),
  );
}
