import 'package:diacritic/diacritic.dart';

/// Normaliza texto para comparar ciudades: minúsculas y sin tildes/diacríticos
/// (mismo criterio que la columna cities.normalized_name).
String normalizeText(String input) {
  return removeDiacritics(input.trim().toLowerCase());
}
