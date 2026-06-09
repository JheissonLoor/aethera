import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget that reveals text letter by letter with animation.
/// Perfect for dramatic reveals and emotional moments.
class LetterByLetterReveal extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delayPerLetter;
  final Duration letterDuration;
  final bool autoStart;
  final VoidCallback? onComplete;

  const LetterByLetterReveal({
    super.key,
    required this.text,
    required this.style,
    this.delayPerLetter = const Duration(milliseconds: 50),
    this.letterDuration = const Duration(milliseconds: 300),
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<LetterByLetterReveal> createState() => _LetterByLetterRevealState();
}

class _LetterByLetterRevealState extends State<LetterByLetterReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.text.length,
      (index) => AnimationController(
        duration: widget.letterDuration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.delayPerLetter * i,
        () {
          if (mounted) {
            _controllers[i].forward();
            if (i == _controllers.length - 1) {
              setState(() => _isComplete = true);
              widget.onComplete?.call();
            }
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          for (int i = 0; i < widget.text.length; i++)
            WidgetSpan(
              child: AnimatedBuilder(
                animation: _animations[i],
                builder: (context, _) {
                  return Opacity(
                    opacity: _animations[i].value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * _animations[i].value),
                      child: Text(
                        widget.text[i],
                        style: widget.style,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
