import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/constants/app_constants.dart';
import 'package:aethera/shared/models/memory_model.dart';

/// Objeto flotante del universo que representa una memoria.
class MemoryObjectWidget extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback? onTap;
  final String? heroTag;

  /// Indice para animacion escalonada.
  final int animationIndex;

  const MemoryObjectWidget({
    super.key,
    required this.memory,
    this.onTap,
    this.heroTag,
    this.animationIndex = 0,
  });

  static String iconForType(String type) {
    return AppConstants.memoryTypeIcons[type] ?? '✦';
  }

  static Color glowColorForType(String type) {
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

  static Widget buildOrb({required String type, double size = 52}) {
    final icon = iconForType(type);
    final glowColor = glowColorForType(type);
    final iconSize = size * 0.46;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            glowColor.withValues(alpha: 0.22),
            glowColor.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: glowColor.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 22,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(child: Text(icon, style: TextStyle(fontSize: iconSize))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Evita que todos floten sincronizados y se vea artificial.
    final floatDuration = Duration(milliseconds: 2200 + animationIndex * 400);
    final floatAmplitude =
        (animationIndex % 3 == 0)
            ? -8.0
            : (animationIndex % 3 == 1)
            ? -5.0
            : -7.0;
    final floatDelay = Duration(milliseconds: animationIndex * 300);

    Widget orb = buildOrb(type: memory.type, size: 52);
    if (heroTag != null) {
      // Material transparente mejora el vuelo de Hero.
      orb = Hero(
        tag: heroTag!,
        child: Material(type: MaterialType.transparency, child: orb),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          orb
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
}
