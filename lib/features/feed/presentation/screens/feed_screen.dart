import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/adaptive_shell.dart';
import '../../../../core/layout/breakpoints.dart';
import '../controllers/feed_controller.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/listing_list_view.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  void _openFilters(BuildContext context, WidgetRef ref) {
    final controller = ref.read(feedControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersSheet(
        initialFilter: controller.currentFilter,
        onApply: (filter) => controller.search(filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // En escritorio los filtros y la lista los pinta el DesktopShell como
    // columnas persistentes; la página /feed queda como el panel de detalle
    // sin selección. Misma regla de ancho que el AdaptiveShell.
    final desktopSupported = ref.watch(desktopLayoutSupportedProvider);
    final isDesktopLayout =
        desktopSupported &&
        MediaQuery.sizeOf(context).width >= kDesktopMinWidth;
    if (isDesktopLayout) {
      return const _ListingDetailPlaceholder();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/new'),
        icon: const Icon(Icons.add),
        label: const Text('Crear publicación'),
      ),
      appBar: AppBar(
        title: const Text('Room2gether'),
        // Chats y Perfil viven ahora en la barra de navegación inferior.
        actions: [
          IconButton(
            onPressed: () => _openFilters(context, ref),
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: ListingListView(
        onListingTap: (listing) => context.push('/listings/${listing.id}'),
      ),
    );
  }
}

/// Estado vacío del panel de detalle en escritorio.
class _ListingDetailPlaceholder extends StatelessWidget {
  const _ListingDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.maps_home_work_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona una publicación para ver el detalle',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
