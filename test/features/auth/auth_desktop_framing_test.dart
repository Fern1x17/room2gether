import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/layout/breakpoints.dart';
import 'package:room2gether/core/widgets/centered_form_frame.dart';

/// El encuadre de auth en escritorio se decide solo por ancho (regla del
/// proyecto): a partir de kDesktopMinWidth el contenido se limita a
/// kAuthContentMaxWidth y se centra; por debajo se muestra tal cual.
void _setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: CenteredFormFrame(child: child)),
  );
}

void main() {
  group('CenteredFormFrame', () {
    final childKey = GlobalKey();

    testWidgets('en ancho de móvil el contenido ocupa todo el ancho', (
      tester,
    ) async {
      _setViewSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        _wrap(SizedBox(key: childKey, width: double.infinity, height: 100)),
      );
      await tester.pumpAndSettle();

      // El hijo se devuelve tal cual: ocupa el ancho completo, no los 448.
      expect(tester.getSize(find.byKey(childKey)).width, 400);
    });

    testWidgets('en ancho de escritorio limita y centra el contenido', (
      tester,
    ) async {
      _setViewSize(tester, const Size(1280, 900));
      await tester.pumpWidget(
        _wrap(SizedBox(key: childKey, width: double.infinity, height: 100)),
      );
      await tester.pumpAndSettle();

      // El hijo queda encajado en el ancho máximo de auth, no en los 1280.
      expect(tester.getSize(find.byKey(childKey)).width, kAuthContentMaxWidth);
      // Y centrado horizontalmente dentro de la ventana.
      final center = tester.getCenter(find.byKey(childKey));
      expect(center.dx, 1280 / 2);
    });
  });
}
