import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índice del feed dentro de `shellDestinations`. Es la pestaña de inicio:
/// el botón atrás acaba siempre aquí, y solo desde aquí se sale de la app.
const int kFeedTabIndex = 0;

/// Tope de pestañas recordadas. Sin él, alternar entre dos secciones un rato
/// largo haría crecer la pila sin fin y saldría un rosario de pulsaciones
/// atrás para llegar al feed.
const int _kMaxHistory = 20;

/// Pila de pestañas visitadas, para que el botón atrás del móvil vuelva a la
/// anterior en vez de cerrar la app.
///
/// Vive fuera del shell porque lo consultan dos sitios: el propio
/// `MobileShell` (botón atrás del sistema) y la flecha de la lista de Chats.
class TabHistory extends Notifier<List<int>> {
  @override
  List<int> build() => const [];

  /// Registra que se ha entrado en [index]. Repetir la pestaña de arriba no
  /// apila: volver a A estando en A no es un paso nuevo del historial.
  void visit(int index) {
    if (state.isNotEmpty && state.last == index) return;
    final next = [...state, index];
    state = next.length > _kMaxHistory
        ? next.sublist(next.length - _kMaxHistory)
        : next;
  }

  /// Quita la pestaña actual y devuelve a cuál hay que volver, o `null` si no
  /// hay ninguna anterior (la app arrancó aquí).
  int? goBack() {
    if (state.length < 2) return null;
    final next = state.sublist(0, state.length - 1);
    state = next;
    return next.last;
  }

  /// Deja el historial con [index] como único elemento.
  void reset(int index) => state = [index];
}

final tabHistoryProvider = NotifierProvider<TabHistory, List<int>>(
  TabHistory.new,
);

/// Lleva a la pestaña anterior, o al feed si no había ninguna.
///
/// Devuelve `false` cuando no hay a dónde ir —ya estamos en el feed sin
/// historial—, que es el único caso en el que procede salir de la app.
///
/// Recibe [currentIndex] y [goBranch] sueltos, y no el shell, porque los dos
/// que lo llaman lo tienen en formas distintas y sin interfaz común: el
/// `MobileShell` maneja el widget `StatefulNavigationShell` y la lista de
/// Chats, que está por debajo, solo alcanza su `State` vía `of(context)`.
///
/// Tras cambiar de rama, `MobileShell` vuelve a registrar la pestaña; no
/// deshace este paso porque [TabHistory.visit] ignora la que ya está arriba.
bool goToPreviousTab(
  WidgetRef ref, {
  required int currentIndex,
  required void Function(int index) goBranch,
}) {
  final history = ref.read(tabHistoryProvider.notifier);

  final previous = history.goBack();
  if (previous != null) {
    goBranch(previous);
    return true;
  }

  if (currentIndex != kFeedTabIndex) {
    // La app arrancó fuera del feed (p. ej. desde una notificación): atrás
    // lleva al feed en vez de cerrar.
    history.reset(kFeedTabIndex);
    goBranch(kFeedTabIndex);
    return true;
  }

  return false;
}
