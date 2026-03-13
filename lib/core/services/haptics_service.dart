import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class HapticsService {
  static bool get _isSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  static Future<void> selection() async {
    if (!_isSupported) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> light() async {
    if (!_isSupported) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!_isSupported) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> success() async {
    if (!_isSupported) return;
    await HapticFeedback.heavyImpact();
  }
}
