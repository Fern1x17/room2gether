import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../places/places_service.dart';

/// Ubicación fina elegida en [AddressSelector]: una dirección con calle o
/// solo un barrio (CU-06 permite ambas).
class AddressSelection {
  const AddressSelection({
    this.placeId,
    required this.displayText,
    this.formattedAddress,
    this.neighborhood,
    this.latitude,
    this.longitude,
    required this.isPreciseAddress,
  });

  /// Null solo al precargar publicaciones antiguas sin place_id guardado.
  final String? placeId;

  /// Texto que queda en el campo, p. ej. "Rúa Real, 12" u "Os Castros".
  final String displayText;

  /// Dirección completa formateada (solo si [isPreciseAddress]).
  final String? formattedAddress;

  /// Barrio: derivado de la dirección o elegido directamente.
  final String? neighborhood;
  final double? latitude;
  final double? longitude;

  /// true si es una dirección con calle; false si es solo un barrio/zona.
  final bool isPreciseAddress;
}

/// Selector de dirección o barrio con Google Places Autocomplete (RF-15).
///
/// - Sugerencias restringidas a España y sesgadas a [cityName], con debounce
///   y session tokens (mismo esquema que `CitySelector`).
/// - Al elegir una dirección se piden sus detalles (Place Details con field
///   mask mínima) para derivar barrio y coordenadas; en modo
///   [neighborhoodsOnly] no se piden detalles (el nombre del barrio basta).
/// - Emite SIEMPRE una [AddressSelection] (o null al borrar): el texto libre
///   nunca cuenta como ubicación.
class AddressSelector extends ConsumerStatefulWidget {
  const AddressSelector({
    super.key,
    this.cityName,
    this.initialSelection,
    required this.onSelected,
    this.neighborhoodsOnly = false,
    this.labelText = 'Dirección o barrio',
    this.hintText,
    this.validator,
  });

  /// Ciudad a la que sesgar las sugerencias.
  final String? cityName;

  final AddressSelection? initialSelection;
  final ValueChanged<AddressSelection?> onSelected;

  /// Solo sugerir barrios (para el filtro del feed, CU-09).
  final bool neighborhoodsOnly;

  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;

  @override
  ConsumerState<AddressSelector> createState() => _AddressSelectorState();
}

class _AddressSelectorState extends ConsumerState<AddressSelector> {
  static const _debounce = Duration(milliseconds: 350);
  static const _minQueryLength = 3;

  String? _selectedText;
  TextEditingController? _controller;
  bool _resolving = false;
  bool _searchFailed = false;
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    _selectedText = widget.initialSelection?.displayText;
  }

  Future<Iterable<AddressPrediction>> _buildOptions(String rawQuery) async {
    final query = rawQuery.trim();
    if (_resolving ||
        query.length < _minQueryLength ||
        query == _selectedText) {
      _searchId++;
      return const [];
    }

    final id = ++_searchId;
    await Future<void>.delayed(_debounce);
    if (id != _searchId || !mounted) return const [];
    if (query == _selectedText) return const [];

    try {
      final results = await ref
          .read(placesServiceProvider)
          .autocompleteAddresses(
            query,
            cityName: widget.cityName,
            neighborhoodsOnly: widget.neighborhoodsOnly,
          );
      if (id != _searchId || !mounted) return const [];
      if (_searchFailed) setState(() => _searchFailed = false);
      return results;
    } catch (_) {
      if (id == _searchId && mounted) setState(() => _searchFailed = true);
      return const [];
    }
  }

  Future<void> _onPredictionSelected(
    AddressPrediction prediction,
    TextEditingController controller,
  ) async {
    final places = ref.read(placesServiceProvider);

    // En modo barrio no hacen falta detalles: el nombre es el dato.
    if (widget.neighborhoodsOnly) {
      places.endSession();
      _selectedText = prediction.name;
      controller.text = prediction.name;
      widget.onSelected(
        AddressSelection(
          placeId: prediction.placeId,
          displayText: prediction.name,
          neighborhood: prediction.name,
          isPreciseAddress: false,
        ),
      );
      return;
    }

    setState(() {
      _resolving = true;
      _searchFailed = false;
    });
    try {
      final details = await places.fetchDetails(prediction.placeId);
      if (!mounted) return;
      _selectedText = prediction.name;
      controller.text = prediction.name;
      widget.onSelected(
        AddressSelection(
          placeId: prediction.placeId,
          displayText: prediction.name,
          formattedAddress: details.isPreciseAddress
              ? details.formattedAddress
              : null,
          // Si el lugar elegido ES un barrio, su propio nombre es el barrio.
          neighborhood:
              details.neighborhood ??
              (details.isPreciseAddress ? null : prediction.name),
          latitude: details.latitude,
          longitude: details.longitude,
          isPreciseAddress: details.isPreciseAddress,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      controller.text = _selectedText ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar la dirección. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _restoreOnBlur(TextEditingController controller) {
    final text = controller.text.trim();
    if (text == (_selectedText ?? '')) return;

    if (text.isEmpty) {
      _selectedText = null;
      widget.onSelected(null);
      return;
    }
    controller.text = _selectedText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AddressPrediction>(
      initialValue: TextEditingValue(text: _selectedText ?? ''),
      displayStringForOption: (prediction) => prediction.name,
      optionsBuilder: (textEditingValue) =>
          _buildOptions(textEditingValue.text),
      optionsViewBuilder: (context, onSelected, options) {
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
              if (_selectedText != null && text != _selectedText) {
                _selectedText = null;
                widget.onSelected(null);
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
                  : const Icon(Icons.place_outlined),
            ),
          ),
        );
      },
    );
  }
}
