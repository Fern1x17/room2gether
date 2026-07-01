const int minCleanlinessLevel = 1;
const int maxCleanlinessLevel = 5;
const List<String> validSchedules = ['early_riser', 'night_owl'];

String? validateDisplayName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return 'Introduce un nombre.';
  }
  return null;
}

String? validateBudgetRange(String? minValue, String? maxValue) {
  final minText = minValue?.trim() ?? '';
  final maxText = maxValue?.trim() ?? '';
  if (minText.isEmpty || maxText.isEmpty) {
    return null;
  }
  final min = int.tryParse(minText);
  final max = int.tryParse(maxText);
  if (min == null || max == null) {
    return 'Introduce un presupuesto válido.';
  }
  if (min > max) {
    return 'El presupuesto mínimo no puede ser mayor que el máximo.';
  }
  return null;
}

String? validateCleanlinessLevel(int? value) {
  if (value == null) {
    return null;
  }
  if (value < minCleanlinessLevel || value > maxCleanlinessLevel) {
    return 'El nivel de limpieza debe estar entre $minCleanlinessLevel y $maxCleanlinessLevel.';
  }
  return null;
}
