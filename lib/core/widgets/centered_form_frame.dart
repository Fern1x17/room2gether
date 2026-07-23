import 'package:flutter/widgets.dart';

import '../layout/breakpoints.dart';

/// Encuadra el contenido de las pantallas sin navegación principal
/// (bienvenida, login, registro) en escritorio: a partir de
/// [kDesktopMinWidth] lo centra horizontalmente y le limita el ancho a
/// [kAuthContentMaxWidth] para que el formulario no se estire de borde a
/// borde. Por debajo del breakpoint devuelve el hijo tal cual, de modo que
/// en móvil no cambia nada.
///
/// La decisión es 100 % por ancho disponible (regla del proyecto): estas
/// pantallas viven fuera del shell adaptativo y no tienen master-detail que
/// romper, así que no aplican el techo de plataforma del shell.
class CenteredFormFrame extends StatelessWidget {
  const CenteredFormFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < kDesktopMinWidth) {
      return child;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kAuthContentMaxWidth),
        child: child,
      ),
    );
  }
}
