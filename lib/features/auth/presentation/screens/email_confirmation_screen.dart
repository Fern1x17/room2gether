import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/centered_form_frame.dart';
import '../../data/auth_repository.dart';

/// Pantalla a la que apunta el enlace del correo de confirmación, y solo él.
///
/// No se llega aquí navegando por la app: el router la protege y manda al
/// inicio a quien abra la URL sin un enlace válido. Existe únicamente en la
/// web, porque un enlace de correo siempre abre un navegador — aunque la cuenta
/// se haya creado desde la app de Android.
///
/// Admite las dos formas en las que puede llegar la confirmación:
/// - `token_hash` + `type`: se verifica contra el servidor. Es la que usa la
///   plantilla de correo del proyecto y funciona en cualquier dispositivo.
/// - `code`: canje PKCE, solo válido en el navegador que hizo el registro. Se
///   mantiene por si se vuelve a la plantilla `{{ .ConfirmationURL }}`.
///
/// En ambos casos la sesión resultante pertenece A LA CUENTA DEL ENLACE y
/// sobrescribe cualquier sesión previa en este navegador, de modo que nunca se
/// queda en la cuenta equivocada.
///
/// Al confirmar **no navega sola**: es una pantalla final con un botón para
/// entrar. Mientras tanto, la pestaña o la app donde se hizo el registro está
/// reintentando el login por su cuenta y entra sola en cuanto la cuenta queda
/// confirmada (ver `ConfirmEmailPanel`).
class EmailConfirmationScreen extends ConsumerStatefulWidget {
  const EmailConfirmationScreen({
    super.key,
    this.code,
    this.tokenHash,
    this.type,
    this.errorDescription,
  });

  /// Código PKCE del enlace, o `null` si la URL no lo trae.
  final String? code;

  /// Token del enlace en el flujo `token_hash`, o `null`.
  final String? tokenHash;

  /// Tipo de enlace (`signup`, `recovery`…) que acompaña a [tokenHash].
  final String? type;

  /// Descripción del error si Supabase redirige con `error_description`
  /// (p. ej. enlace caducado), o `null` si no hay error.
  final String? errorDescription;

  @override
  ConsumerState<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

enum _Status { verifying, confirmed, failed }

class _EmailConfirmationScreenState
    extends ConsumerState<EmailConfirmationScreen> {
  _Status _status = _Status.verifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
  }

  Future<void> _confirm() async {
    if (widget.errorDescription != null) {
      _setStatus(_Status.failed);
      return;
    }

    final tokenHash = widget.tokenHash;
    final code = widget.code;
    final repository = ref.read(authRepositoryProvider);

    try {
      if (tokenHash != null && tokenHash.isNotEmpty) {
        await repository.verifyEmailToken(
          tokenHash: tokenHash,
          type: widget.type,
        );
      } else if (code != null && code.isNotEmpty) {
        await repository.exchangeCode(code);
      } else {
        _setStatus(_Status.failed);
        return;
      }
    } catch (_) {
      _setStatus(_Status.failed);
      return;
    }

    _setStatus(_Status.confirmed);
  }

  void _setStatus(_Status status) {
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: CenteredFormFrame(
              child: switch (_status) {
                _Status.verifying => const _Verifying(),
                _Status.confirmed => _Confirmed(
                  // La sesión ya está creada en este navegador, así que se
                  // entra directo al alta de perfil.
                  onEnter: () => context.go('/onboarding'),
                ),
                // Con `confirm=pending` el login ofrece reenviar el correo,
                // para que un enlace caducado no sea un callejón sin salida.
                _Status.failed => _Failed(
                  onRequestNewLink: () => context.go('/login?confirm=pending'),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Verifying extends StatelessWidget {
  const _Verifying();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text('Confirmando tu cuenta…'),
      ],
    );
  }
}

class _Confirmed extends StatelessWidget {
  const _Confirmed({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          '¡Cuenta confirmada!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Ya puedes empezar a usar Room2gether. Si te registraste en otra '
          'pestaña o en la app del móvil, allí ya has entrado solo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(onPressed: onEnter, child: const Text('Entrar')),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRequestNewLink});

  final VoidCallback onRequestNewLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 72, color: theme.colorScheme.error),
        const SizedBox(height: 24),
        Text(
          'No hemos podido confirmar tu cuenta. El enlace puede haber caducado '
          'o ya haberse usado.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: onRequestNewLink,
            child: const Text('Pedir un enlace nuevo'),
          ),
        ),
      ],
    );
  }
}
