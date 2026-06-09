import 'package:flutter/material.dart';

/// Premium gradient text widget for eye-catching typography.
/// Supports custom gradients and text styles.
class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return gradient.createShader(bounds);
      },
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: (textStyle ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
