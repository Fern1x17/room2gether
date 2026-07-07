import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/listing_detail_controller.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Publicación')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar la publicación.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (listing) {
          final theme = Theme.of(context);
          final location = [
            listing.neighborhood,
            listing.city,
          ].where((part) => part != null && part.isNotEmpty).join(', ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.photos.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listing.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          listing.photos[index],
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Chip(label: Text(listing.isOffering ? 'Ofrezco' : 'Busco')),
                const SizedBox(height: 16),
                Text(listing.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (location.isNotEmpty)
                  Text(location, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  listing.priceLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (listing.description != null && listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Descripción', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(listing.description!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
