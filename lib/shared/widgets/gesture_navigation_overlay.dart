import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

/// Gesture-based navigation indicator showing swipe directions.
class GestureNavigationOverlay extends StatefulWidget {
  final Widget child;

  const GestureNavigationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<GestureNavigationOverlay> createState() =>
      _GestureNavigationOverlayState();
}

class _GestureNavigationOverlayState extends State<GestureNavigationOverlay> {
  Offset? _dragStart;
  bool _showHint = false;

  void _handleDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;

    final delta = details.globalPosition - _dragStart!;
    if (delta.distance > 20) {
      setState(() => _showHint = true);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _dragStart = null;
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          widget.child,
          if (_showHint)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AetheraTokens.radiusSm),
                    color: AetheraTokens.deepSpace.withValues(alpha: 0.9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Swipe to navigate',
                    style: AetheraTokens.bodySmall(
                      color: AetheraTokens.moonGlow,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
