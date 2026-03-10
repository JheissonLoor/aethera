import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/services/music_service.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOk = await _initializeFirebase();
  if (!firebaseOk) {
    runApp(const _BootstrapErrorApp());
    return;
  }

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

  runApp(const ProviderScope(child: AetheraApp()));

  // Initialize non-critical services after first frame.
  unawaited(_initializeOptionalServices());
}

class AetheraApp extends ConsumerWidget {
  const AetheraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Aethera',
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
  } catch (_) {
    // Non-fatal: app keeps running without notifications.
  }

  try {
    await MusicService.instance.initialize();
  } catch (_) {
    // Non-fatal: app keeps running without music.
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AetheraTokens.deepSpace,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  'No se pudo iniciar Aethera',
                  textAlign: TextAlign.center,
                  style: AetheraTokens.displaySmall(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verifica la configuracion de Firebase e intentalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: AetheraTokens.bodySmall(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
