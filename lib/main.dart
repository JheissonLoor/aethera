import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/services/crashlytics_service.dart';
import 'package:aethera/core/services/music_service.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/l10n/gen/app_localizations.dart';

import 'firebase_options.dart';

const Duration _startupTimeout = Duration(seconds: 12);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureSystemChrome();
  runApp(const _BootstrapGateApp());
}

Future<void> _configureSystemChrome() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AetheraTokens.deepSpace,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class _BootstrapGateApp extends StatefulWidget {
  const _BootstrapGateApp();

  @override
  State<_BootstrapGateApp> createState() => _BootstrapGateAppState();
}

class _BootstrapGateAppState extends State<_BootstrapGateApp> {
  bool _isReady = false;
  bool _isLoading = true;
  bool _didTimeout = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _didTimeout = false;
    });

    var timedOut = false;
    final firebaseOk = await _initializeFirebase().timeout(
      _startupTimeout,
      onTimeout: () {
        timedOut = true;
        return false;
      },
    );

    if (!mounted) return;

    if (!firebaseOk) {
      setState(() {
        _isReady = false;
        _isLoading = false;
        _didTimeout = timedOut;
      });
      return;
    }

    try {
      await CrashlyticsService.instance.initialize();
    } catch (_) {
      // Non-fatal: app keeps running if Crashlytics wiring fails.
    }

    unawaited(_initializeOptionalServices());

    if (!mounted) return;
    setState(() {
      _isReady = true;
      _isLoading = false;
      _didTimeout = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const ProviderScope(child: AetheraApp());
    }

    return _BootstrapRecoveryApp(
      isLoading: _isLoading,
      didTimeout: _didTimeout,
      onRetry: _bootstrap,
    );
  }
}

class AetheraApp extends ConsumerWidget {
  const AetheraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle:
          (context) => AppLocalizations.of(context)?.appTitle ?? 'Aethera',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AetheraTokens.theme,
      routerConfig: appRouter,
    );
  }
}

Future<bool> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    }

    // Android/iOS/macOS with native config files.
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    // Fallback for desktop/dev setups that rely on generated options.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

Future<void> _initializeOptionalServices() async {
  try {
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    unawaited(
      CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'notification_init_failed',
      ),
    );
    // Non-fatal: app keeps running without notifications.
  }

  try {
    await MusicService.instance.initialize();
  } catch (error, stackTrace) {
    unawaited(
      CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'music_init_failed',
      ),
    );
    // Non-fatal: app keeps running without music.
  }
}

class _BootstrapRecoveryApp extends StatelessWidget {
  final bool isLoading;
  final bool didTimeout;
  final Future<void> Function() onRetry;

  const _BootstrapRecoveryApp({
    required this.isLoading,
    required this.didTimeout,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle:
          (context) => AppLocalizations.of(context)?.appTitle ?? 'Aethera',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);

          if (isLoading) {
            return Scaffold(
              backgroundColor: AetheraTokens.deepSpace,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AetheraTokens.auroraTeal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.startupLoadingMessage ?? 'Iniciando tu universo...',
                      style: AetheraTokens.bodyMedium(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }

          final bodyText =
              didTimeout
                  ? (l10n?.startupTimeoutMessage ??
                      'El inicio tardo demasiado. Intenta de nuevo.')
                  : (l10n?.startupErrorMessage ??
                      'Verifica la configuracion de Firebase e intentalo de nuevo.');

          return Scaffold(
            backgroundColor: AetheraTokens.deepSpace,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.startupErrorTitle ?? 'No se pudo iniciar Aethera',
                      textAlign: TextAlign.center,
                      style: AetheraTokens.displaySmall(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyText,
                      textAlign: TextAlign.center,
                      style: AetheraTokens.bodySmall(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => unawaited(onRetry()),
                      child: Text(l10n?.startupRetryButton ?? 'Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
