import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Premium morphing card with glassmorphism and color shift effect.
/// Creates an immersive card experience with smooth state transitions.
class MorphCard extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;

  const MorphCard({
    super.key,
    required this.child,
    this.primaryColor = AetheraTokens.auroraTeal,
    this.secondaryColor = AetheraTokens.nebulaPurple,
    this.width = double.infinity,
    this.height = 200,
    this.padding = const EdgeInsets.all(AetheraTokens.spacingLg),
    this.borderRadius = AetheraTokens.radiusLg,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<MorphCard> createState() => _MorphCardState();
}

class _MorphCardState extends State<MorphCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    if (widget.enableHover) {
      setState(() => _isHovered = true);
      _hoverController.forward();
    }
  }

  void _onHoverExit() {
    if (widget.enableHover) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, _) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                children: [
                  // Background blur effect
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 15 + (5 * _hoverController.value),
                          sigmaY: 15 + (5 * _hoverController.value),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(
                                  widget.primaryColor.withValues(alpha: 0.1),
                                  widget.primaryColor.withValues(alpha: 0.2),
                                  _hoverController.value,
                                )!,
                                Color.lerp(
                                  widget.secondaryColor.withValues(alpha: 0.08),
                                  widget.secondaryColor.withValues(alpha: 0.15),
                                  _hoverController.value,
                                )!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.25),
                                _hoverController.value,
                              )!,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: widget.padding,
                      child: Transform.scale(
                        scale: 1 + (0.02 * _hoverController.value),
                        child: widget.child,
                      ),
                    ),
                  ),
                  // Glow effect on hover
                  if (_isHovered)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.3 * _hoverController.value,
                                ),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
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
