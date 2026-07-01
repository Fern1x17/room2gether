import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/validators/auth_validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _acceptsPrivacyPolicy = false;
  bool _privacyPolicyError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _privacyPolicyError = !_acceptsPrivacyPolicy);
    if (!formValid || !_acceptsPrivacyPolicy) {
      return;
    }

    final response = await ref.read(registerControllerProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          age: int.parse(_ageController.text.trim()),
        );

    if (!mounted || response == null) {
      return;
    }

    if (response.session != null) {
      context.go('/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Revisa tu email para confirmarla.'),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    });

    final isLoading = ref.watch(registerControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                AuthTextField(
                  controller: _ageController,
                  label: 'Edad',
                  keyboardType: TextInputType.number,
                  validator: validateAge,
                ),
                const SizedBox(height: 16),
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
          ),
        ),
      ),
    );
  }
}
