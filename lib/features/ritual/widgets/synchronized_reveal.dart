import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';

/// Widget that reveals partner's answer with synchronized animation.
/// Creates a dramatic reveal experience for shared ritual moments.
class SynchronizedReveal extends StatefulWidget {
  final String question;
  final String partnerAnswer;
  final String yourAnswer;
  final VoidCallback? onRevealed;

  const SynchronizedReveal({
    super.key,
    required this.question,
    required this.partnerAnswer,
    required this.yourAnswer,
    this.onRevealed,
  });

  @override
  State<SynchronizedReveal> createState() => _SynchronizedRevealState();
}

class _SynchronizedRevealState extends State<SynchronizedReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late Animation<double> _flipAnimation;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _revealAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOutBack),
    );

    _flipAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _reveal() {
    if (!_isRevealed) {
      _revealController.forward();
      setState(() => _isRevealed = true);
      widget.onRevealed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Question
        Text(
          widget.question,
          textAlign: TextAlign.center,
          style: AetheraTokens.displaySmall(),
        ),
        const SizedBox(height: 32),

        // Answers in sync
        Row(
          children: [
            // Your Answer
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Your Answer',
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeonBorderCard(
                    neonColor: AetheraTokens.nebulaPurple,
                    backgroundColor: AetheraTokens.voidBlue.withValues(alpha: 0.5),
                    padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                    child: Text(
                      widget.yourAnswer,
                      textAlign: TextAlign.center,
                      style: AetheraTokens.bodyLarge(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Partner's Answer (Revealed with animation)
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Their Answer',
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _revealAnimation,
                    builder: (context, _) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnimation.value * 3.14159),
                        child: NeonBorderCard(
                          neonColor: _isRevealed
                              ? AetheraTokens.roseQuartz
                              : AetheraTokens.auroraTeal,
                          backgroundColor: AetheraTokens.voidBlue.withValues(
                            alpha: 0.5 + (0.2 * _revealAnimation.value),
                          ),
                          glowAnimation: !_isRevealed,
                          padding: const EdgeInsets.all(AetheraTokens.spacingMd),
                          child: _isRevealed
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(3.14159),
                                  child: Text(
                                    widget.partnerAnswer,
                                    textAlign: TextAlign.center,
                                    style: AetheraTokens.bodyLarge(
                                      color: AetheraTokens.roseQuartz,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: AetheraTokens.auroraTeal,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Locked',
                                      style: AetheraTokens.labelSmall(
                                        color: AetheraTokens.auroraTeal,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Reveal button
        if (!_isRevealed)
          SizedBox(
            width: double.infinity,
            child: LiquidButton(
              label: 'Reveal Their Answer',
              onPressed: _reveal,
              gradientStart: AetheraTokens.roseQuartz,
              gradientEnd: AetheraTokens.auroraTeal,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
              color: AetheraTokens.roseQuartz.withValues(alpha: 0.15),
              border: Border.all(
                color: AetheraTokens.roseQuartz.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AetheraTokens.roseQuartz,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Revealed!',
                  style: AetheraTokens.labelLarge(
                    color: AetheraTokens.roseQuartz,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
