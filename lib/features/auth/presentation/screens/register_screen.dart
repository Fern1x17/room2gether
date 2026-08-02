import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/link_opener.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/centered_form_frame.dart';
import '../../../profile/domain/validators/profile_validators.dart';
import '../../domain/validators/auth_validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/confirm_email_panel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdateController = TextEditingController();
  DateTime? _birthdate;
  bool _acceptsPrivacyPolicy = false;
  bool _privacyPolicyError = false;

  /// Email del alta pendiente de confirmar. Mientras no sea `null`, la pantalla
  /// muestra el aviso de "confirma tu correo" en lugar del formulario. No se
  /// cambia de pantalla para que volver a corregir el email sea inmediato.
  String? _pendingEmail;

  // Documentos legales servidos como páginas estáticas del sitio (web/legal/).
  static const _privacyPolicyPath = '/legal/privacy.html';
  static const _termsPath = '/legal/terms.html';

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _birthdate ?? DateTime(now.year - minAge, now.month, now.day),
      firstDate: DateTime(now.year - maxAge),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked == null) return;
    setState(() {
      _birthdate = picked;
      _birthdateController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

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

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _privacyPolicyError = !_acceptsPrivacyPolicy);
    if (!formValid || !_acceptsPrivacyPolicy) {
      return;
    }

    final response = await ref
        .read(registerControllerProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          birthdate: _birthdate!,
        );

    if (!mounted || response == null) {
      return;
    }

    if (response.session != null) {
      context.go('/profile');
    } else {
      // Falta confirmar el email: nos quedamos en esta misma pantalla y
      // cambiamos el formulario por el aviso, que se encarga del reenvío y del
      // auto-login por polling. Las credenciales siguen en los controladores,
      // en memoria, así que volver al formulario las conserva.
      setState(() => _pendingEmail = _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    final isLoading = ref.watch(registerControllerProvider).isLoading;

    final pendingEmail = _pendingEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CenteredFormFrame(
            child: pendingEmail == null
                ? _registerForm(isLoading)
                : ConfirmEmailPanel(
                    email: pendingEmail,
                    password: _passwordController.text,
                    onEdit: () => setState(() => _pendingEmail = null),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _registerForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: AppLogo()),
          const SizedBox(height: 24),
          // Obligatorio: es el nombre con el que aparecerá el usuario en sus
          // publicaciones y en el chat.
          AuthTextField(
            controller: _displayNameController,
            label: 'Nombre',
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.name],
            validator: validateDisplayName,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Contraseña',
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthdateController,
            readOnly: true,
            onTap: _pickBirthdate,
            validator: (_) => validateBirthdate(_birthdate),
            decoration: const InputDecoration(
              labelText: 'Fecha de nacimiento',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Antes de continuar, consulta la ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                _LegalLink(
                  label: 'política de privacidad',
                  onTap: () => _openLegalDoc(_privacyPolicyPath),
                ),
                Text(' y los ', style: Theme.of(context).textTheme.bodySmall),
                _LegalLink(
                  label: 'términos y condiciones',
                  onTap: () => _openLegalDoc(_termsPath),
                ),
                Text('.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: _acceptsPrivacyPolicy,
            onChanged: (value) {
              setState(() {
                _acceptsPrivacyPolicy = value ?? false;
                _privacyPolicyError = false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('He leído y acepto la política de privacidad'),
          ),
          if (_privacyPolicyError)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Debes aceptar la política de privacidad para continuar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
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
                  : const Text('Crear cuenta'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('¿Ya tienes cuenta? Inicia sesión'),
          ),
        ],
      ),
    );
  }
}

/// Texto pulsable con estilo de enlace, para los documentos legales.
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
