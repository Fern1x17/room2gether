import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/centered_form_frame.dart';
import '../../data/auth_repository.dart';

/// Página de callback del enlace de confirmación de email (flujo PKCE).
///
/// Recibe el `code` que Supabase añade al redirigir tras confirmar. Lo canjea
/// por una sesión: `exchangeCode` establece la sesión que corresponde AL TOKEN
/// y sobrescribe cualquier sesión previa que hubiera en este navegador, de modo
/// que nunca se queda en la cuenta equivocada. Tras el canje redirige al alta
/// de perfil.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({
    super.key,
    required this.code,
    this.errorDescription,
  });

  /// Código PKCE del enlace, o `null` si la URL no lo trae.
  final String? code;

  /// Descripción del error si Supabase redirige con `error_description`
  /// (p. ej. enlace caducado), o `null` si no hay error.
  final String? errorDescription;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    final code = widget.code;
    if (widget.errorDescription != null || code == null || code.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      await ref.read(authRepositoryProvider).exchangeCode(code);
      if (!mounted) return;
      context.go('/onboarding');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CenteredFormFrame(
              child: _failed
                  ? _CallbackError(
                      onGoToLogin: () => context.go('/login'),
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 24),
                        Text('Confirmando tu cuenta…'),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallbackError extends StatelessWidget {
  const _CallbackError({required this.onGoToLogin});

  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 56,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'No hemos podido confirmar tu cuenta. El enlace puede haber caducado '
          'o ya haberse usado.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onGoToLogin,
          child: const Text('Ir a iniciar sesión'),
        ),
      ],
    );
  }
}
