import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aethera/core/services/crashlytics_service.dart';

typedef NonFatalRecorder =
    Future<void> Function(
      Object error,
      StackTrace stackTrace, {
      String? reason,
    });

abstract class TelemetrySink {
  Future<void> initialize();
  Future<void> setEnabled(bool enabled);
  Future<void> logEvent(String name, {Map<String, Object> parameters});
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
}

class FirebaseTelemetrySink implements TelemetrySink {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object> parameters = const {},
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}

class AppTelemetryService {
  AppTelemetryService({TelemetrySink? sink, NonFatalRecorder? nonFatalRecorder})
    : _sink = sink ?? FirebaseTelemetrySink(),
      _nonFatalRecorder =
          nonFatalRecorder ?? CrashlyticsService.instance.recordNonFatal;

  static final AppTelemetryService instance = AppTelemetryService();

  final TelemetrySink _sink;
  final NonFatalRecorder _nonFatalRecorder;

  bool _initialized = false;
  bool _enabled = false;

  bool get isReady => _initialized && _enabled;

  Future<void> initialize({bool enabled = true}) async {
    if (_initialized) return;
    _enabled = enabled;
    if (!_enabled || kIsWeb) return;

    try {
      await _sink.setEnabled(enabled);
      await _sink.initialize();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> setUserContext({
    required String userId,
    String? coupleId,
  }) async {
    if (!isReady) return;
    try {
      await _sink.setUserId(userId);
      await _sink.setUserProperty(
        'has_couple',
        (coupleId?.isNotEmpty == true) ? '1' : '0',
      );
      if (coupleId != null && coupleId.isNotEmpty) {
        await _sink.setUserProperty(
          'couple_id_prefix',
          coupleId.substring(0, math.min(8, coupleId.length)),
        );
      }
    } catch (_) {}
  }

  Future<void> trackScreen(String screenName) async {
    await logEvent(
      'screen_view_custom',
      parameters: {'screen_name': screenName},
    );
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    if (!isReady) return;

    final normalizedName = _normalizeKey(name, fallback: 'app_event');
    final normalizedParams = <String, Object>{};
    for (final entry in parameters.entries) {
      final normalizedKey = _normalizeKey(entry.key, fallback: 'param');
      final normalizedValue = _normalizeValue(entry.value);
      if (normalizedValue != null) {
        normalizedParams[normalizedKey] = normalizedValue;
      }
    }

    try {
      await _sink.logEvent(normalizedName, parameters: normalizedParams);
    } catch (_) {}
  }

  Future<void> recordNonFatal({
    required String reason,
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    await _nonFatalRecorder(error, stackTrace, reason: reason);

    final params = <String, Object?>{
      'reason': reason,
      'error_type': error.runtimeType.toString(),
      ...context,
    };
    await logEvent('non_fatal_error', parameters: params);
  }

  String _normalizeKey(String raw, {required String fallback}) {
    final collapsed = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final base = collapsed.isEmpty ? fallback : collapsed;
    final prefixed = RegExp(r'^[a-z]').hasMatch(base) ? base : 'e_$base';
    return prefixed.substring(0, math.min(40, prefixed.length));
  }

  Object? _normalizeValue(Object? value) {
    if (value == null) return null;
    if (value is int || value is double) return value;
    if (value is bool) return value ? 1 : 0;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text.substring(0, math.min(100, text.length));
  }
}

class TelemetryNavigationObserver extends NavigatorObserver {
  String? _lastScreen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _track(previousRoute);
  }

  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty || name == _lastScreen) return;
    _lastScreen = name;
    unawaited(AppTelemetryService.instance.trackScreen(name));
  }
}
