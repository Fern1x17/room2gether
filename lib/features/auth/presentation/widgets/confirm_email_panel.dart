import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_repository.dart';
import '../utils/auth_error_translator.dart';

/// Aviso de "confirma tu email" que sustituye al formulario dentro de la
/// pantalla de registro (CU-01), sin cambiar de pantalla.
///
/// Hace polling: reintenta el login con las credenciales recién introducidas
/// hasta que el email quede confirmado (en esta pestaña o en otra) y entonces
/// entra sin que el usuario reescriba nada. Ofrece reenviar el correo con un
/// cooldown, y [onEdit] para volver al formulario si el email estaba mal.
///
/// Las credenciales llegan por parámetro y viven SOLO en memoria (en los
/// controladores del formulario, que se destruyen con la pantalla). Nunca se
/// persisten, no viajan en la URL ni se registran en logs.
class ConfirmEmailPanel extends ConsumerStatefulWidget {
  const ConfirmEmailPanel({
    super.key,
    required this.email,
    required this.password,
    required this.onEdit,
  });

  final String email;
  final String password;

  /// Vuelve al formulario de registro (p. ej. para corregir el email).
  final VoidCallback onEdit;

  @override
  ConsumerState<ConfirmEmailPanel> createState() => _ConfirmEmailPanelState();
}

class _ConfirmEmailPanelState extends ConsumerState<ConfirmEmailPanel> {
  // Intervalo entre reintentos de login.
  static const _pollInterval = Duration(seconds: 4);
  // Segundos que el botón "Reenviar" queda deshabilitado tras un envío.
  static const _resendCooldownSeconds = 30;

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _attempting = false;
  bool _navigated = false;
  bool _resending = false;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _attemptLogin());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (_attempting || _navigated) return;

    _attempting = true;
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: widget.email, password: widget.password);
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
    if (_resending || _cooldownSeconds > 0) return;

    setState(() => _resending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendSignupConfirmation(email: widget.email);
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
    final theme = Theme.of(context);
    final resendDisabled = _resending || _cooldownSeconds > 0;

    return Column(
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
        TextButton(
          onPressed: widget.onEdit,
          child: const Text('Cambiar el email'),
        ),
      ],
    );
  }
}
