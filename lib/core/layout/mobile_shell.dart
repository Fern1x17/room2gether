import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/feed/presentation/controllers/feed_controller.dart';
import 'shell_destination_icon.dart';
import 'shell_destinations.dart';
import 'tab_history_controller.dart';

/// Margen para encadenar las dos pulsaciones que cierran la app. Es también lo
/// que dura el aviso, para que el mensaje desaparezca justo cuando deja de ser
/// verdad.
const Duration kExitConfirmWindow = Duration(seconds: 2);

/// Forma móvil: barra de navegación inferior con las secciones principales.
/// La comparten Android y la web estrecha; no distingue plataforma.
///
/// Aquí vive además el botón atrás del sistema. Que esté en este widget y no
/// en el `AdaptiveShell` no es casual: `MobileShell` solo se construye por
/// debajo del breakpoint, así que el comportamiento queda acotado al ancho de
/// móvil sin preguntarle a la plataforma.
class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  /// Cuándo se armó la salida. `null` = la siguiente pulsación no cierra.
  DateTime? _exitArmedAt;

  /// Última pestaña anotada, para no repetir el apunte en cada rebuild.
  int? _recordedIndex;

  /// Anota la pestaña actual en el historial. Va en un post-frame porque tocar
  /// un provider durante el build dispara "setState during build" en quien lo
  /// esté escuchando.
  void _recordTab() {
    final index = widget.navigationShell.currentIndex;
    if (index == _recordedIndex) return;
    _recordedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tabHistoryProvider.notifier).visit(index);
    });
  }

  Future<void> _handleBack() async {
    // 1. ¿Hay pestaña anterior, o estamos fuera del feed? Volvemos allí.
    if (goToPreviousTab(
      ref,
      currentIndex: widget.navigationShell.currentIndex,
      goBranch: (index) => widget.navigationShell.goBranch(index),
    )) {
      _exitArmedAt = null;
      return;
    }

    // 2. En el feed y sin historial: la segunda pulsación seguida cierra.
    final now = DateTime.now();
    final armed = _exitArmedAt;
    if (armed != null && now.difference(armed) <= kExitConfirmWindow) {
      await SystemNavigator.pop();
      return;
    }

    // 3. Primera pulsación: recarga el feed y avisa de qué hará la siguiente.
    _exitArmedAt = now;
    unawaited(ref.read(feedControllerProvider.notifier).refresh());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pulsa otra vez para salir'),
        duration: kExitConfirmWindow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _recordTab();

    return PopScope(
      // Se intercepta siempre: quién cierra la app lo decide _handleBack. Las
      // pantallas apiladas dentro de una rama (detalle, chat abierto) no
      // llegan hasta aquí, las cierra antes el navegador de su propia rama.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            // Tocar la pestaña activa vuelve a la raíz de esa rama.
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          destinations: [
            for (final (index, destination) in shellDestinations.indexed)
              NavigationDestination(
                icon: ShellDestinationIcon(
                  destination: destination,
                  selected: false,
                ),
                selectedIcon: ShellDestinationIcon(
                  destination: destination,
                  selected: true,
                ),
                label: destination.label,
                tooltip: destination.label,
                key: ValueKey('shell-destination-$index'),
              ),
          ],
        ),
      ),
    );
  }
}
