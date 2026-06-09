import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/shared/widgets/index.dart';

/// Live status card showing real-time connection status and activity.
class LiveStatusCard extends StatefulWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String? subtitle;
  final IconData icon;
  final bool isLive;
  final VoidCallback? onTap;

  const LiveStatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    this.subtitle,
    required this.icon,
    this.isLive = false,
    this.onTap,
  });

  @override
  State<LiveStatusCard> createState() => _LiveStatusCardState();
}

class _LiveStatusCardState extends State<LiveStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    if (widget.isLive) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MorphCard(
        primaryColor: widget.statusColor,
        secondaryColor: AetheraTokens.nebulaPurple,
        height: 120,
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: AetheraTokens.labelSmall(
                        color: widget.statusColor,
                      ),
                    ),
                  ],
                ),
                if (widget.isLive)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: widget.statusColor.withValues(
                                alpha: 0.5 * (1 - _pulseController.value),
                              ),
                              blurRadius: 8 * (1 - _pulseController.value),
                              spreadRadius: 2 * (1 - _pulseController.value),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),

            // Status text
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.status,
                style: AetheraTokens.displaySmall(
                  color: widget.statusColor,
                ),
              ),
            ),

            // Subtitle if provided
            if (widget.subtitle != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.subtitle!,
                  style: AetheraTokens.bodySmall(
                    color: AetheraTokens.moonGlow,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
