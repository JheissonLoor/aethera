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
import 'package:aethera/core/services/telemetry_service.dart';
import 'package:aethera/core/theme/aethera_motion.dart';

abstract class AetheraRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String pairing = '/pairing';
  static const String universe = '/universe';
  static const String ritual = '/ritual';
  static const String profile = '/profile';
}

final GoRouter appRouter = createAppRouter();

GoRouter createAppRouter({
  AppStateNotifier? stateNotifier,
  String initialLocation = AetheraRoutes.splash,
  bool includeTelemetryObserver = true,
  WidgetBuilder? splashBuilder,
  WidgetBuilder? authBuilder,
  WidgetBuilder? pairingBuilder,
  WidgetBuilder? universeBuilder,
  WidgetBuilder? onboardingBuilder,
  WidgetBuilder? profileBuilder,
  WidgetBuilder? ritualBuilder,
}) {
  final notifier = stateNotifier ?? appStateNotifier;
  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) => _redirect(notifier, state),
    observers: [if (includeTelemetryObserver) TelemetryNavigationObserver()],
    routes: [
      GoRoute(
        path: AetheraRoutes.splash,
        name: 'splash',
        pageBuilder:
            (context, state) => _fadeTransition(
              state: state,
              routeName: 'splash',
              child: splashBuilder?.call(context) ?? const SplashScreen(),
            ),
      ),
      GoRoute(
        path: AetheraRoutes.auth,
        name: 'auth',
        pageBuilder:
            (context, state) => _cinematicTransition(
              state: state,
              routeName: 'auth',
              beginOffset: const Offset(0, 0.04),
              beginScale: 0.987,
              child: authBuilder?.call(context) ?? const AuthScreen(),
            ),
      ),
      GoRoute(
        path: AetheraRoutes.pairing,
        name: 'pairing',
        pageBuilder:
            (context, state) => _cinematicTransition(
              state: state,
              routeName: 'pairing',
              beginOffset: const Offset(0, 0.04),
              beginScale: 0.987,
              child: pairingBuilder?.call(context) ?? const PairingScreen(),
            ),
      ),
      GoRoute(
        path: AetheraRoutes.universe,
        name: 'universe',
        pageBuilder:
            (context, state) => _cinematicTransition(
              state: state,
              routeName: 'universe',
              beginOffset: const Offset(0, 0.028),
              beginScale: 0.992,
              child: universeBuilder?.call(context) ?? const UniverseScreen(),
            ),
      ),
      GoRoute(
        path: AetheraRoutes.onboarding,
        name: 'onboarding',
        pageBuilder:
            (context, state) => _cinematicTransition(
              state: state,
              routeName: 'onboarding',
              beginOffset: const Offset(0, 0.035),
              beginScale: 0.988,
              child:
                  onboardingBuilder?.call(context) ?? const OnboardingScreen(),
            ),
      ),
      GoRoute(
        path: AetheraRoutes.profile,
        name: 'profile',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              name: 'profile',
              child: profileBuilder?.call(context) ?? const ProfileScreen(),
              transitionDuration: AetheraMotion.screen,
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: AetheraMotion.enter,
                  reverseCurve: AetheraMotion.exit,
                );
                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(curved),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            ),
      ),
      GoRoute(
        path: AetheraRoutes.ritual,
        name: 'ritual',
        pageBuilder:
            (context, state) => _cinematicTransition(
              state: state,
              routeName: 'ritual',
              beginOffset: const Offset(0.03, 0),
              beginScale: 0.986,
              duration: AetheraMotion.screenSlow,
              child: ritualBuilder?.call(context) ?? const RitualScreen(),
            ),
      ),
    ],
  );
}

String? _redirect(AppStateNotifier stateNotifier, GoRouterState state) {
  return resolveAppRedirect(
    stateNotifier: stateNotifier,
    matchedLocation: state.matchedLocation,
  );
}

String? resolveAppRedirect({
  required AppStateNotifier stateNotifier,
  required String matchedLocation,
}) {
  // Espera hasta resolver estado inicial de autenticacion.
  if (stateNotifier.isLoading) return null;

  // Splash gestiona su propia navegacion.
  if (matchedLocation == AetheraRoutes.splash) return null;

  final isAuth = stateNotifier.isAuthenticated;
  final hasPair = stateNotifier.hasCoupleId;
  final onboardingDone = stateNotifier.onboardingDone;
  final loc = matchedLocation;

  if (!onboardingDone) {
    return loc == AetheraRoutes.onboarding ? null : AetheraRoutes.onboarding;
  }

  if (!isAuth) {
    return loc == AetheraRoutes.auth ? null : AetheraRoutes.auth;
  }

  if (!hasPair) {
    return loc == AetheraRoutes.pairing ? null : AetheraRoutes.pairing;
  }

  if (loc == AetheraRoutes.auth || loc == AetheraRoutes.pairing) {
    return AetheraRoutes.universe;
  }

  return null;
}

CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required String routeName,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: routeName,
    child: child,
    transitionDuration: AetheraMotion.screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AetheraMotion.fade),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _cinematicTransition({
  required GoRouterState state,
  required String routeName,
  required Widget child,
  Offset beginOffset = const Offset(0, 0.03),
  double beginScale = 0.99,
  Duration? duration,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: routeName,
    child: child,
    transitionDuration: duration ?? AetheraMotion.screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AetheraMotion.enter,
        reverseCurve: AetheraMotion.exit,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: beginScale, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
