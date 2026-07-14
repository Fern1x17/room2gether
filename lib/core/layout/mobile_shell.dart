import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_destinations.dart';

/// Forma móvil: barra de navegación inferior con las secciones principales.
/// La comparten Android y la web estrecha; no distingue plataforma.
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tocar la pestaña activa vuelve a la raíz de esa rama.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in shellDestinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
