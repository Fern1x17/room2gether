import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/link_opener.dart';
import '../../../../core/widgets/city_selector.dart';
// 1. Añadimos la importación del controlador del tema
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/presentation/controllers/sign_out_controller.dart';
import '../../../listing/presentation/widgets/my_listings_section.dart';
import '../../domain/models/profile.dart';
import '../../domain/validators/profile_validators.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

const Map<String, String> _scheduleLabels = {
  'early_riser': 'Madrugador',
  'night_owl': 'Noctámbulo',
};

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _cityId;
  String? _cityName;
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  bool _initialized = false;
  bool _isSmoker = false;
  bool _hasPets = false;
  int? _cleanlinessLevel;
  String? _schedule;
  String? _avatarUrl;
  String? _budgetError;
  bool _uploadingAvatar = false;

  // Documentos legales servidos como páginas estáticas del sitio (web/legal/).
  static const _privacyPolicyPath = '/legal/privacy.html';
  static const _termsPath = '/legal/terms.html';

  void _openLegalDoc(String path) {
    if (kIsWeb) {
      openExternalLink(path);
    } else {
      // En móvil aún no hay lanzador de enlaces; se indica dónde consultarlo.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disponible en room2gether.com$path')),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  void _initializeFrom(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _displayNameController.text = profile.displayName;
    _bioController.text = profile.bio ?? '';
    _cityId = profile.cityId;
    _cityName = profile.cityName;
    _budgetMinController.text = profile.budgetMin?.toString() ?? '';
    _budgetMaxController.text = profile.budgetMax?.toString() ?? '';
    _isSmoker = profile.isSmoker;
    _hasPets = profile.hasPets;
    _cleanlinessLevel = profile.cleanlinessLevel;
    _schedule = profile.schedule;
    _avatarUrl = profile.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final bytes = await picked.readAsBytes();
    final extension = picked.path.contains('.')
        ? picked.path.split('.').last
        : 'jpg';
    final url = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(bytes: bytes, fileExtension: extension);

    if (!mounted) return;
    setState(() {
      _uploadingAvatar = false;
      if (url != null) _avatarUrl = url;
    });

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la foto. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  Future<void> _submit(Profile current) async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final budgetError = validateBudgetRange(
      _budgetMinController.text,
      _budgetMaxController.text,
    );
    setState(() => _budgetError = budgetError);
    if (!formValid || budgetError != null) return;

    final updated = current.copyWith(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      avatarUrl: _avatarUrl,
      cityId: _cityId,
      cityName: _cityName,
      budgetMin: int.tryParse(_budgetMinController.text.trim()),
      budgetMax: int.tryParse(_budgetMaxController.text.trim()),
      isSmoker: _isSmoker,
      hasPets: _hasPets,
      cleanlinessLevel: _cleanlinessLevel,
      schedule: _schedule,
    );

    final ok = await ref.read(profileControllerProvider.notifier).save(updated);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final signedOut = await ref
        .read(signOutControllerProvider.notifier)
        .signOut();
    if (!mounted) return;
    if (signedOut) {
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final isSaving = profileAsync.isLoading && _initialized;

    // 2. Leemos el estado del tema para saber qué mostrar en el interruptor
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.system;
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu perfil'),
        actions: [
          IconButton(
            onPressed: () => context.go('/feed'),
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Ver publicaciones',
          ),
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(profileControllerProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            _initializeFrom(profile);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              onPressed: _uploadingAvatar ? null : _pickAvatar,
                              icon: _uploadingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt, size: 20),
                              tooltip: 'Cambiar foto',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: validateDisplayName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CitySelector(
                      initialCityName: _cityName,
                      onCitySelected: (city) {
                        _cityId = city?.id;
                        _cityName = city?.name;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Presupuesto mín. (€)',
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _isSmoker,
                      onChanged: (value) => setState(() => _isSmoker = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fumador'),
                    ),
                    SwitchListTile(
                      value: _hasPets,
                      onChanged: (value) => setState(() => _hasPets = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tiene mascotas'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nivel de limpieza',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Slider(
                      value: (_cleanlinessLevel ?? 3).toDouble(),
                      min: minCleanlinessLevel.toDouble(),
                      max: maxCleanlinessLevel.toDouble(),
                      divisions: maxCleanlinessLevel - minCleanlinessLevel,
                      label: (_cleanlinessLevel ?? 3).toString(),
                      onChanged: (value) =>
                          setState(() => _cleanlinessLevel = value.round()),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Horario',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Sin especificar'),
                          selected: _schedule == null,
                          onSelected: (_) => setState(() => _schedule = null),
                        ),
                        for (final entry in _scheduleLabels.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: _schedule == entry.key,
                            onSelected: (_) =>
                                setState(() => _schedule = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: isSaving ? null : () => _submit(profile),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 3. Añadimos el interruptor de Modo Oscuro con su separador
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Modo Oscuro'),
                      secondary: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      ),
                      value: isDarkMode,
                      onChanged: (bool value) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .toggleTheme(value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    Text(
                      'Tus publicaciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const MyListingsSection(),
                    const SizedBox(height: 24),

                    const Divider(),
                    Text(
                      'Legal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Política de privacidad'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openLegalDoc(_privacyPolicyPath),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Términos y condiciones'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openLegalDoc(_termsPath),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
