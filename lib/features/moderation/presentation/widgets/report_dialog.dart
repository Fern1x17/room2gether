import 'package:flutter/material.dart';

import '../../domain/report_reasons.dart';

/// Diálogo de selección de motivos (CU-11, paso 2-3). Devuelve los motivos
/// elegidos, o null si se cancela. El que llama ejecuta el reporte+bloqueo.
Future<List<String>?> showReportDialog(BuildContext context) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final Set<String> _selected = {};
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona los motivos del reporte. '
              'Al reportar, el usuario quedará bloqueado.',
            ),
            const SizedBox(height: 8),
            for (final reason in reportReasons)
              CheckboxListTile(
                value: _selected.contains(reason),
                onChanged: (checked) {
                  setState(() {
                    _showError = false;
                    if (checked ?? false) {
                      _selected.add(reason);
                    } else {
                      _selected.remove(reason);
                    }
                  });
                },
                title: Text(reason),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            if (_showError)
              Text(
                'Selecciona al menos un motivo.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_selected.isEmpty) {
              setState(() => _showError = true);
              return;
            }
            Navigator.of(context).pop(_selected.toList());
          },
          child: const Text('Reportar y bloquear'),
        ),
      ],
    );
  }
}
