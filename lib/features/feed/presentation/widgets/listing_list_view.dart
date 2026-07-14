import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/listing.dart';
import '../controllers/feed_controller.dart';
import 'listing_card.dart';

/// Lista de publicaciones del feed con sus estados de carga/error/vacío.
/// Widget de contenido compartido: en móvil ocupa la pantalla del feed y en
/// escritorio es la columna central del master-detail.
class ListingListView extends ConsumerWidget {
  const ListingListView({
    super.key,
    required this.onListingTap,
    this.selectedListingId,
  });

  final ValueChanged<Listing> onListingTap;

  /// Publicación resaltada (la abierta en el panel de detalle de escritorio).
  final String? selectedListingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(feedControllerProvider);

    return listingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(feedControllerProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay publicaciones que coincidan con tu búsqueda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListingCard(
                listing: listing,
                selected: listing.id == selectedListingId,
                onTap: () => onListingTap(listing),
              ),
            );
          },
        );
      },
    );
  }
}
