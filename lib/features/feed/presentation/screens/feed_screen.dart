import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/adaptive_shell.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../domain/models/listing_filter.dart';
import '../controllers/feed_controller.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/listing_list_view.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  /// El botón de filtros se aparta mientras se baja por la lista y vuelve al
  /// subir. Solo afecta a este botón: el de publicar se queda donde estaba.
  bool _filtersButtonVisible = true;

  void _openFilters() {
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

  bool _onScroll(UserScrollNotification notification) {
    final visible = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      // idle: se deja como esté; no hay intención del usuario que interpretar.
      ScrollDirection.idle => _filtersButtonVisible,
    };
    if (visible != _filtersButtonVisible) {
      setState(() => _filtersButtonVisible = visible);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
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

    // El badge solo dice si hay filtros puestos, sin contarlos. Se observa el
    // propio feed —que cambia de estado al aplicar filtros— para que el badge
    // se repinte; el filtro en sí vive en el notifier.
    ref.watch(feedControllerProvider);
    final hasActiveFilters =
        !ref.read(feedControllerProvider.notifier).currentFilter.isEmpty;

    return Scaffold(
      // Dos botones flotantes: filtros a la izquierda y publicar a la derecha.
      // Van en una fila dentro del hueco del FAB, en vez de posicionarlos a
      // mano, para que el Scaffold siga encargándose de separarlos de la barra
      // de navegación inferior y del área segura.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _filtersButtonVisible
                  ? Offset.zero
                  : const Offset(0, 1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _filtersButtonVisible ? 1 : 0,
                child: _FiltersButton(
                  hasActiveFilters: hasActiveFilters,
                  // Sin interacción mientras está oculto, para que no se pueda
                  // pulsar a ciegas.
                  onPressed: _filtersButtonVisible ? _openFilters : null,
                ),
              ),
            ),
            FloatingActionButton.extended(
              heroTag: 'create-listing-fab',
              onPressed: () => context.push('/listings/new'),
              icon: const Icon(Icons.add),
              label: const Text('Crear publicación'),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Room2gether'),
        // Chats y Perfil viven ahora en la barra de navegación inferior.
        actions: [
          // CU-20: la lupa es la entrada al buscador de usuarios. Los filtros
          // del feed se abren desde el botón de abajo a la izquierda.
          IconButton(
            onPressed: () => context.push('/users/search'),
            icon: const Icon(Icons.search),
            tooltip: 'Buscar usuarios',
          ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: ListingListView(
          onListingTap: (listing) => context.push('/listings/${listing.id}'),
        ),
      ),
    );
  }
}

/// Botón de filtros. El badge es un punto sin número: solo avisa de que hay
/// filtros puestos. Se apoya en [ListingFilter.isEmpty], que ya deja fuera
/// `cityName` por ser presentación y no criterio.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool hasActiveFilters;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final button = FloatingActionButton(
      heroTag: 'filters-fab',
      onPressed: onPressed,
      tooltip: 'Filtrar publicaciones',
      child: const Icon(Icons.menu),
    );

    return Semantics(
      button: true,
      // El tooltip ya da la etiqueta base; aquí se añade el estado, que si no
      // solo se percibe por el punto dibujado encima del icono.
      label: hasActiveFilters
          ? 'Filtrar publicaciones, con filtros activos'
          : 'Filtrar publicaciones',
      child: hasActiveFilters ? Badge(child: button) : button,
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
