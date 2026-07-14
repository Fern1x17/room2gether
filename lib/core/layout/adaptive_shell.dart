import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'breakpoints.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

/// Capacidad de mostrar el layout de escritorio.
///
/// Excepción única y aprobada (2026-07-14) a la regla "el layout se decide
/// solo por ancho": el escritorio solo existe en web. Así Android nunca puede
/// renderizarlo, ni en tablet ni en apaisado (un móvil grande en horizontal
/// supera los 840 dp). Es un techo de plataforma, no una decisión de layout:
/// dentro de web la elección sigue siendo 100 % por ancho.
///
/// Provider para poder sobrescribirlo en tests (kIsWeb es false en la VM).
final desktopLayoutSupportedProvider = Provider<bool>((ref) => kIsWeb);

/// Raíz visual de la zona autenticada: elige la forma según el ancho de la
/// ventana. Nunca consulta la plataforma para elegir entre formas.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
    required this.currentUri,
  });

  final StatefulNavigationShell navigationShell;

  /// URI actual del router; el escritorio la usa para saber qué detalle
  /// está abierto en el panel derecho.
  final Uri currentUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktopSupported = ref.watch(desktopLayoutSupportedProvider);
    final width = MediaQuery.sizeOf(context).width;

    if (desktopSupported && width >= kDesktopMinWidth) {
      return DesktopShell(
        navigationShell: navigationShell,
        currentUri: currentUri,
      );
    }
    return MobileShell(navigationShell: navigationShell);
  }
}
