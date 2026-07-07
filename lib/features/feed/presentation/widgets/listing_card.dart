import 'package:flutter/material.dart';

import '../../domain/models/listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      listing.neighborhood,
      listing.city,
    ].where((part) => part != null && part.isNotEmpty).join(', ');

    return Card(
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
    );
  }
}
