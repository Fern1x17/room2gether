import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/adaptive_shell.dart';
import '../../../../core/layout/breakpoints.dart';
import '../controllers/feed_controller.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/listing_list_view.dart';

class FeedScreen extends ConsumerStatefulWidget {
  final bool isLookingForRoommate;

  const FeedScreen({
    super.key,
    required this.isLookingForRoommate,
  });

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(feedControllerProvider.notifier);
      final currentFilter = controller.currentFilter;

      controller.search(
        currentFilter.copyWith(
          type: widget.isLookingForRoommate ? 'offering' : 'seeking',
        ),
      );
    });
  }

  void _openFilters(BuildContext context) {
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
  Widget build(BuildContext context) {
    final desktopSupported = ref.watch(desktopLayoutSupportedProvider);
    final isDesktopLayout =
        desktopSupported && MediaQuery.sizeOf(context).width >= kDesktopMinWidth;

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
        title: Text(widget.isLookingForRoommate
            ? 'Buscando Compañero'
            : 'Buscando Piso'),
        actions: [
          IconButton(
            onPressed: () => _openFilters(context),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListingListView(
        onListingTap: (listing) => context.push('/listings/${listing.id}'),
      ),
    );
  }
}

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