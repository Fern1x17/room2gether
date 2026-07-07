import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/my_listings_controller.dart';

/// Lista de publicaciones propias, mostrada dentro del perfil (CU-07/CU-08:
/// "entra en el perfil y selecciona una publicación").
class MyListingsSection extends ConsumerWidget {
  const MyListingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return listingsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Column(
        children: [
          const Text('No se pudieron cargar tus publicaciones.'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(myListingsProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return Text(
            'No tienes ninguna publicación.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Column(
          children: [
            for (final listing in listings)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Chip(
                    label: Text(listing.isOffering ? 'Ofrezco' : 'Busco'),
                    visualDensity: VisualDensity.compact,
                  ),
                  title: Text(listing.title),
                  subtitle: Text(listing.priceLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/listings/${listing.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
