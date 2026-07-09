import 'package:roomie/core/cities/cities_repository.dart';
import 'package:roomie/core/cities/city.dart';

class FakeCitiesRepository implements CitiesRepository {
  FakeCitiesRepository({List<City>? cities, this.fetchError})
    : cities = cities ?? [fakeCity()];

  final List<City> cities;
  final Object? fetchError;

  @override
  Future<List<City>> fetchActiveCities() async {
    if (fetchError != null) throw fetchError!;
    return cities.where((city) => city.isActive).toList();
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

/// Catálogo del seed real, para tests del ranking y del selector.
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
