import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aethera/core/router/app_router.dart';
import 'package:aethera/core/theme/aethera_tokens.dart';
import 'package:aethera/core/services/notification_service.dart';
import 'package:aethera/core/services/music_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service (FCM + local notifications)
  // Wrapped in try-catch so a notification setup failure never blocks the app.
  try {
    await NotificationService.instance.initialize();
  } catch (_) {
    // Non-fatal — app runs without notifications if this fails
  }

  // Initialize music service
  try {
    await MusicService.instance.initialize();
  } catch (_) {
    // Non-fatal — app runs without music if this fails
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
