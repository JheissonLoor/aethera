import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/universe/widgets/goal_horizon.dart';
import 'package:aethera/features/universe/widgets/universe_loading_widgets.dart';
import 'package:aethera/shared/models/goal_model.dart';

GoalModel _goal({
  required String id,
  required String title,
  required double progress,
  required String symbol,
  bool completed = false,
}) {
  final now = DateTime(2026, 3, 18, 20, 0);
  return GoalModel(
    id: id,
    coupleId: 'c1',
    title: title,
    description: '',
    targetDate: now.add(const Duration(days: 30)),
    progress: progress,
    symbol: symbol,
    createdAt: now.subtract(const Duration(days: 2)),
    completedAt: completed ? now : null,
  );
}

class _TolerantGoldenComparator extends LocalFileComparator {
  final double precisionTolerance;

  _TolerantGoldenComparator(super.testFile, this.precisionTolerance);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= precisionTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    final testFile = comparator.basedir.resolve(
      'universe_visual_golden_test.dart',
    );
    goldenFileComparator = _TolerantGoldenComparator(testFile, 0.02);
  }

  testWidgets('regresion visual de horizonte y skeletons', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goals = <GoalModel>[
      _goal(
        id: 'g1',
        title: 'Encuentro en Lima',
        progress: 0.22,
        symbol: 'bridge',
      ),
      _goal(id: 'g2', title: 'Viaje al mar', progress: 0.66, symbol: 'island'),
      _goal(
        id: 'g3',
        title: 'Meta cumplida',
        progress: 1.0,
        symbol: 'castle',
        completed: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: AetheraTokens.deepSpace,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 110,
                  child: GoalHorizon(goals: goals, animate: false),
                ),
                const SizedBox(height: 16),
                const UniverseTopPanelsSkeleton(compact: false, animate: false),
                const SizedBox(height: 16),
                const UniverseBottomActionsSkeleton(
                  compact: false,
                  animate: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/universe_visual_states.png'),
    );
  });
}
