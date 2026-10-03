import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RequestMessageDialog extends StatefulWidget {
  final String initialMessage;
  const RequestMessageDialog({super.key, required this.initialMessage});
  @override
  State<RequestMessageDialog> createState() => _RequestMessageDialogState();
}

class _RequestMessageDialogState extends State<RequestMessageDialog> {
  late final _text = TextEditingController(text: widget.initialMessage);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final length = _text.text.runes.length;
    final valid = _text.text.trim().isNotEmpty && length <= 500;
    return AlertDialog(
      title: const Text('Editar mensaje'),
      content: SingleChildScrollView(
        child: TextField(
          controller: _text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Mensaje',
            counterText: '$length/500',
            errorText: length > 500
                ? 'El mensaje no puede superar 500 caracteres.'
                : _text.text.trim().isEmpty
                ? 'Escribe un mensaje.'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.pop(context, _text.text.trim())
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
