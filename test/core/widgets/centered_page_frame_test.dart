import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room2gether/core/layout/breakpoints.dart';
import 'package:room2gether/core/widgets/centered_page_frame.dart';

/// Pantalla completa de prueba: igual que las reales, trae su propio Scaffold.
const _child = Scaffold(appBar: null, body: Center(child: Text('CONTENIDO')));

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap() {
  return const MaterialApp(
    home: CenteredPageFrame(maxWidth: kProfileContentMaxWidth, child: _child),
  );
}

/// Ancho real que ocupa el contenido en pantalla.
double _childWidth(WidgetTester tester) {
  return tester.getSize(find.byWidget(_child)).width;
}

void main() {
  group('CenteredPageFrame', () {
    testWidgets('en escritorio limita el ancho y centra el contenido', (
      tester,
    ) async {
      _setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(_childWidth(tester), kProfileContentMaxWidth);

      // Centrado: los márgenes a izquierda y derecha son iguales.
      final box = tester.getRect(find.byWidget(_child));
      expect(box.left, closeTo(1400 - box.right, 0.01));
      expect(find.text('CONTENIDO'), findsOneWidget);
    });

    testWidgets('justo por debajo del breakpoint no encuadra nada', (
      tester,
    ) async {
      _setSize(tester, const Size(kDesktopMinWidth - 1, 900));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Ocupa todo el ancho: en móvil no cambia nada.
      expect(_childWidth(tester), kDesktopMinWidth - 1);
    });

    testWidgets('en móvil devuelve el hijo sin envolverlo', (tester) async {
      _setSize(tester, const Size(400, 800));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(_childWidth(tester), 400);
      // Sin Scaffold exterior: solo está el de la propia pantalla.
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('en escritorio añade el Scaffold que pinta el fondo', (
      tester,
    ) async {
      _setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsNWidgets(2));
    });
  });
}
