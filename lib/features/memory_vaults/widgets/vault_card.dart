import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/features/memory_vaults/models/memory_vault.dart';

/// Interactive vault card that can be tapped to reveal or lock/unlock.
class VaultCard extends StatefulWidget {
  final MemoryVault vault;
  final VoidCallback? onReveal;
  final VoidCallback? onDelete;

  const VaultCard({
    super.key,
    required this.vault,
    this.onReveal,
    this.onDelete,
  });

  @override
  State<VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<VaultCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (widget.vault.isRevealed) return;
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !widget.vault.isRevealed;
    final lockColor = widget.vault.canReveal
        ? AetheraTokens.auroraTeal
        : AetheraTokens.moonGlow;

    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final isFlipped = _flipAnimation.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * 3.14159),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
                border: Border.all(
                  color: isLocked ? lockColor : AetheraTokens.auroraTeal,
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    isLocked
                        ? AetheraTokens.voidBlue.withValues(alpha: 0.4)
                        : AetheraTokens.auroraTeal.withValues(alpha: 0.1),
                    isLocked
                        ? AetheraTokens.cosmicNight.withValues(alpha: 0.3)
                        : AetheraTokens.nebulaPurple.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isLocked
                    ? [
                        BoxShadow(
                          color: lockColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AetheraTokens.auroraTeal.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(AetheraTokens.spacingLg),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(isFlipped ? 3.14159 : 0),
                child: isFlipped
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.vault.title,
                                      style: AetheraTokens.labelLarge(
                                        color: AetheraTokens.auroraTeal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.vault.revealCondition,
                                      style: AetheraTokens.bodySmall(
                                        color: AetheraTokens.moonGlow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.vault.isRevealed)
                                Icon(
                                  Icons.lock_open,
                                  color: AetheraTokens.auroraTeal,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                widget.vault.content,
                                style: AetheraTokens.bodyMedium(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.vault.isRevealed)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: widget.onDelete,
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AetheraTokens.roseQuartz,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 48,
                            color: lockColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.vault.title,
                            textAlign: TextAlign.center,
                            style: AetheraTokens.labelLarge(
                              color: lockColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.vault.canReveal ? 'Tap to reveal' : 'Locked',
                            style: AetheraTokens.bodySmall(
                              color: AetheraTokens.moonGlow,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
