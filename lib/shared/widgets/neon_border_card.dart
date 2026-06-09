import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Premium card with animated neon border effect.
/// Creates a glowing, cyberpunk-inspired look perfect for key interactions.
class NeonBorderCard extends StatefulWidget {
  final Widget child;
  final Color neonColor;
  final double borderWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool glowAnimation;
  final EdgeInsetsGeometry padding;

  const NeonBorderCard({
    super.key,
    required this.child,
    this.neonColor = AetheraTokens.auroraTeal,
    this.borderWidth = 2.0,
    this.borderRadius = AetheraTokens.radiusMd,
    this.backgroundColor,
    this.onTap,
    this.glowAnimation = true,
    this.padding = const EdgeInsets.all(AetheraTokens.spacingMd),
  });

  @override
  State<NeonBorderCard> createState() => _NeonBorderCardState();
}

class _NeonBorderCardState extends State<NeonBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.glowAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.neonColor,
                width: widget.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.neonColor.withValues(alpha: 0.4 * _glowAnimation.value),
                  blurRadius: 16 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
                BoxShadow(
                  color: widget.neonColor.withValues(alpha: 0.15 * _glowAnimation.value),
                  blurRadius: 32 * _glowAnimation.value,
                  spreadRadius: 6 * _glowAnimation.value,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                padding: widget.padding,
                color: widget.backgroundColor ?? AetheraTokens.voidBlue.withValues(alpha: 0.4),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
