import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/services/adoption_service.dart';

class AdoptionsView extends StatefulWidget {
  final int? plantId;
  final AdoptionService? service;
  const AdoptionsView({super.key, this.plantId, this.service});
  @override
  State<AdoptionsView> createState() => _AdoptionsViewState();
}

class _AdoptionsViewState extends State<AdoptionsView>
    with WidgetsBindingObserver {
  late final AdoptionService _service;
  List<AdoptionStatus> _items = [];
  bool _loading = false, _saving = false;
  int _revision = 0;
  String? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdoptionService();
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  void _resume() {
    _timer?.cancel();
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

  String _message(Object e) => e is AdoptionFailure
      ? e.message
      : 'No se pudo conectar con la API. Revisa tu conexión.';

  Future<void> _load() async {
    if (_loading || _saving || !mounted) return;
    setState(() => _loading = true);
    final revision = _revision;
    try {
      final items = await _service.list();
      if (mounted && revision == _revision) {
        setState(() {
          _items = items
              .where(
                (a) => widget.plantId == null || a.plantId == widget.plantId,
              )
              .toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && revision == _revision) {
        setState(() => _error = _message(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(AdoptionStatus adoption) async {
    if (_saving || _loading) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adoption.actionLabel),
        content: Text(
          adoption.isDonor
              ? '¿Ya entregaste físicamente ${adoption.plantName} al adoptante? Confirma únicamente después de entregarla.'
              : '¿Ya recibiste físicamente ${adoption.plantName}? Confirma únicamente después de recibirla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || _saving) return;
    _revision++;
    setState(() => _saving = true);
    try {
      final updated = await _service.confirm(adoption);
      if (!mounted) return;
      setState(() {
        _items = _items.map((a) => a.id == updated.id ? updated : a).toList();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.complete
                ? 'Ambas confirmaciones registradas. ¡Adopción completada!'
                : 'Tu confirmación quedó guardada. Falta la otra persona.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_message(e)} Actualiza antes de volver a confirmar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        await _load();
      }
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Pendiente';
    final d = value.toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis adopciones'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _loading || _saving ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading || _saving) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (!_loading && _error == null && _items.isEmpty)
            const Text(
              'Aquí aparecerán tus adopciones cuando una solicitud sea aceptada.',
            ),
          for (final adoption in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adoption.plantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(adoption.complete ? 'COMPLETADA' : 'EN PROCESO'),
                    Text('Donante: ${adoption.donor}'),
                    Text('Adoptante: ${adoption.adopter}'),
                    const SizedBox(height: 12),
                    Text('Entrega: ${_date(adoption.deliveredAt)}'),
                    Text('Recepción: ${_date(adoption.receivedAt)}'),
                    const SizedBox(height: 12),
                    if (adoption.canConfirm)
                      FilledButton.icon(
                        onPressed: _saving || _loading
                            ? null
                            : () => _confirm(adoption),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(adoption.actionLabel),
                      )
                    else if (!adoption.complete)
                      const Text(
                        'Ya confirmaste. Falta la confirmación de la otra persona.',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
