import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/address_selector.dart';
import '../../../../core/widgets/city_selector.dart';
import '../../../feed/domain/models/listing.dart';
import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../../feed/presentation/controllers/listing_detail_controller.dart';
import '../../data/listing_repository.dart';
import '../../domain/models/listing_draft.dart';
import '../../domain/validators/listing_validators.dart';
import '../controllers/create_listing_controller.dart';
import '../controllers/my_listings_controller.dart';
import '../controllers/update_listing_controller.dart';

/// Formulario de publicación. Sin [initial] crea una nueva (CU-06); con
/// [initial] modifica la existente precargando sus datos (CU-08).
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.initial});

  final Listing? initial;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _cityId;
  String? _cityName;
  AddressSelection? _address;
  bool _showExactAddress = false;
  final _priceController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isOffering = true;
  final List<PendingPhoto> _photos = [];
  final List<String> _existingPhotoUrls = [];
  String? _photosError;
  String? _budgetError;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _isOffering = initial.isOffering;
      _titleController.text = initial.title;
      _cityId = initial.cityId;
      _cityName = initial.cityName;
      // Precarga de la ubicación: dirección exacta si la hay (RLS siempre la
      // devuelve al dueño), si no el barrio guardado.
      if (initial.formattedAddress != null) {
        _address = AddressSelection(
          placeId: initial.addressPlaceId,
          displayText: initial.formattedAddress!,
          formattedAddress: initial.formattedAddress,
          neighborhood: initial.neighborhood,
          latitude: initial.latitude,
          longitude: initial.longitude,
          isPreciseAddress: true,
        );
        _showExactAddress = initial.addressIsPublic;
      } else if (initial.neighborhood != null) {
        _address = AddressSelection(
          displayText: initial.neighborhood!,
          neighborhood: initial.neighborhood,
          isPreciseAddress: false,
        );
      }
      _priceController.text = initial.price?.toString() ?? '';
      _budgetMinController.text = initial.budgetMin?.toString() ?? '';
      _budgetMaxController.text = initial.budgetMax?.toString() ?? '';
      _descriptionController.text = initial.description ?? '';
      _existingPhotoUrls.addAll(initial.photos);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;
    final newPhotos = <PendingPhoto>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      final extension = file.path.contains('.')
          ? file.path.split('.').last
          : 'jpg';
      newPhotos.add((bytes: Uint8List.fromList(bytes), extension: extension));
    }
    if (!mounted) return;
    setState(() {
      _photos.addAll(newPhotos);
      _photosError = null;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final photosError = validateListingPhotos(
      _existingPhotoUrls.length + _photos.length,
      isOffering: _isOffering,
    );
    final budgetError = _isOffering
        ? null
        : validateListingBudgetRange(
            _budgetMinController.text,
            _budgetMaxController.text,
          );
    setState(() {
      _photosError = photosError;
      _budgetError = budgetError;
    });
    if (!formValid || photosError != null || budgetError != null) return;

    final description = _descriptionController.text.trim();
    final address = _address;
    final isPrecise = address?.isPreciseAddress ?? false;
    final draft = ListingDraft(
      type: _isOffering ? 'offering' : 'seeking',
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      cityId: _cityId!,
      // El barrio (texto) es lo que se muestra públicamente si la dirección
      // exacta no es pública o no existe (CU-06).
      neighborhood: address?.neighborhood,
      addressPlaceId: isPrecise ? address?.placeId : null,
      formattedAddress: isPrecise ? address?.formattedAddress : null,
      latitude: isPrecise ? address?.latitude : null,
      longitude: isPrecise ? address?.longitude : null,
      showExactAddress: isPrecise && _showExactAddress,
      price: _isOffering ? int.parse(_priceController.text.trim()) : null,
      budgetMin: _isOffering
          ? null
          : int.parse(_budgetMinController.text.trim()),
      budgetMax: _isOffering
          ? null
          : int.parse(_budgetMaxController.text.trim()),
    );

    if (_isEditing) {
      final listingId = widget.initial!.id;
      final updated = await ref
          .read(updateListingControllerProvider.notifier)
          .save(
            listingId,
            draft,
            newPhotos: _isOffering ? _photos : const [],
            keptPhotoUrls: _isOffering ? _existingPhotoUrls : const [],
          );
      if (!mounted || !updated) return;
      ref.invalidate(feedControllerProvider);
      ref.invalidate(myListingsProvider);
      ref.invalidate(listingDetailProvider(listingId));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación actualizada.')));
      context.pop();
      return;
    }

    final created = await ref
        .read(createListingControllerProvider.notifier)
        .create(draft, photos: _isOffering ? _photos : const []);

    if (!mounted || !created) return;
    ref.invalidate(feedControllerProvider);
    ref.invalidate(myListingsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publicación creada.')));
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createListingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
    ref.listen(updateListingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    final isLoading = _isEditing
        ? ref.watch(updateListingControllerProvider).isLoading
        : ref.watch(createListingControllerProvider).isLoading;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modificar publicación' : 'Crear publicación'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Tengo piso y busco compañero'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Busco piso y compañero'),
                    ),
                  ],
                  selected: {_isOffering},
                  onSelectionChanged: (selection) =>
                      setState(() => _isOffering = selection.first),
                ),
                const SizedBox(height: 24),
                if (_isOffering) ...[
                  OutlinedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _existingPhotoUrls.isEmpty && _photos.isEmpty
                          ? 'Adjuntar fotos del piso'
                          : 'Fotos: ${_existingPhotoUrls.length + _photos.length} (añadir más)',
                    ),
                  ),
                  if (_existingPhotoUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingPhotoUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingPhotoUrls[index],
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _existingPhotoUrls.removeAt(index),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    child: Icon(Icons.close, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_photos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _photos[index].bytes,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _photos.removeAt(index)),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    child: Icon(Icons.close, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_photosError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        _photosError!,
                        style: TextStyle(color: errorColor, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio por mes (€)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _isOffering ? validateListingPrice(value) : null,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Presupuesto mín. (€)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Presupuesto máx. (€)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_budgetError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        _budgetError!,
                        style: TextStyle(color: errorColor, fontSize: 12),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateListingTitle,
                ),
                const SizedBox(height: 16),
                CitySelector(
                  initialCityName: _cityName,
                  onCitySelected: (city) {
                    setState(() {
                      _cityId = city?.id;
                      _cityName = city?.name;
                      // La ubicación pertenece a una ciudad: al cambiarla se
                      // descarta la selección anterior.
                      _address = null;
                      _showExactAddress = false;
                    });
                  },
                  validator: (_) => validateListingCityId(_cityId),
                ),
                const SizedBox(height: 16),
                AddressSelector(
                  // Recrea el selector al cambiar de ciudad (vacía su campo).
                  key: ValueKey('address-$_cityId'),
                  cityName: _cityName,
                  initialSelection: _address,
                  onSelected: (selection) {
                    setState(() {
                      _address = selection;
                      if (selection == null || !selection.isPreciseAddress) {
                        _showExactAddress = false;
                      }
                    });
                  },
                  hintText: _isOffering
                      ? 'Calle y número, o solo el barrio'
                      : 'Vacío = cualquiera',
                  validator: (_) => validateListingLocation(
                    _address?.displayText,
                    isOffering: _isOffering,
                  ),
                ),
                if (_address?.isPreciseAddress ?? false) ...[
                  if (_address?.neighborhood != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        'Barrio: ${_address!.neighborhood}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar la dirección completa'),
                    subtitle: const Text(
                      'Si está desactivado, el anuncio solo muestra el barrio.',
                    ),
                    value: _showExactAddress,
                    onChanged: (value) =>
                        setState(() => _showExactAddress = value),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Guardar cambios' : 'Publicar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
