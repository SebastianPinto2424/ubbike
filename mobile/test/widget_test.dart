import 'package:flutter_test/flutter_test.dart';
import 'package:ubbike/main.dart';

void main() {
  testWidgets('muestra la pantalla de ingreso UBBike', (tester) async {
    await tester.pumpWidget(const AplicacionUBBike());

    expect(find.bySemanticsLabel('Logo UBBike'), findsOneWidget);
    expect(find.text('Ingreso seguro'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
