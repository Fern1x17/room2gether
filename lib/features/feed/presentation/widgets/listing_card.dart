import 'package:flutter/material.dart';

import '../../domain/models/listing.dart';

/// Lado (dp) de la miniatura cuadrada de la tarjeta.
const double _thumbnailSize = 88;

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Solo las de "Ofrezco" enseñan foto: en las de "Busco" lo que
                // se ofrece es la persona, no un espacio.
                if (listing.isOffering && listing.photos.isNotEmpty) ...[
                  _Thumbnail(url: listing.photos.first),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              listing.isOffering ? 'Ofrezco' : 'Busco',
                            ),
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
                      const SizedBox(height: 4),
                      Text(
                        listing.ownerNameLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primera foto de la publicación, cuadrada y recortada.
///
/// Reserva el hueco mientras carga y lo conserva si la imagen falla, para que
/// la tarjeta no dé saltos ni se rompa por una URL caída.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _thumbnailSize,
        height: _thumbnailSize,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.photo_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
