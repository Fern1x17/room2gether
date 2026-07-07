import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../feed/presentation/controllers/feed_controller.dart';
import '../../data/listing_repository.dart';
import '../../domain/models/listing_draft.dart';
import '../../domain/validators/listing_validators.dart';
import '../controllers/create_listing_controller.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _priceController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isOffering = true;
  final List<PendingPhoto> _photos = [];
  String? _photosError;
  String? _budgetError;

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _priceController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    final newPhotos = <PendingPhoto>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      final extension = file.path.contains('.') ? file.path.split('.').last : 'jpg';
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
    final photosError =
        validateListingPhotos(_photos.length, isOffering: _isOffering);
    final budgetError = _isOffering
        ? null
        : validateListingBudgetRange(
            _budgetMinController.text, _budgetMaxController.text);
    setState(() {
      _photosError = photosError;
      _budgetError = budgetError;
    });
    if (!formValid || photosError != null || budgetError != null) return;

    final neighborhood = _neighborhoodController.text.trim();
    final description = _descriptionController.text.trim();
    final draft = ListingDraft(
      type: _isOffering ? 'offering' : 'seeking',
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      city: _cityController.text.trim(),
      neighborhood: neighborhood.isEmpty ? null : neighborhood,
      price: _isOffering ? int.parse(_priceController.text.trim()) : null,
      budgetMin: _isOffering ? null : int.parse(_budgetMinController.text.trim()),
      budgetMax: _isOffering ? null : int.parse(_budgetMaxController.text.trim()),
    );

    final created = await ref
        .read(createListingControllerProvider.notifier)
        .create(draft, photos: _isOffering ? _photos : const []);

    if (!mounted || !created) return;
    ref.invalidate(feedControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publicación creada.')),
    );
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createListingControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    });

    final isLoading = ref.watch(createListingControllerProvider).isLoading;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear publicación')),
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
                      _photos.isEmpty
                          ? 'Adjuntar fotos del piso'
                          : 'Fotos adjuntadas: ${_photos.length} (añadir más)',
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
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateListingCity,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _neighborhoodController,
                  decoration: InputDecoration(
                    labelText: 'Barrio',
                    hintText: _isOffering ? null : 'Vacío = cualquiera',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      validateListingNeighborhood(value, isOffering: _isOffering),
                ),
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
                        : const Text('Publicar'),
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
