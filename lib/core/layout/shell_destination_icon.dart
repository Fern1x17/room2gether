import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/controllers/chat_controllers.dart';
import 'shell_destinations.dart';

/// Icono de una sección de la navegación principal, con su badge si la sección
/// lo declara.
///
/// Lo usan la barra inferior (móvil) y el rail (escritorio): el badge se define
/// una sola vez y aparece igual en las dos formas, como el resto de widgets de
/// contenido compartidos.
class ShellDestinationIcon extends ConsumerWidget {
  const ShellDestinationIcon({
    super.key,
    required this.destination,
    required this.selected,
  });

  final ShellDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = Icon(selected ? destination.selectedIcon : destination.icon);
    if (!destination.showsUnreadBadge) return icon;

    final unread = ref.watch(totalUnreadProvider);
    final badge = Badge(
      isLabelVisible: unread > 0,
      label: Text(formatUnreadCount(unread)),
      child: icon,
    );
    if (unread == 0) return badge;

    // El número suelto no dice nada a un lector de pantalla; el nombre de la
    // sección ya lo pone la propia barra o el rail.
    return Semantics(
      label: unread == 1 ? '1 mensaje sin leer' : '$unread mensajes sin leer',
      child: ExcludeSemantics(child: badge),
    );
  }
}
