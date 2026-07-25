import 'package:flutter/material.dart';

import '../../domain/models/listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.selected = false,
  });

  final Listing listing;
  final VoidCallback onTap;

  /// Resalta la tarjeta cuando su detalle está abierto (panel de escritorio).
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      listing.neighborhood,
      listing.cityName,
    ].where((part) => part != null && part.isNotEmpty).join(', ');

    // 1. Envolvemos la tarjeta en un Hero
    return Hero(
      // 2. Le damos una etiqueta única basada en el ID de la publicación
      tag: 'listing_card_${listing.id}',
      // 3. Este flightShuttleBuilder evita que el texto se vea con
      // dobles líneas amarillas feas durante la animación de vuelo.
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            return Material(
              color: Colors.transparent,
              child: toHeroContext.widget,
            );
          },
      child: Card(
        shape: selected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(listing.isOffering ? 'Ofrezco' : 'Busco'),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    Text(
                      listing.priceLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(listing.title, style: theme.textTheme.titleMedium),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(location, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
