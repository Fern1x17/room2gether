import '../utils/normalize_text.dart';
import 'city.dart';

const int maxCitySuggestions = 8;

/// Nivel de coincidencia de [city] con [normalizedQuery] (0 = mejor), o null
/// si no hay coincidencia. Niveles según la especificación de RF-15:
///  0. coincidencia exacta con normalized_name
///  1. normalized_name empieza por lo escrito
///  2. alguna palabra de normalized_name empieza por lo escrito
///  3. normalized_name contiene lo escrito
///  4. algún alias contiene lo escrito
int? cityMatchLevel(City city, String normalizedQuery) {
  final name = city.normalizedName;
  if (name == normalizedQuery) return 0;
  if (name.startsWith(normalizedQuery)) return 1;
  if (name.split(' ').any((word) => word.startsWith(normalizedQuery))) return 2;
  if (name.contains(normalizedQuery)) return 3;
  if (city.aliases.any((alias) => alias.contains(normalizedQuery))) return 4;
  return null;
}

/// Sugerencias para [query]: máximo [maxCitySuggestions], ordenadas por nivel
/// (y alfabéticamente dentro del mismo nivel). Con la consulta vacía devuelve
/// directamente las ciudades recibidas (las activas).
List<City> rankCities(List<City> cities, String query) {
  final normalizedQuery = normalizeText(query);

  if (normalizedQuery.isEmpty) {
    final sorted = List.of(cities)..sort((a, b) => a.name.compareTo(b.name));
    return sorted.take(maxCitySuggestions).toList();
  }

  final scored = <({City city, int level})>[];
  for (final city in cities) {
    final level = cityMatchLevel(city, normalizedQuery);
    if (level != null) {
      scored.add((city: city, level: level));
    }
  }
  scored.sort((a, b) {
    final byLevel = a.level.compareTo(b.level);
    if (byLevel != 0) return byLevel;
    return a.city.name.compareTo(b.city.name);
  });
  return scored.take(maxCitySuggestions).map((entry) => entry.city).toList();
}
