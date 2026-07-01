import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/feed_controller.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/listing_card.dart';

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
    final listingsAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roomie'),
        actions: [
          IconButton(
            onPressed: () => _openFilters(context, ref),
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
          ),
          IconButton(
            onPressed: () => context.push('/onboarding'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Tu perfil',
          ),
        ],
      ),
      body: listingsAsync.when(
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
                  onTap: () => context.push('/listings/${listing.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
