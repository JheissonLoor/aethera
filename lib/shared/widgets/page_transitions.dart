import 'package:flutter/material.dart';

/// Custom page transitions for Aethera app.
class AetheraPageTransitions {
  /// Fade and scale transition
  static PageRoute<T> fadeScale<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  /// Slide from bottom transition
  static PageRoute<T> slideUp<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  /// Zoom in from center transition
  static PageRoute<T> zoomIn<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  /// Rotate and fade transition
  static PageRoute<T> rotateFade<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAnimation =
            Tween<double>(begin: 0.5, end: 0.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeIn),
        );

        return Transform.rotate(
          angle: rotationAnimation.value,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }
}
