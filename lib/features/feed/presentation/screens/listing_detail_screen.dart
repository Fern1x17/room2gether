import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/current_user_provider.dart';
import '../../../chat/presentation/controllers/chat_controllers.dart';
import '../../../listing/presentation/controllers/my_listings_controller.dart';
import '../../../moderation/presentation/controllers/report_controller.dart';
import '../../../moderation/presentation/widgets/report_dialog.dart';
import '../../domain/models/listing.dart';
import '../controllers/feed_controller.dart';
import '../controllers/listing_detail_controller.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  /// CU-11 desde una publicación: reportar al dueño y bloquearlo.
  Future<void> _reportOwner(
    BuildContext context,
    WidgetRef ref,
    Listing listing,
  ) async {
    final reasons = await showReportDialog(context);
    if (reasons == null || !context.mounted) return;

    final done = await ref
        .read(reportUserControllerProvider.notifier)
        .reportAndBlock(
          reportedUserId: listing.ownerId,
          reportedListingId: listing.id,
          reasons: reasons,
        );
    if (!done || !context.mounted) return;
    // Sus publicaciones dejan de verse y sus chats quedan marcados.
    ref.invalidate(feedControllerProvider);
    ref.invalidate(conversationsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario reportado y bloqueado.')),
    );
    context.pop();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Seguro que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await ref
        .read(deleteListingControllerProvider.notifier)
        .delete(listingId);
    if (!context.mounted) return;
    if (deleted) {
      // La publicación desaparece del feed y del perfil (postcondición CU-07).
      ref.invalidate(feedControllerProvider);
      ref.invalidate(myListingsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación eliminada.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));
    final currentUserId = ref.watch(currentUserIdProvider);

    ref.listen(deleteListingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
    ref.listen(openConversationControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
    ref.listen(reportUserControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    final isDeleting = ref.watch(deleteListingControllerProvider).isLoading;
    final isOpeningChat = ref
        .watch(openConversationControllerProvider)
        .isLoading;

    final loadedListing = listingAsync.value;
    final canReport =
        loadedListing != null &&
        currentUserId != null &&
        loadedListing.ownerId != currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          // CU-11, paso 1-2: botón de opciones en una publicación ajena.
          if (canReport)
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (_) => _reportOwner(context, ref, loadedListing),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('Reportar')),
              ],
            ),
        ],
      ),
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
          final isOwner =
              currentUserId != null && listing.ownerId == currentUserId;
          final location = [
            listing.neighborhood,
            listing.cityName,
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
                if (listing.description != null &&
                    listing.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Descripción', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(listing.description!),
                ],
                if (!isOwner) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: isOpeningChat
                          ? null
                          : () async {
                              final conversation = await ref
                                  .read(
                                    openConversationControllerProvider.notifier,
                                  )
                                  .open(
                                    otherUserId: listing.ownerId,
                                    listingId: listing.id,
                                  );
                              if (conversation != null && context.mounted) {
                                context.push('/chats/${conversation.id}');
                              }
                            },
                      icon: isOpeningChat
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline),
                      label: const Text('Enviar mensaje'),
                    ),
                  ),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/listings/$listingId/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modificar publicación'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: isDeleting
                          ? null
                          : () => _confirmDelete(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      icon: isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('Eliminar publicación'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
