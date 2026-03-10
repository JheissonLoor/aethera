import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/models/goal_model.dart';

/// Renders goal structures on the horizon. Further = less progress.
class GoalHorizon extends StatelessWidget {
  final List<GoalModel> goals;
  final void Function(GoalModel)? onGoalTap;

  const GoalHorizon({super.key, required this.goals, this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: goals.asMap().entries.map((entry) {
            final i = entry.key;
            final goal = entry.value;
            // Distribute goals evenly across width
            final xFraction = (i + 1) / (goals.length + 1);
            // Scale: completed goals appear larger/closer
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
    final color = goal.isCompleted
        ? AetheraTokens.goldenDawn
        : AetheraTokens.starlight.withValues(alpha: 0.3 + goal.progress * 0.5);

    final icon = _iconForSymbol(goal.symbol);

    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 28,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          if (goal.progress > 0.1)
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, color, Colors.transparent],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _iconForSymbol(String symbol) {
    switch (symbol) {
      case 'lighthouse':
        return '🏮';
      case 'bridge':
        return '🌉';
      case 'island':
        return '🏝️';
      case 'mountain':
        return '⛰️';
      case 'castle':
        return '🏰';
      default:
        return '🏛️';
    }
  }
}
