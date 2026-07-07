String? validateListingTitle(String? value) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) {
    return 'Introduce un título.';
  }
  return null;
}

String? validateListingCity(String? value) {
  final city = value?.trim() ?? '';
  if (city.isEmpty) {
    return 'Introduce la ciudad.';
  }
  return null;
}

/// El barrio es obligatorio si ya se tiene piso; si se busca piso puede
/// dejarse vacío ("cualquiera"), tal como indica CU-06.
String? validateListingNeighborhood(String? value, {required bool isOffering}) {
  final neighborhood = value?.trim() ?? '';
  if (isOffering && neighborhood.isEmpty) {
    return 'Introduce el barrio donde está el piso.';
  }
  return null;
}

String? validateListingPrice(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Introduce el precio por mes.';
  }
  final price = int.tryParse(raw);
  if (price == null || price < 0) {
    return 'Introduce un precio válido.';
  }
  return null;
}

String? validateListingBudgetRange(String? minValue, String? maxValue) {
  final minText = minValue?.trim() ?? '';
  final maxText = maxValue?.trim() ?? '';
  if (minText.isEmpty || maxText.isEmpty) {
    return 'Introduce el presupuesto mínimo y máximo.';
  }
  final min = int.tryParse(minText);
  final max = int.tryParse(maxText);
  if (min == null || max == null || min < 0 || max < 0) {
    return 'Introduce un presupuesto válido.';
  }
  if (min > max) {
    return 'El presupuesto mínimo no puede ser mayor que el máximo.';
  }
  return null;
}

/// CU-06 (2.1): si ya se tiene piso "se deben adjuntar imágenes".
String? validateListingPhotos(int photoCount, {required bool isOffering}) {
  if (isOffering && photoCount == 0) {
    return 'Adjunta al menos una foto del piso.';
  }
  return null;
}
