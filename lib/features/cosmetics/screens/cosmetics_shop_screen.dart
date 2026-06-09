import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';
import 'package:aethera/features/cosmetics/providers/cosmetics_provider.dart';

class CosmeticsShopScreen extends ConsumerWidget {
  const CosmeticsShopScreen({super.key});

  Color _categoryColor(String category) {
    switch (category) {
      case 'universe_theme':
        return AetheraTokens.nebulaPurple;
      case 'particle':
        return AetheraTokens.goldenDawn;
      case 'button_style':
        return AetheraTokens.auroraTeal;
      case 'glow':
        return AetheraTokens.roseQuartz;
      default:
        return AetheraTokens.moonGlow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cosmetics = ref.watch(allCosmeticsProvider);
    final userCosmetics = ref.watch(userCosmeticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmetics Shop'),
        centerTitle: true,
        backgroundColor: AetheraTokens.deepSpace,
        elevation: 0,
        actions: [
          // Points counter
          userCosmetics.when(
            data: (profile) => profile != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: AetheraTokens.goldenDawn,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${profile.totalPoints}',
                            style: AetheraTokens.labelLarge(
                              color: AetheraTokens.goldenDawn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
          ),
        ],
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
        child: cosmetics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text('Error: $err', style: AetheraTokens.bodyMedium()),
          ),
          data: (cosmeticList) {
            if (cosmeticList.isEmpty) {
              return Center(
                child: Text(
                  'No cosmetics available',
                  style: AetheraTokens.bodyMedium(),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AetheraTokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Your Style',
                    style: AetheraTokens.displayMedium(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete challenges and rituals to unlock cosmetics',
                    style: AetheraTokens.bodyMedium(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Grid of cosmetics
                  userCosmetics.when(
                    data: (profile) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: cosmeticList.length,
                      itemBuilder: (context, index) {
                        final cosmetic = cosmeticList[index];
                        final isUnlocked = profile?.unlockedCosmeticIds
                                .contains(cosmetic.id) ??
                            false;
                        final isEquipped = profile?.equippedCosmetics
                                .containsValue(cosmetic.id) ??
                            false;
                        final categoryColor = _categoryColor(cosmetic.category);

                        return GestureDetector(
                          onTap: isUnlocked
                              ? () {
                                  ref.read(
                                    equipCosmeticProvider(
                                      (
                                        cosmeticId: cosmetic.id,
                                        category: cosmetic.category,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: NeonBorderCard(
                            neonColor: isUnlocked
                                ? categoryColor
                                : AetheraTokens.dusk,
                            backgroundColor: AetheraTokens.voidBlue
                                .withValues(alpha: isUnlocked ? 0.5 : 0.2),
                            glowAnimation: isUnlocked,
                            onTap: isUnlocked
                                ? () {
                                    ref.read(
                                      equipCosmeticProvider(
                                        (
                                          cosmeticId: cosmetic.id,
                                          category: cosmetic.category,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Icon area
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isUnlocked
                                        ? RadialGradient(
                                            colors: [
                                              categoryColor
                                                  .withValues(alpha: 0.4),
                                              categoryColor
                                                  .withValues(alpha: 0.1),
                                            ],
                                          )
                                        : RadialGradient(
                                            colors: [
                                              AetheraTokens.dusk
                                                  .withValues(alpha: 0.2),
                                              AetheraTokens.dusk
                                                  .withValues(alpha: 0.05),
                                            ],
                                          ),
                                  ),
                                  child: isUnlocked
                                      ? Icon(
                                          Icons.check_circle,
                                          color: categoryColor,
                                          size: 32,
                                        )
                                      : Icon(
                                          Icons.lock,
                                          color: AetheraTokens.dusk,
                                          size: 28,
                                        ),
                                ),
                                // Name
                                Text(
                                  cosmetic.name,
                                  textAlign: TextAlign.center,
                                  style: AetheraTokens.labelSmall(
                                    color: isUnlocked
                                        ? categoryColor
                                        : AetheraTokens.dusk,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Status
                                if (isEquipped)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AetheraTokens.radiusSm,
                                      ),
                                      color: categoryColor.withValues(alpha: 0.25),
                                    ),
                                    child: Text(
                                      'Equipped',
                                      style: AetheraTokens.bodySmall(
                                        color: categoryColor,
                                      ),
                                    ),
                                  )
                                else if (!isUnlocked)
                                  Text(
                                    cosmetic.unlockCondition,
                                    textAlign: TextAlign.center,
                                    style: AetheraTokens.bodySmall(
                                      color: AetheraTokens.dusk,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(
                      child: Text('Error: $err',
                          style: AetheraTokens.bodyMedium()),
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
