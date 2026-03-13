import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aethera/core/services/telemetry_service.dart';

/// ChangeNotifier used as GoRouter's [refreshListenable].
/// Tracks auth state + whether the current user has a coupleId.
class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    _loadOnboarding();
  }

  late final StreamSubscription<User?> _sub;

  User? _user;
  String? _coupleId;
  bool _authLoaded = false;
  bool _onboardingLoaded = false;
  bool _onboardingDone = false;

  User? get currentUser => _user;
  String? get coupleId => _coupleId;
  bool get isLoading => !_authLoaded || !_onboardingLoaded;
  bool get isAuthenticated => _user != null;
  bool get hasCoupleId => _coupleId != null && _coupleId!.isNotEmpty;
  bool get onboardingDone => _onboardingDone;

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool('onboarding_done') ?? false;
    _onboardingLoaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        _coupleId = doc.data()?['coupleId'] as String?;
      } catch (_) {
        _coupleId = null;
      }

      unawaited(
        AppTelemetryService.instance.setUserContext(
          userId: user.uid,
          coupleId: _coupleId,
        ),
      );
      unawaited(
        AppTelemetryService.instance.logEvent(
          'auth_session_active',
          parameters: {'has_couple': _coupleId?.isNotEmpty == true},
        ),
      );
    } else {
      _coupleId = null;
      unawaited(AppTelemetryService.instance.logEvent('auth_session_closed'));
    }
    _authLoaded = true;
    notifyListeners();
  }

  /// Called after pairing so the router redirects immediately.
  void setCoupleId(String coupleId) {
    _coupleId = coupleId;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Singleton — shared by app_router and pairing_provider.
final appStateNotifier = AppStateNotifier();
