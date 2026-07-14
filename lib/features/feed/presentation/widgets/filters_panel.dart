import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/address_selector.dart';
import '../../../../core/widgets/city_selector.dart';
import '../../domain/models/listing_filter.dart';
import '../controllers/recent_searches_controller.dart';

/// Formulario de filtros del feed. Widget de contenido compartido: en móvil
/// vive dentro del FiltersSheet (bottom sheet) y en escritorio como panel
/// persistente. No cierra nada por sí mismo: quien lo aloja decide qué hacer
/// tras [onApply] (el sheet hace pop; el panel persistente, nada).
class FiltersPanel extends ConsumerStatefulWidget {
  const FiltersPanel({
    super.key,
    required this.title,
    required this.initialFilter,
    required this.onApply,
  });

  final String title;
  final ListingFilter initialFilter;
  final ValueChanged<ListingFilter> onApply;

  @override
  ConsumerState<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends ConsumerState<FiltersPanel> {
  String? _cityId;
  String? _cityName;
  String? _neighborhoodName;
  late final TextEditingController _maxPriceController;
  String? _type;

  // Aumenta al aplicar una búsqueda reciente para remontar los selectores
  // (ciudad/barrio) con los nuevos valores iniciales sin perder el foco en
  // el uso normal.
  int _recentGeneration = 0;

  @override
  void initState() {
    super.initState();
    _cityId = widget.initialFilter.cityId;
    _cityName = widget.initialFilter.cityName;
    _neighborhoodName = widget.initialFilter.neighborhood;
    _maxPriceController = TextEditingController(
      text: widget.initialFilter.maxPrice?.toString() ?? '',
    );
    _type = widget.initialFilter.type;
  }

  @override
  void dispose() {
    _maxPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    final filter = ListingFilter(
      cityId: _cityId,
      cityName: _cityName,
      // El barrio se filtra por su nombre canónico del catálogo.
      neighborhood: _neighborhoodName,
      maxPrice: int.tryParse(_maxPriceController.text.trim()),
      type: _type,
    );
    widget.onApply(filter);
  }

  void _applyRecent(ListingFilter filter) {
    // Sincroniza el formulario con la búsqueda aplicada: en el panel
    // persistente de escritorio los campos quedan a la vista.
    setState(() {
      _cityId = filter.cityId;
      _cityName = filter.cityName;
      _neighborhoodName = filter.neighborhood;
      _maxPriceController.text = filter.maxPrice?.toString() ?? '';
      _type = filter.type;
      _recentGeneration++;
    });
    widget.onApply(filter);
  }

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        CitySelector(
          key: ValueKey('filter-city-$_recentGeneration'),
          initialCityName: _cityName,
          onCitySelected: (city) {
            setState(() {
              _cityId = city?.id;
              _cityName = city?.name;
              _neighborhoodName = null;
            });
          },
        ),
        const SizedBox(height: 16),
        AddressSelector(
          key: ValueKey('filter-neighborhood-$_cityId-$_recentGeneration'),
          cityName: _cityName,
          neighborhoodsOnly: true,
          labelText: 'Barrio',
          initialSelection: _neighborhoodName == null
              ? null
              : AddressSelection(
                  displayText: _neighborhoodName!,
                  neighborhood: _neighborhoodName,
                  isPreciseAddress: false,
                ),
          onSelected: (selection) {
            _neighborhoodName = selection?.neighborhood;
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _maxPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio máximo (€)'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Cualquiera'),
              selected: _type == null,
              onSelected: (_) => setState(() => _type = null),
            ),
            ChoiceChip(
              label: const Text('Busco'),
              selected: _type == 'seeking',
              onSelected: (_) => setState(() => _type = 'seeking'),
            ),
            ChoiceChip(
              label: const Text('Ofrezco'),
              selected: _type == 'offering',
              onSelected: (_) => setState(() => _type = 'offering'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _apply,
            child: const Text('Aplicar filtros'),
          ),
        ),
        recentSearches.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (searches) {
            if (searches.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Búsquedas recientes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final search in searches)
                      ActionChip(
                        label: Text(_describe(search)),
                        onPressed: () => _applyRecent(search),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _describe(ListingFilter filter) {
    final parts = <String>[
      if (filter.cityName != null) filter.cityName!,
      if (filter.neighborhood != null) filter.neighborhood!,
      if (filter.maxPrice != null) 'hasta ${filter.maxPrice}€',
      if (filter.type == 'seeking') 'busco',
      if (filter.type == 'offering') 'ofrezco',
    ];
    return parts.isEmpty ? 'Sin filtros' : parts.join(' · ');
  }
}
