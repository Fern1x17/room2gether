import 'package:room2gether/core/cities/cities_repository.dart';
import 'package:room2gether/core/cities/city.dart';
import 'package:room2gether/core/utils/normalize_text.dart';

class FakeCitiesRepository implements CitiesRepository {
  FakeCitiesRepository({List<City>? cities, this.rpcError})
    : cities = List.of(cities ?? [fakeCity()]);

  final List<City> cities;
  final Object? rpcError;

  /// Último place_id recibido, para asertar en los tests.
  String? lastPlaceId;

  @override
  Future<City> getOrCreateCity({
    required String placeId,
    required String name,
  }) async {
    if (rpcError != null) throw rpcError!;
    lastPlaceId = placeId;
    final normalized = normalizeText(name);
    for (final city in cities) {
      if (city.normalizedName == normalized ||
          city.aliases.contains(normalized)) {
        return city;
      }
    }
    // Igual que la RPC real: la primera selección crea la fila.
    final created = City(
      id: 'city-$normalized',
      name: name,
      normalizedName: normalized,
      isActive: false,
    );
    cities.add(created);
    return created;
  }
}

City fakeCity({
  String id = 'city-vigo',
  String name = 'Vigo',
  String? normalizedName,
  List<String> aliases = const [],
  bool isActive = true,
}) {
  return City(
    id: id,
    name: name,
    normalizedName: normalizedName ?? name.toLowerCase(),
    aliases: aliases,
    isActive: isActive,
  );
}

/// Catálogo del seed real, para tests del selector.
final seedCities = [
  fakeCity(),
  fakeCity(
    id: 'city-santiago',
    name: 'Santiago de Compostela',
    normalizedName: 'santiago de compostela',
    aliases: ['santiago'],
  ),
  fakeCity(
    id: 'city-coruna',
    name: 'A Coruña',
    normalizedName: 'a coruna',
    aliases: ['la coruna', 'coruna'],
  ),
];
