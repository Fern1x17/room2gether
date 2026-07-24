import 'package:flutter/material.dart';

/// Secciones de la navegación principal, compartidas por la barra inferior
/// (móvil) y el rail lateral (escritorio). Única fuente de verdad: para
/// añadir una sección (p. ej. "Guardados" cuando exista la feature) basta
/// con añadirla aquí y crear su rama en el router.
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showsUnreadBadge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Si la sección lleva el contador de mensajes sin leer encima del icono.
  /// Lo pinta `ShellDestinationIcon`, común a la barra y al rail.
  final bool showsUnreadBadge;
}

const shellDestinations = <ShellDestination>[
  ShellDestination(
    icon: Icons.search,
    selectedIcon: Icons.search,
    label: 'Buscar',
  ),
  ShellDestination(
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
    label: 'Chats',
    showsUnreadBadge: true,
  ),
  ShellDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Perfil',
  ),
];
