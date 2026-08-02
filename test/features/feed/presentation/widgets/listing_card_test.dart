import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/features/feed/domain/models/listing.dart';
import 'package:room2gether/features/feed/presentation/widgets/listing_card.dart';

import '../../fakes/fake_feed_repository.dart';

Widget _wrap(Listing listing) {
  return MaterialApp(
    home: Scaffold(
      body: ListingCard(listing: listing, onTap: () {}),
    ),
  );
}

void main() {
  group('ListingCard', () {
    testWidgets('muestra el nombre de quien publicó', (tester) async {
      await tester.pumpWidget(_wrap(fakeListing(ownerName: 'Ana')));

      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('si la cuenta no tiene nombre usa un texto de reserva', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(fakeListing(ownerName: null)));

      expect(find.text('Usuario'), findsOneWidget);
    });

    testWidgets('en "Ofrezco" con fotos enseña la primera como miniatura', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          fakeListing(
            type: 'offering',
            photos: const [
              'https://example.com/primera.jpg',
              'https://example.com/segunda.jpg',
            ],
          ),
        ),
      );

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(1));
      expect(
        (images.single.image as NetworkImage).url,
        'https://example.com/primera.jpg',
      );
    });

    testWidgets('en "Ofrezco" sin fotos no hay miniatura', (tester) async {
      await tester.pumpWidget(
        _wrap(fakeListing(type: 'offering', photos: const [])),
      );

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('en "Busco" no se enseña foto aunque la tenga', (tester) async {
      await tester.pumpWidget(
        _wrap(
          fakeListing(
            type: 'seeking',
            photos: const ['https://example.com/primera.jpg'],
          ),
        ),
      );

      expect(find.text('Busco'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
