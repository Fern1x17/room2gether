import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/widgets/conversations_pane.dart';
import '../../features/feed/presentation/widgets/feed_desktop_panes.dart';
import '../widgets/app_logo.dart';
import 'shell_destination_icon.dart';
import 'shell_destinations.dart';

/// Forma de escritorio (solo web ancha): cabecera con logo y acción de
/// publicar, rail de navegación lateral y área de contenido. En la sección
/// Buscar el contenido es master-detail: filtros persistentes, lista y panel
/// de detalle (el navegador de la rama).
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.navigationShell,
    required this.currentUri,
  });

  final StatefulNavigationShell navigationShell;
  final Uri currentUri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Cabecera fina: logo + Publicar (equivalente al FAB del móvil).
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                const AppLogo(size: 36),
                const SizedBox(width: 12),
                Text(
                  'Room2gether',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.push('/listings/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => navigationShell.goBranch(
                    index,
                    // Igual que en móvil: reactivar la sección vuelve a su raíz.
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  destinations: [
                    for (final destination in shellDestinations)
                      NavigationRailDestination(
                        icon: ShellDestinationIcon(
                          destination: destination,
                          selected: false,
                        ),
                        selectedIcon: ShellDestinationIcon(
                          destination: destination,
                          selected: true,
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                // Columnas extra en las secciones master-detail. Buscar tiene
                // filtros + lista; Chats, la lista de conversaciones. En ambas,
                // el panel de detalle es el navegador de la rama (el Expanded
                // de abajo): la publicación o el chat abiertos.
                if (navigationShell.currentIndex == 0) ...[
                  const SizedBox(width: 300, child: FeedFiltersPane()),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Expanded(
                    flex: 5,
                    child: FeedListPane(currentUri: currentUri),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ],
                if (navigationShell.currentIndex == 1) ...[
                  SizedBox(
                    width: 320,
                    child: ConversationsListPane(currentUri: currentUri),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ],
                // El navegador de las ramas: panel de detalle en Buscar y
                // área completa en las demás secciones. La key preserva el
                // estado cuando cambia su posición dentro del Row; el árbol
                // interior mantiene siempre la misma forma para no perder
                // estado al cambiar de sección (solo varían los valores).
                Expanded(
                  key: const ValueKey('desktop-content'),
                  flex: 4,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // En Buscar y Chats el navegador de la rama es el panel
                        // de detalle (publicación / chat) y ocupa todo su ancho.
                        // En Perfil, sección de contenido único, se limita para
                        // que el formulario no se estire de borde a borde.
                        maxWidth: navigationShell.currentIndex == 2
                            ? 840
                            : double.infinity,
                      ),
                      child: navigationShell,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
