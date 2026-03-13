import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/shared/widgets/emotion_orb.dart';

void main() {
  testWidgets('EmotionOrb muestra emoji de emocion y responde al tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EmotionOrb(
              mood: 'joy',
              animated: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    final joyEmoji = AppConstants.emotionEmojis['joy']!;
    expect(find.text(joyEmoji), findsOneWidget);

    await tester.tap(find.byType(EmotionOrb));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
