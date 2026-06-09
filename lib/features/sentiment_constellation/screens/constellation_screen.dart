import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';
import 'package:aethera/features/sentiment_constellation/providers/constellation_provider.dart';
import 'package:aethera/features/sentiment_constellation/widgets/constellation_painter.dart';

class ConstellationScreen extends ConsumerWidget {
  const ConstellationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constellation = ref.watch(constellationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Constellation'),
        centerTitle: true,
        backgroundColor: AetheraTokens.deepSpace,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AetheraTokens.deepSpace,
              AetheraTokens.cosmicNight,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: constellation.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
          ),
          data: (data) {
            if (data == null || data.points.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your constellation is waiting',
                      style: AetheraTokens.displayMedium(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start sharing emotions to create your emotional journey',
                      style: AetheraTokens.bodyLarge(color: AetheraTokens.moonGlow),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AetheraTokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Your Emotional Journey',
                    style: AetheraTokens.displayMedium(),
                  ),
                  const SizedBox(height: 24),

                  // Constellation visualization
                  AetheraGlassPanel(
                    height: 400,
                    padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                    child: CustomPaint(
                      painter: ConstellationPainter(data),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  Text(
                    'Journey Stats',
                    style: AetheraTokens.displaySmall(),
                  ),
                  const SizedBox(height: 16),

                  // Dominant emotion
                  MorphCard(
                    height: 120,
                    primaryColor: AetheraTokens.colorForEmotion(data.dominantEmotion),
                    secondaryColor: AetheraTokens.nebulaPurple,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Dominant Emotion',
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.dominantEmotion.toUpperCase(),
                          style: AetheraTokens.displaySmall(
                            color: AetheraTokens.colorForEmotion(data.dominantEmotion),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Journey complexity
                  MorphCard(
                    height: 120,
                    primaryColor: AetheraTokens.auroraTeal,
                    secondaryColor: AetheraTokens.goldenDawn,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Journey Complexity',
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.journeyComplexity.toStringAsFixed(1)}',
                          style: AetheraTokens.displaySmall(
                            color: AetheraTokens.auroraTeal,
                          ),
                        ),
                        Text(
                          'emotional shifts',
                          style: AetheraTokens.bodySmall(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total moments
                  MorphCard(
                    height: 120,
                    primaryColor: AetheraTokens.roseQuartz,
                    secondaryColor: AetheraTokens.nebulaPurple,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Emotional Moments',
                          style: AetheraTokens.bodyMedium(
                            color: AetheraTokens.moonGlow,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data.points.length}',
                          style: AetheraTokens.displayMedium(
                            color: AetheraTokens.roseQuartz,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
