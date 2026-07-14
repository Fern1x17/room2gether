import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cities/cities_repository.dart';
import '../cities/city.dart';
import '../places/places_service.dart';

/// Selector de ciudad con autocompletado de Google Places (RF-15).
///
/// - Las sugerencias vienen de Places Autocomplete (API nueva) restringido a
///   localidades de España, con debounce y session tokens para abaratar coste.
/// - Al elegir una sugerencia se resuelve contra la tabla `cities` mediante la
///   RPC `get_or_create_city` (la crea si es la primera vez que alguien la
///   selecciona) y se emite la [City] resultante.
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
  static const _debounce = Duration(milliseconds: 350);
  static const _minQueryLength = 2;

  String? _selectedName;

  /// Controller interno del Autocomplete (asignado en fieldViewBuilder) para
  /// poder corregir el texto al nombre canónico tras resolver la selección.
  TextEditingController? _controller;

  /// Resolviendo la selección contra `cities` (RPC en curso).
  bool _resolving = false;
  bool _searchFailed = false;

  /// Identifica la última búsqueda lanzada para descartar respuestas obsoletas
  /// (el debounce se implementa esperando y comprobando que sigue siendo la
  /// última).
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.initialCityName;
  }

  Future<Iterable<CityPrediction>> _buildOptions(String rawQuery) async {
    final query = rawQuery.trim();
    // Tras seleccionar, el campo contiene el nombre canónico: no re-buscar.
    if (_resolving ||
        query.length < _minQueryLength ||
        query == _selectedName) {
      _searchId++;
      return const [];
    }

    final id = ++_searchId;
    await Future<void>.delayed(_debounce);
    if (id != _searchId || !mounted) return const [];
    // Re-comprobación: la selección puede haberse resuelto durante la espera
    // (el framework escribe el nombre en el campo antes de resolver la RPC).
    if (query == _selectedName) return const [];

    try {
      final results = await ref
          .read(placesServiceProvider)
          .autocompleteCities(query);
      if (id != _searchId || !mounted) return const [];
      if (_searchFailed) setState(() => _searchFailed = false);
      return results;
    } catch (_) {
      if (id == _searchId && mounted) setState(() => _searchFailed = true);
      return const [];
    }
  }

  /// Resuelve la sugerencia elegida contra el catálogo `cities` y emite la
  /// ciudad canónica resultante.
  Future<void> _onPredictionSelected(
    CityPrediction prediction,
    TextEditingController controller,
  ) async {
    ref.read(placesServiceProvider).endSession();
    setState(() {
      _resolving = true;
      _searchFailed = false;
    });
    try {
      final city = await ref
          .read(citiesRepositoryProvider)
          .getOrCreateCity(placeId: prediction.placeId, name: prediction.name);
      if (!mounted) return;
      _selectedName = city.name;
      controller.text = city.name;
      widget.onCitySelected(city);
    } catch (_) {
      if (!mounted) return;
      controller.text = _selectedName ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo seleccionar la ciudad. Inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  /// Al perder el foco, si el texto no corresponde a una selección se restaura
  /// la última (o se vacía). Así el usuario nunca deja texto libre como ciudad.
  void _restoreOnBlur(TextEditingController controller) {
    final text = controller.text.trim();
    if (text == (_selectedName ?? '')) return;

    if (text.isEmpty) {
      _selectedName = null;
      widget.onCitySelected(null);
      return;
    }
    controller.text = _selectedName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<CityPrediction>(
      initialValue: TextEditingValue(text: widget.initialCityName ?? ''),
      displayStringForOption: (prediction) => prediction.name,
      optionsBuilder: (textEditingValue) =>
          _buildOptions(textEditingValue.text),
      optionsViewBuilder: (context, onSelected, options) {
        // Vista propia para mostrar la descripción completa ("Toro, Zamora,
        // España") y así distinguir municipios homónimos.
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.name),
                    subtitle: Text(option.description),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (prediction) {
        final controller = _controller;
        if (controller != null) {
          _onPredictionSelected(prediction, controller);
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller = controller;
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) return;
            // Un microtask para no pisar la selección cuando el blur viene de
            // tocar una opción del desplegable.
            Future.microtask(() {
              if (mounted && !_resolving) _restoreOnBlur(controller);
            });
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: widget.validator,
            enabled: !_resolving,
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
              errorText: _searchFailed
                  ? 'No se pudieron cargar las sugerencias.'
                  : null,
              suffixIcon: _resolving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.location_city_outlined),
            ),
          ),
        );
      },
    );
  }
}
