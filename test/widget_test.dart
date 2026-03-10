import 'package:aethera/shared/widgets/aethera_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AetheraButton triggers callback on tap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AetheraButton(label: 'Entrar', onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.text('ENTRAR'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
