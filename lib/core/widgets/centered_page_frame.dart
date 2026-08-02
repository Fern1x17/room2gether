import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';

/// Encuadra en escritorio una pantalla completa —con su propio `Scaffold` y su
/// `AppBar`— que vive fuera del shell adaptativo.
///
/// Es la misma técnica que aplica `DesktopShell` a la sección Perfil
/// (`Align` arriba y al centro + `ConstrainedBox`), pero para las rutas raíz,
/// que no pasan por el shell y por eso se estiraban de borde a borde. El
/// `Scaffold` exterior existe para pintar el fondo alrededor del contenido ya
/// limitado; sin él quedaría el hueco en negro.
///
/// Se diferencia de `CenteredFormFrame` en qué envuelve: aquel encuadra el
/// contenido *dentro* del `body` de una pantalla (login, registro), y este
/// encuadra la pantalla entera.
///
/// Por debajo de [kDesktopMinWidth] devuelve el hijo tal cual, sin envolverlo
/// en nada: en móvil —también en la web desde el móvil— no cambia nada. La
/// decisión es 100 % por ancho disponible, como manda la regla del proyecto.
class CenteredPageFrame extends StatelessWidget {
  const CenteredPageFrame({
    super.key,
    required this.child,
    required this.maxWidth,
  });

  final Widget child;

  /// Ancho máximo del contenido en escritorio (p. ej.
  /// [kContentPageMaxWidth]).
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < kDesktopMinWidth) {
      return child;
    }
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
