import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/feed_controller.dart';
import 'filters_panel.dart';
import 'listing_list_view.dart';

/// Columnas de la sección Buscar en el layout de escritorio. El contenido es
/// el mismo que en móvil (FiltersPanel, ListingListView); solo cambia cómo
/// se dispone.

/// Panel de filtros persistente (equivale al FiltersSheet del móvil).
class FeedFiltersPane extends ConsumerWidget {
  const FeedFiltersPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(feedControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FiltersPanel(
        title: 'Filtros',
        initialFilter: controller.currentFilter,
        onApply: controller.search,
      ),
    );
  }
}

/// Columna central: contador de resultados + lista de publicaciones. El
/// detalle se abre en el panel derecho navegando a /listings/:id, de modo
/// que la URL sigue siendo compartible y el deep-link funciona igual que
/// en móvil.
class FeedListPane extends ConsumerWidget {
  const FeedListPane({super.key, required this.currentUri});

  /// URI actual del router; la pasa el DesktopShell en cada navegación.
  final Uri currentUri;

  String? get _selectedListingId {
    final segments = currentUri.pathSegments;
    if (segments.length == 2 && segments.first == 'listings') {
      return segments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(feedControllerProvider);
    final selectedId = _selectedListingId;
    // `valueOrNull` y no `value`: este último RELANZA el error cuando la carga
    // ha fallado, y esta columna reventaría antes de llegar a ListingListView,
    // que es quien pinta el error y el botón de reintentar. Sin número, no hay
    // contador y ya está.
    final count = listingsAsync.valueOrNull?.length;
    final cityName = ref
        .read(feedControllerProvider.notifier)
        .currentFilter
        .cityName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (count != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              cityName == null || cityName.isEmpty
                  ? '$count publicaciones'
                  : '$count publicaciones en $cityName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Expanded(
          child: ListingListView(
            selectedListingId: selectedId,
            onListingTap: (listing) {
              final target = '/listings/${listing.id}';
              // Con un detalle ya abierto se sustituye en vez de apilar,
              // para que la pila del panel no crezca sin límite.
              if (selectedId != null) {
                context.pushReplacement(target);
              } else {
                context.push(target);
              }
            },
          ),
        ),
      ],
    );
  }
}
