import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A dónde va el atrás cuando no queda nada que desapilar.
const String kBackFallbackLocation = '/feed';

/// Resuelve el "volver atrás" de una pantalla, en este orden:
///
/// 1. [backLocation], si quien la abrió dijo de dónde se venía.
/// 2. Desapilar, si hay algo debajo.
/// 3. El feed, para que ninguna pantalla se quede sin salida.
///
/// El paso 1 existe porque las rutas raíz (el perfil de otro usuario) y las
/// ramas del shell (chat, detalle de publicación) no se pueden encadenar con
/// `push`: apilar la página del shell sobre una ruta raíz cuando ya está
/// debajo hace que el `Navigator` aborte por claves de página duplicadas. Hay
/// que cruzar con `go`, que reemplaza la pila, y entonces el origen solo
/// sobrevive si viaja aparte.
void goBackFrom(BuildContext context, {String? backLocation}) {
  if (backLocation != null) {
    context.go(backLocation);
  } else if (_canPop(context)) {
    context.pop();
  } else {
    context.go(kBackFallbackLocation);
  }
}

/// ¿Hay algo debajo en la pila? Se pregunta al `Navigator` y no con el
/// `context.canPop()` de go_router porque este último exige un router en el
/// árbol, y hay pantallas que se montan sueltas en los tests. Además es
/// justo lo que mira el `AppBar` para decidir su flecha automática.
bool _canPop(BuildContext context) =>
    Navigator.maybeOf(context)?.canPop() ?? false;

/// Flecha de volver que nunca desaparece.
///
/// La automática de `AppBar` se esconde cuando no hay nada que desapilar, que
/// es justo lo que pasa al llegar a una pantalla con `go`.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.backLocation});

  /// Ruta a la que volver, cuando quien abrió la pantalla la indicó.
  final String? backLocation;

  /// Flecha **solo si hay a dónde volver**: `null` cuando no hay origen ni
  /// nada que desapilar, para que el `AppBar` no reserve el hueco.
  ///
  /// Es lo que hay que usar en las pantallas que además se pintan como panel
  /// de detalle en escritorio (publicación, chat): allí la lista está al lado
  /// y una flecha que saltara al feed no tendría ningún sentido. Reproduce la
  /// flecha automática de siempre, más el caso de [backLocation].
  static Widget? maybe(BuildContext context, {String? backLocation}) {
    if (backLocation == null && !_canPop(context)) return null;
    return AppBackButton(backLocation: backLocation);
  }

  @override
  Widget build(BuildContext context) {
    return BackButton(
      onPressed: () => goBackFrom(context, backLocation: backLocation),
    );
  }
}

/// Hace que el botón atrás del sistema acabe donde la flecha.
///
/// Solo hace falta con [backLocation] puesto: sin él, desapilar ya es lo que
/// hace el sistema por su cuenta. Envolver siempre sería secuestrar el gesto
/// para nada.
class BackDestination extends StatelessWidget {
  const BackDestination({
    super.key,
    required this.backLocation,
    required this.child,
  });

  final String? backLocation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = backLocation;
    if (location == null) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(location);
      },
      child: child,
    );
  }
}
