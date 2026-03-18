import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/aethera_glass_panel.dart';

/// Skeleton de carga para paneles superiores del universo.
class UniverseTopPanelsSkeleton extends StatelessWidget {
  final bool compact;

  const UniverseTopPanelsSkeleton({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando paneles del universo',
      child: Column(
        children: [
          _SkeletonPanel(
            compact: compact,
            iconColor: AetheraTokens.auroraTeal,
            borderColor: AetheraTokens.auroraTeal.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 8),
          _SkeletonPanel(
            compact: compact,
            iconColor: AetheraTokens.goldenDawn,
            borderColor: AetheraTokens.goldenDawn.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de carga para la zona de acciones inferiores.
class UniverseBottomActionsSkeleton extends StatelessWidget {
  final bool compact;

  const UniverseBottomActionsSkeleton({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    final buttonHeight = compact ? 52.0 : 56.0;
    return Row(
      children: [
        Expanded(
          child: UniverseSkeletonBlock(height: buttonHeight, radius: 15),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: UniverseSkeletonBlock(height: buttonHeight, radius: 15),
        ),
        const SizedBox(width: 8),
        UniverseSkeletonBlock(
          width: compact ? 62 : 70,
          height: compact ? 58 : 64,
          radius: 999,
          color: AetheraTokens.auroraTeal.withValues(alpha: 0.26),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: UniverseSkeletonBlock(height: buttonHeight, radius: 15),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: UniverseSkeletonBlock(height: buttonHeight, radius: 15),
        ),
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  final bool compact;
  final Color iconColor;
  final Color borderColor;

  const _SkeletonPanel({
    required this.compact,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AetheraGlassPanel(
      borderRadius: 20,
      backgroundColor: const Color(0x220B1326),
      borderColor: borderColor,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UniverseSkeletonBlock(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                radius: 999,
                color: iconColor.withValues(alpha: 0.32),
              ),
              const SizedBox(width: 8),
              UniverseSkeletonBlock(
                width: compact ? 120 : 150,
                height: 12,
                radius: 99,
              ),
              const Spacer(),
              UniverseSkeletonBlock(
                width: compact ? 54 : 64,
                height: 16,
                radius: 99,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          UniverseSkeletonBlock(
            width: double.infinity,
            height: compact ? 11 : 13,
            radius: 99,
          ),
          const SizedBox(height: 8),
          UniverseSkeletonBlock(
            width: compact ? 160 : 210,
            height: compact ? 11 : 13,
            radius: 99,
          ),
          SizedBox(height: compact ? 10 : 12),
          UniverseSkeletonBlock(
            width: double.infinity,
            height: compact ? 34 : 38,
            radius: 12,
            color: iconColor.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

/// Bloque base de skeleton con pulso suave.
class UniverseSkeletonBlock extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final Color? color;

  const UniverseSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    required this.radius,
    this.color,
  });

  @override
  State<UniverseSkeletonBlock> createState() => _UniverseSkeletonBlockState();
}

class _UniverseSkeletonBlockState extends State<UniverseSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? Colors.white.withValues(alpha: 0.18);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.38, end: 0.72).animate(_opacity),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: base,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
      ),
    );
  }
}
