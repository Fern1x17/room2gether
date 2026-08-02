import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/centered_form_frame.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_failure.dart';
import '../../domain/validators/auth_validators.dart';
import '../controllers/login_controller.dart';
import '../utils/auth_error_translator.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.emailNotConfirmed = false});

  /// Muestra de entrada el aviso de "cuenta sin confirmar" con el botón de
  /// reenviar. Llega desde el callback del correo cuando el enlace ya había
  /// caducado o se había usado, para que ese camino no acabe en un callejón
  /// sin salida.
  final bool emailNotConfirmed;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Segundos que el botón "Reenviar" queda deshabilitado tras un envío.
  static const _resendCooldownSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _showResend = widget.emailNotConfirmed;
  bool _resending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final response = await ref
        .read(loginControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted || response == null) {
      return;
    }

    context.go('/feed');
  }

  Future<void> _resend() async {
    if (_resending || _cooldownSeconds > 0) return;

    // El reenvío necesita un email válido: es el único dato que identifica la
    // cuenta a confirmar.
    final email = _emailController.text.trim();
    if (validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe tu email para reenviarte la confirmación.'),
        ),
      );
      return;
    }

    setState(() => _resending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendSignupConfirmation(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te hemos reenviado el correo de confirmación.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(translateAuthError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _resending = false);
        _startResendCooldown();
      }
    }
  }

  void _startResendCooldown() {
    setState(() => _cooldownSeconds = _resendCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));

      // La cuenta existe pero está sin confirmar: en vez de dejar solo el
      // aviso, se ofrece reenviar el enlace desde aquí mismo.
      if (error is AuthFailure && error.emailNotConfirmed && !_showResend) {
        setState(() => _showResend = true);
      }
    });

    final isLoading = ref.watch(loginControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CenteredFormFrame(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: AppLogo()),
                  const SizedBox(height: 24),
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
                    autofillHints: const [AutofillHints.password],
                    validator: validatePassword,
                  ),
                  if (_showResend) ...[
                    const SizedBox(height: 16),
                    _ResendNotice(
                      cooldownSeconds: _cooldownSeconds,
                      enabled: !_resending && _cooldownSeconds == 0,
                      onResend: _resend,
                    ),
                  ],
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
                          : const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading ? null : () => context.go('/register'),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de cuenta sin confirmar con el botón para pedir un enlace nuevo.
class _ResendNotice extends StatelessWidget {
  const _ResendNotice({
    required this.cooldownSeconds,
    required this.enabled,
    required this.onResend,
  });

  final int cooldownSeconds;
  final bool enabled;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu cuenta está sin confirmar. Comprueba tu correo, y si el enlace '
            'ha caducado escribe tu email arriba y te enviamos uno nuevo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: enabled ? onResend : null,
              child: Text(
                cooldownSeconds > 0
                    ? 'Reenviar confirmación ($cooldownSeconds s)'
                    : 'Reenviar confirmación',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
