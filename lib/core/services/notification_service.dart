import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

// ─── FCM background handler (must be top-level) ───────────────────────────────
//
// Called when a data-only FCM message arrives and the app is in the background
// or terminated. Notification-type messages are shown automatically by the OS.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized at this point by the FCM plugin.
  // Nothing extra needed — the OS shows the notification payload automatically.
}

// ─── NotificationService ──────────────────────────────────────────────────────

/// Singleton that manages:
///   • FCM token lifecycle (request, store, refresh)
///   • Local notification display (foreground + scheduled)
///   • Weekly ritual reminder (every Monday 09:00, device-local)
///   • Convenience show-methods for each app event
///
/// Usage:
///   await NotificationService.instance.initialize();
///   NotificationService.instance.showPartnerOnlineNotification();
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _fcm = FirebaseMessaging.instance;

  static const _channelId = 'aethera_channel';
  static const _channelName = 'Aethera';
  static const _channelDesc = 'Notificaciones de conexión y rituales';

  bool _initialized = false;
  String? _lastKnownToken;
  String? _lastAuthUserId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authSub;

  // ── Initialize ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Timezone data (needed for scheduled notifications)
    tz_data.initializeTimeZones();

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      ledColor: null, // uses system default
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Initialize flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Register FCM background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request FCM permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _refreshAndStoreToken();
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((token) {
        _lastKnownToken = token;
        unawaited(_storeToken(token));
      });

      // Show local notification for foreground FCM messages
      FirebaseMessaging.onMessage.listen(_onForegroundFCMMessage);

      // Keep token/user mapping fresh when auth state changes.
      _authSub?.cancel();
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        final previousUserId = _lastAuthUserId;
        _lastAuthUserId = user?.uid;

        if (user == null) {
          if (previousUserId != null) {
            unawaited(_clearToken(previousUserId));
          }
          return;
        }

        if (_lastKnownToken != null) {
          unawaited(_storeToken(_lastKnownToken!));
        } else {
          unawaited(_refreshAndStoreToken());
        }
      });
    }

    // Schedule weekly ritual reminder
    await _scheduleWeeklyRitual();
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> _refreshAndStoreToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      _lastKnownToken = token;
      await _storeToken(token);
    }
  }

  Future<void> _storeToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal: token can be synced in the next auth/token refresh.
    }
  }

  Future<void> _clearToken(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal: stale token will be overwritten on the next sign-in.
    }
  }

  // ── Foreground FCM message handler ────────────────────────────────────────

  void _onForegroundFCMMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _show(
      id: message.hashCode & 0x7FFFFFFF,
      title: notification.title ?? 'Aethera',
      body: notification.body ?? '',
    );
  }

  // ── Notification tap handler ──────────────────────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    // Navigate based on payload if needed in the future
  }

  // ── Core show method ──────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── App-event notification helpers ────────────────────────────────────────

  /// Partner came online at the same time.
  void showPartnerOnlineNotification() => _show(
    id: 1,
    title: 'Están juntos en el universo ✦',
    body: 'Tu pareja también está conectada ahora mismo.',
  );

  /// Partner added a new memory to the shared universe.
  void showNewMemoryNotification() => _show(
    id: 2,
    title: 'Nueva memoria en tu universo ⭐',
    body: 'Tu pareja acaba de añadir un recuerdo.',
  );

  /// Partner completed their weekly ritual.
  void showPartnerRitualNotification() => _show(
    id: 3,
    title: 'Su carta llegó 💌',
    body: '¡Tu pareja completó el ritual semanal! Lee su respuesta.',
  );

  /// Partner sent a heartbeat pulse.
  void showPulseNotification() => _show(
    id: 4,
    title: 'Un latido para ti 💕',
    body: 'Tu pareja te envió un latido desde su universo.',
  );

  /// Partner added a new goal.
  void showNewGoalNotification() => _show(
    id: 5,
    title: 'Nueva meta en el horizonte 🎯',
    body: 'Tu pareja añadió una meta a su universo compartido.',
  );

  // ── Weekly ritual reminder ────────────────────────────────────────────────

  /// Schedules a recurring local notification every Monday at 09:00 (local time).
  /// Safe to call on every app launch — cancels the previous schedule first.
  Future<void> _scheduleWeeklyRitual() async {
    await _local.cancel(99); // cancel any previous schedule

    final scheduledDate = _nextMonday9AM();

    await _local.zonedSchedule(
      99,
      'Ritual semanal 🌙',
      '¿Listo para conectar con tu pareja esta semana?',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextMonday9AM() {
    final now = tz.TZDateTime.now(tz.local);
    // Start from today at 09:00
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    // Advance day-by-day until we land on a Monday that's in the future
    while (candidate.weekday != DateTime.monday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
