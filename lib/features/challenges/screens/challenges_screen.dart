import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';
import 'package:aethera/features/challenges/providers/challenges_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  Color _categoryColor(String category) {
    switch (category) {
      case 'communication':
        return AetheraTokens.auroraTeal;
      case 'adventure':
        return AetheraTokens.goldenDawn;
      case 'creativity':
        return AetheraTokens.nebulaPurple;
      case 'intimacy':
        return AetheraTokens.roseQuartz;
      default:
        return AetheraTokens.moonGlow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyChallenge = ref.watch(weeklyChallengeProvider);
    final allChallenges = ref.watch(allChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Challenges'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AetheraTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Challenge Section
              Text(
                "This Week's Challenge",
                style: AetheraTokens.displayMedium(),
              ),
              const SizedBox(height: 24),

              weeklyChallenge.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
                ),
                data: (challenge) {
                  if (challenge == null) {
                    return AetheraGlassPanel(
                      padding: const EdgeInsets.all(AetheraTokens.spacingLg),
                      child: Center(
                        child: Text(
                          'No challenge this week yet',
                          style: AetheraTokens.bodyMedium(),
                        ),
                      ),
                    );
                  }

                  final categoryColor = _categoryColor(challenge.category);
                  final difficultyStars = '★' * challenge.difficulty;

                  return MorphCard(
                    height: 280,
                    primaryColor: categoryColor,
                    secondaryColor: AetheraTokens.nebulaPurple,
                    padding: const EdgeInsets.all(AetheraTokens.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: AetheraTokens.displaySmall(
                                  color: categoryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AetheraTokens.radiusSm,
                                ),
                                color: categoryColor.withValues(alpha: 0.2),
                              ),
                              child: Text(
                                challenge.category,
                                style: AetheraTokens.labelSmall(
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          challenge.description,
                          style: AetheraTokens.bodyMedium(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),

                        // Difficulty & Reward
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Difficulty: $difficultyStars',
                              style: AetheraTokens.bodySmall(
                                color: AetheraTokens.moonGlow,
                              ),
                            ),
                            Text(
                              '+${challenge.pointsReward} points',
                              style: AetheraTokens.labelSmall(
                                color: AetheraTokens.goldenDawn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Completion status
                        if (!challenge.isCompleted)
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: LiquidButton(
                              label: 'Complete Challenge',
                              onPressed: () {
                                ref.read(
                                  completeChallengeProvider(challenge.id),
                                );
                              },
                              gradientStart: categoryColor,
                              gradientEnd: AetheraTokens.nebulaPurple,
                              height: 40,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AetheraTokens.auroraTeal,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Challenge Completed!',
                                style: AetheraTokens.labelLarge(
                                  color: AetheraTokens.auroraTeal,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Past Challenges
              Text(
                'Challenge History',
                style: AetheraTokens.displayMedium(),
              ),
              const SizedBox(height: 24),

              allChallenges.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(
                  child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
                ),
                data: (challenges) {
                  if (challenges.isEmpty) {
                    return Center(
                      child: Text(
                        'No challenges yet',
                        style: AetheraTokens.bodyMedium(
                          color: AetheraTokens.moonGlow,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      final categoryColor = _categoryColor(challenge.category);

                      return NeonBorderCard(
                        neonColor: categoryColor,
                        backgroundColor: AetheraTokens.voidBlue.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                        onTap: () {},
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.title,
                                    style: AetheraTokens.labelLarge(
                                      color: categoryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    challenge.category,
                                    style: AetheraTokens.bodySmall(
                                      color: AetheraTokens.moonGlow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (challenge.isCompleted)
                              Icon(
                                Icons.check_circle,
                                color: categoryColor,
                                size: 24,
                              )
                            else
                              Text(
                                '${challenge.pointsReward}pts',
                                style: AetheraTokens.labelSmall(
                                  color: AetheraTokens.goldenDawn,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
