import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Reusable glassmorphism container — the core visual building block of Aethera.
class AetheraGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const AetheraGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AetheraTokens.radiusLg,
    this.blurAmount = AetheraTokens.glassBlur,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
    this.onTap,
  });

  /// Creates a panel with a stronger glass effect (slightly more opaque).
  const AetheraGlassPanel.strong({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = AetheraTokens.radiusLg,
    this.blurAmount = AetheraTokens.glassBlur,
    Color? backgroundColor,
    Color? borderColor,
    this.shadows,
    this.onTap,
  })  : backgroundColor = backgroundColor ?? const Color(0x1FFFFFFF),
        borderColor = borderColor ?? const Color(0x33FFFFFF);

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AetheraTokens.spacingMd),
          decoration: BoxDecoration(
            color: backgroundColor ?? AetheraTokens.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AetheraTokens.glassBorder,
              width: AetheraTokens.glassBorderWidth,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: onTap != null ? GestureDetector(onTap: onTap, child: content) : content,
      );
    }
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}
