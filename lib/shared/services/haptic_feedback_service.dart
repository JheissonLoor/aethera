import 'package:flutter/services.dart';

/// Service for managing haptic feedback throughout the app.
/// Provides different feedback types for various interactions.
class HapticFeedbackService {
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> success() async {
    try {
      // Simulate success with light double tap
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> error() async {
    try {
      // Heavy feedback for errors
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> pulse() async {
    try {
      // Heartbeat-like pulse
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }

  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      print('[v0] Haptic feedback error: $e');
    }
  }
}
