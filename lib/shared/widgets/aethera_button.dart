import 'package:flutter/material.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';

enum AetheraButtonVariant { filled, outlined, ghost }

class AetheraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AetheraButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AetheraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AetheraButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: switch (variant) {
        AetheraButtonVariant.filled => _FilledButton(
            label: label,
            onPressed: isLoading ? null : onPressed,
            icon: icon,
            isLoading: isLoading,
          ),
        AetheraButtonVariant.outlined => _OutlinedButton(
            label: label,
            onPressed: isLoading ? null : onPressed,
            icon: icon,
            isLoading: isLoading,
          ),
        AetheraButtonVariant.ghost => _GhostButton(
            label: label,
            onPressed: isLoading ? null : onPressed,
            icon: icon,
          ),
      },
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const _FilledButton({
    required this.label,
    this.onPressed,
    this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AetheraTokens.auroraGradient,
        borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
        boxShadow: AetheraTokens.auroraGlow(intensity: 0.6),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AetheraTokens.deepSpace,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AetheraTokens.deepSpace),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label.toUpperCase(),
                    style: AetheraTokens.labelLarge(color: AetheraTokens.deepSpace),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const _OutlinedButton({
    required this.label,
    this.onPressed,
    this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AetheraTokens.auroraTeal, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
        ),
        foregroundColor: AetheraTokens.auroraTeal,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AetheraTokens.auroraTeal,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: AetheraTokens.labelLarge(color: AetheraTokens.auroraTeal),
                ),
              ],
            ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _GhostButton({
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AetheraTokens.moonGlow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetheraTokens.radiusMd),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(label, style: AetheraTokens.bodyMedium()),
        ],
      ),
    );
  }
}
