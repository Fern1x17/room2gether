import 'package:flutter/material.dart';

import '../../domain/models/listing_filter.dart';
import 'filters_panel.dart';

/// Bottom sheet de filtros (forma móvil). El formulario en sí es el
/// [FiltersPanel] compartido con el panel persistente de escritorio; aquí
/// solo se añade el comportamiento de sheet: padding del teclado, scroll y
/// cierre al aplicar.
class FiltersSheet extends StatelessWidget {
  const FiltersSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  final ListingFilter initialFilter;
  final ValueChanged<ListingFilter> onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: FiltersPanel(
          title: 'Filtrar publicaciones',
          initialFilter: initialFilter,
          onApply: (filter) {
            onApply(filter);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
