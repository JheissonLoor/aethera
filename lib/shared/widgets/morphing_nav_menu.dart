import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Item for the morphing navigation menu
class NavMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  NavMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
}

/// Premium morphing bottom navigation menu with floating action capabilities.
class MorphingNavMenu extends StatefulWidget {
  final List<NavMenuItem> items;
  final VoidCallback? onCenterTap;

  const MorphingNavMenu({
    super.key,
    required this.items,
    this.onCenterTap,
  });

  @override
  State<MorphingNavMenu> createState() => _MorphingNavMenuState();
}

class _MorphingNavMenuState extends State<MorphingNavMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_isExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expanded menu items
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.items.map((item) {
                      final isSelected = item.selected;
                      return GestureDetector(
                        onTap: () {
                          item.onTap();
                          _toggleExpand();
                        },
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.0, end: 1.0)
                              .animate(_animationController),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        AetheraTokens.auroraTeal,
                                        AetheraTokens.nebulaPurple,
                                      ],
                                    )
                                  : null,
                              color: !isSelected
                                  ? AetheraTokens.voidBlue.withValues(alpha: 0.8)
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? AetheraTokens.auroraTeal
                                    : Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AetheraTokens.auroraTeal
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? Colors.white
                                  : AetheraTokens.moonGlow,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Bottom bar with center button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AetheraTokens.deepSpace.withValues(alpha: 0.9),
                      AetheraTokens.cosmicNight.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Left items (first half)
                    ...widget.items.take((widget.items.length / 2).floor()).map(
                      (item) {
                        final isSelected = item.selected;
                        return GestureDetector(
                          onTap: () {
                            item.onTap();
                            if (_isExpanded) _toggleExpand();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AetheraTokens.nebulaPurple.withValues(
                                      alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AetheraTokens.nebulaPurple
                                        .withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? AetheraTokens.nebulaPurple
                                  : AetheraTokens.moonGlow,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),

                    // Center expand button
                    GestureDetector(
                      onTap: _toggleExpand,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 0.9)
                            .animate(_animationController),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AetheraTokens.auroraTeal,
                                AetheraTokens.nebulaPurple,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AetheraTokens.auroraTeal
                                    .withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isExpanded ? Icons.close : Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Right items (second half)
                    ...widget.items
                        .skip((widget.items.length / 2).floor())
                        .map(
                      (item) {
                        final isSelected = item.selected;
                        return GestureDetector(
                          onTap: () {
                            item.onTap();
                            if (_isExpanded) _toggleExpand();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AetheraTokens.roseQuartz.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AetheraTokens.roseQuartz
                                        .withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? AetheraTokens.roseQuartz
                                  : AetheraTokens.moonGlow,
                              size: 22,
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
        );
      },
    );
  }
}
