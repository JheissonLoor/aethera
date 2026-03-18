import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/models/goal_model.dart';

/// Renderiza estructuras de metas en el horizonte.
class GoalHorizon extends StatelessWidget {
  final List<GoalModel> goals;
  final void Function(GoalModel)? onGoalTap;

  const GoalHorizon({super.key, required this.goals, this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          child: Stack(
            children:
                goals.asMap().entries.map((entry) {
                  final i = entry.key;
                  final goal = entry.value;
                  final xFraction = (i + 1) / (goals.length + 1);
                  final scale = 0.4 + goal.progress * 0.6;
                  final yOffset = 20 - goal.progress * 15;

                  return Positioned(
                    left: constraints.maxWidth * xFraction - 20,
                    bottom: yOffset,
                    child: GestureDetector(
                      onTap: onGoalTap != null ? () => onGoalTap!(goal) : null,
                      child: _GoalStructure(goal: goal, scale: scale),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

class _GoalStructure extends StatelessWidget {
  final GoalModel goal;
  final double scale;

  const _GoalStructure({required this.goal, required this.scale});

  @override
  Widget build(BuildContext context) {
    final color =
        goal.isCompleted
            ? AetheraTokens.goldenDawn
            : AetheraTokens.starlight.withValues(
              alpha: 0.3 + goal.progress * 0.5,
            );
    final haloColor =
        goal.isCompleted
            ? AetheraTokens.goldenDawn.withValues(alpha: 0.26)
            : AetheraTokens.auroraTeal.withValues(
              alpha: 0.2 + goal.progress * 0.2,
            );

    final icon = _iconForSymbol(goal.symbol);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: scale * 0.84, end: scale),
        duration: Duration(
          milliseconds: 420 + (goal.id.hashCode.abs() % 5) * 70,
        ),
        curve: Curves.easeOutBack,
        builder:
            (context, animatedScale, _) => Transform.scale(
              scale: animatedScale,
              alignment: Alignment.bottomCenter,
              child: Semantics(
                label:
                    '${goal.title}: ${(goal.progress * 100).round()}% ${goal.isCompleted ? "completada" : "en progreso"}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [haloColor, Colors.transparent],
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: 0.34),
                                width: 0.8 + (goal.progress * 1.2),
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'goal_${goal.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Icon(
                                icon,
                                size: 28,
                                color: color,
                                shadows: [
                                  Shadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (goal.isCompleted)
                            Positioned(
                              top: 2,
                              right: 4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AetheraTokens.goldenDawn,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 8,
                                  color: AetheraTokens.deepSpace,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (goal.progress > 0.05)
                      Container(
                        width: 24 + goal.progress * 18,
                        height: 2.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              color,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  IconData _iconForSymbol(String symbol) {
    switch (symbol) {
      case 'lighthouse':
        return Icons.light_rounded;
      case 'bridge':
        return Icons.architecture_rounded;
      case 'island':
        return Icons.landscape_rounded;
      case 'mountain':
        return Icons.terrain_rounded;
      case 'castle':
        return Icons.castle_rounded;
      default:
        return Icons.flag_rounded;
    }
  }
}
