import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cities/cities_repository.dart';
import '../cities/city.dart';
import '../cities/city_ranking.dart';
import '../utils/normalize_text.dart';

/// Selector de ciudad con autocompletado (RF-15).
///
/// - Carga las ciudades activas una sola vez ([activeCitiesProvider]) y filtra
///   en memoria a cada pulsación con el ranking de [rankCities].
/// - Con el campo vacío muestra directamente las ciudades activas.
/// - Emite SIEMPRE una [City] seleccionada (o null si se borra la selección):
///   el texto libre nunca cuenta como ciudad — al perder el foco, si el texto
///   no corresponde a una selección se restaura o se descarta.
class CitySelector extends ConsumerStatefulWidget {
  const CitySelector({
    super.key,
    this.initialCityName,
    required this.onCitySelected,
    this.labelText = 'Ciudad',
    this.hintText,
    this.validator,
  });

  final String? initialCityName;
  final ValueChanged<City?> onCitySelected;
  final String labelText;
  final String? hintText;

  /// Validador para usar dentro de un Form (recibe el texto del campo; la
  /// pantalla decide validando su propio cityId seleccionado).
  final String? Function(String?)? validator;

  @override
  ConsumerState<CitySelector> createState() => _CitySelectorState();
}

class _CitySelectorState extends ConsumerState<CitySelector> {
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialCityName;
  }

  /// Al perder el foco: si el texto coincide exactamente con una ciudad se
  /// selecciona; si no, se restaura la última selección (o se vacía). Así el
  /// usuario nunca puede dejar texto libre como ciudad.
  void _resolveOnBlur(TextEditingController controller, List<City> cities) {
    final text = controller.text.trim();
    if (text == (_selectedName ?? '')) return;

    if (text.isEmpty) {
      _selectedName = null;
      widget.onCitySelected(null);
      return;
    }

    final normalized = normalizeText(text);
    City? exact;
    for (final city in cities) {
      if (city.normalizedName == normalized) {
        exact = city;
        break;
      }
    }
    if (exact != null) {
      _selectedName = exact.name;
      controller.text = exact.name;
      widget.onCitySelected(exact);
    } else {
      controller.text = _selectedName ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(activeCitiesProvider);

    return citiesAsync.when(
      loading: () => TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
          errorText: 'No se pudieron cargar las ciudades.',
          suffixIcon: IconButton(
            onPressed: () => ref.invalidate(activeCitiesProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reintentar',
          ),
        ),
      ),
      data: (cities) => Autocomplete<City>(
        initialValue: TextEditingValue(text: widget.initialCityName ?? ''),
        displayStringForOption: (city) => city.name,
        optionsBuilder: (textEditingValue) =>
            rankCities(cities, textEditingValue.text),
        onSelected: (city) {
          _selectedName = city.name;
          widget.onCitySelected(city);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus) return;
              // Un microtask para no pisar la selección cuando el blur viene
              // de tocar una opción del desplegable.
              Future.microtask(() {
                if (mounted) _resolveOnBlur(controller, cities);
              });
            },
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              validator: widget.validator,
              onChanged: (text) {
                if (_selectedName != null && text != _selectedName) {
                  _selectedName = null;
                  widget.onCitySelected(null);
                }
              },
              onFieldSubmitted: (_) => onFieldSubmitted(),
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}
