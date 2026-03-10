import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/shared/models/memory_model.dart';

/// A floating symbolic object in the universe representing a memory.
class MemoryObjectWidget extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback? onTap;

  /// Index for staggered animation — each memory floats at a different rate.
  final int animationIndex;

  const MemoryObjectWidget({
    super.key,
    required this.memory,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppConstants.memoryTypeIcons[memory.type] ?? '✦';
    final glowColor = _glowColorForType(memory.type);

    // Vary float duration and amplitude per object so they don't bob in sync
    final floatDuration = Duration(milliseconds: 2200 + animationIndex * 400);
    final floatAmplitude =
        (animationIndex % 3 == 0)
            ? -8.0
            : (animationIndex % 3 == 1)
            ? -5.0
            : -7.0;
    final floatDelay = Duration(milliseconds: animationIndex * 300);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.22),
                      glowColor.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.4),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: floatAmplitude,
                duration: floatDuration,
                delay: floatDelay,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 4),
          Text(
            memory.title,
            style: AetheraTokens.bodySmall(color: AetheraTokens.moonGlow),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _glowColorForType(String type) {
    switch (type) {
      case 'tree':
        return const Color(0xFF4CAF50);
      case 'lighthouse':
        return AetheraTokens.goldenDawn;
      case 'constellation':
        return AetheraTokens.auroraTeal;
      case 'bridge':
        return AetheraTokens.starlightBlue;
      case 'island':
        return AetheraTokens.roseQuartz;
      case 'relic':
        return AetheraTokens.goldenDawn;
      default:
        return AetheraTokens.moonGlow;
    }
  }
}
