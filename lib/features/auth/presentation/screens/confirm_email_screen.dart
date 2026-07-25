import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/centered_form_frame.dart';
import '../../data/auth_repository.dart';
import '../utils/auth_error_translator.dart';

/// Pantalla de espera tras el registro (CU-01). Informa de que hay que
/// confirmar el email y hace polling: reintenta el login con las credenciales
/// recién introducidas hasta que el email quede confirmado (en este dispositivo
/// o en otro) y entonces entra sin que el usuario reescriba nada.
///
/// Las credenciales viven SOLO en memoria (estado del widget) y se limpian al
/// salir. Nunca se persisten ni se registran en logs.
class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  // Intervalo entre reintentos de login.
  static const _pollInterval = Duration(seconds: 4);
  // Segundos que el botón "Reenviar" queda deshabilitado tras un envío.
  static const _resendCooldownSeconds = 30;

  // Credenciales SOLO en memoria; se ponen a null en dispose/cancelar.
  String? _email;
  String? _password;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _attempting = false;
  bool _navigated = false;
  bool _resending = false;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _password = widget.password;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _attemptLogin());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    // Limpieza explícita de las credenciales en memoria.
    _email = null;
    _password = null;
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (_attempting || _navigated) return;
    final email = _email;
    final password = _password;
    if (email == null || password == null) return;

    _attempting = true;
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      if (!mounted) return;
      _navigated = true;
      _pollTimer?.cancel();
      context.go('/onboarding');
    } catch (_) {
      // email_not_confirmed (aún sin confirmar) o un error transitorio de red:
      // en ambos casos seguimos esperando y reintentamos en la próxima vuelta.
    } finally {
      _attempting = false;
    }
  }

  Future<void> _resend() async {
    final email = _email;
    if (email == null || _resending || _cooldownSeconds > 0) return;

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

  void _cancel() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    _email = null;
    _password = null;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resendDisabled = _resending || _cooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirma tu cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancel,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CenteredFormFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Revisa tu correo y confirma tu cuenta.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hemos enviado un enlace de confirmación a ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Esperando confirmación…'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: resendDisabled ? null : _resend,
                    child: Text(
                      _cooldownSeconds > 0
                          ? 'Reenviar correo ($_cooldownSeconds s)'
                          : 'Reenviar correo',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _cancel, child: const Text('Cancelar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
