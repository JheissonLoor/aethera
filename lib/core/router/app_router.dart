import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aethera/features/splash/splash_screen.dart';
import 'package:aethera/features/auth/screens/auth_screen.dart';
import 'package:aethera/features/pairing/screens/pairing_screen.dart';
import 'package:aethera/features/universe/screens/universe_screen.dart';
import 'package:aethera/features/ritual/screens/ritual_screen.dart';
import 'package:aethera/features/onboarding/onboarding_screen.dart';
import 'package:aethera/features/profile/profile_screen.dart';
import 'package:aethera/core/providers/app_state_notifier.dart';

abstract class AetheraRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String pairing = '/pairing';
  static const String universe = '/universe';
  static const String ritual = '/ritual';
  static const String profile = '/profile';
}

final appRouter = GoRouter(
  initialLocation: AetheraRoutes.splash,
  debugLogDiagnostics: false,
  refreshListenable: appStateNotifier,
  redirect: _redirect,
  routes: [
    GoRoute(
      path: AetheraRoutes.splash,
      name: 'splash',
      pageBuilder: (context, state) =>
          _fadeTransition(state: state, child: const SplashScreen()),
    ),
    GoRoute(
      path: AetheraRoutes.auth,
      name: 'auth',
      pageBuilder: (context, state) =>
          _fadeTransition(state: state, child: const AuthScreen()),
    ),
    GoRoute(
      path: AetheraRoutes.pairing,
      name: 'pairing',
      pageBuilder: (context, state) =>
          _fadeTransition(state: state, child: const PairingScreen()),
    ),
    GoRoute(
      path: AetheraRoutes.universe,
      name: 'universe',
      pageBuilder: (context, state) =>
          _fadeTransition(state: state, child: const UniverseScreen()),
    ),
    GoRoute(
      path: AetheraRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) =>
          _fadeTransition(state: state, child: const OnboardingScreen()),
    ),
    GoRoute(
      path: AetheraRoutes.profile,
      name: 'profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfileScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: AetheraRoutes.ritual,
      name: 'ritual',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RitualScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      ),
    ),
  ],
);

String? _redirect(BuildContext context, GoRouterState state) {
  // Wait until Firebase has resolved the initial auth state
  if (appStateNotifier.isLoading) return null;

  // Splash manages its own navigation — never intercept it
  if (state.matchedLocation == AetheraRoutes.splash) return null;

  final isAuth = appStateNotifier.isAuthenticated;
  final hasPair = appStateNotifier.hasCoupleId;
  final onboardingDone = appStateNotifier.onboardingDone;
  final loc = state.matchedLocation;

  // First-time users → onboarding
  if (!onboardingDone) {
    return loc == AetheraRoutes.onboarding ? null : AetheraRoutes.onboarding;
  }

  // Not logged in → always go to auth
  if (!isAuth) {
    return loc == AetheraRoutes.auth ? null : AetheraRoutes.auth;
  }

  // Logged in but not paired → go to pairing
  if (!hasPair) {
    return loc == AetheraRoutes.pairing ? null : AetheraRoutes.pairing;
  }

  // Logged in + paired → always universe
  if (loc == AetheraRoutes.auth || loc == AetheraRoutes.pairing) {
    return AetheraRoutes.universe;
  }

  return null;
}

CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 800),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
