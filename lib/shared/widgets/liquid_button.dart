import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Premium animated button with liquid morphing effect.
/// Creates a smooth, organic feel with gradient and ripple animations.
class LiquidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color gradientStart;
  final Color gradientEnd;
  final double width;
  final double height;
  final IconData? icon;
  final bool isLoading;

  const LiquidButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradientStart = AetheraTokens.auroraTeal,
    this.gradientEnd = AetheraTokens.roseQuartz,
    this.width = double.infinity,
    this.height = 56,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onPress() {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _rippleController.forward().then((_) {
        setState(() => _isPressed = false);
      });
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onPress,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, _) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              children: [
                // Animated ripple effect
                if (_rippleController.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: (1 - _rippleController.value) * 0.15,
                        ),
                      ),
                      transform: Matrix4.identity()
                        ..scale(1 + (_rippleController.value * 0.5)),
                    ),
                  ),
                // Main button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
                    gradient: LinearGradient(
                      colors: [widget.gradientStart, widget.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientStart.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onPress,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
                      child: Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(widget.icon, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    widget.label,
                                    style: AetheraTokens.labelLarge(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
