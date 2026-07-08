import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/presentation/controllers/listing_detail_controller.dart';
import 'create_listing_screen.dart';

/// Carga la publicación y abre el formulario en modo edición (CU-08).
class EditListingScreen extends ConsumerWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return listingAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Modificar publicación')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No se pudo cargar la publicación.'),
          ),
        ),
      ),
      data: (listing) => CreateListingScreen(initial: listing),
    );
  }
}
