import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';
import 'pending_notification_navigation.dart';
import 'push_navigator.dart';

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'sembrapp_push',
  'Sembrapp',
  description: 'Pedidos y mensajes',
  importance: Importance.high,
);

/// Isolate de background: debe inicializar Firebase aquí.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (firebaseOptionsConfigured) {
    await Firebase.initializeApp(options: firebaseOptionsForPlatform());
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<AuthState>? _authSub;
  String? _fcmToken;
  String? _registeredUserId;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!firebaseOptionsConfigured) {
      debugPrint(
        'PushNotificationService: Firebase no configurado (dart-define).',
      );
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Arranque en frío: capturar destino antes de permisos / getToken (evita null o pérdida de orden).
    final launchDetails = await _local.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          PendingNotificationNavigation.instance.stashFromNotificationData(map);
        } catch (_) {}
      }
    }
    final initialFcm = await FirebaseMessaging.instance.getInitialMessage();
    if (initialFcm != null) {
      PendingNotificationNavigation.instance.stashFromNotificationData(
        initialFcm.data,
      );
    }

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('PushNotificationService: permiso de notificaciones denegado.');
    }

    FirebaseMessaging.onMessage.listen(_onForegroundRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _navigateFromData(m.data);
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      AuthState data,
    ) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _registeredUserId = data.session!.user.id;
        await _registerTokenForUser(_registeredUserId!);
      } else if (data.event == AuthChangeEvent.signedOut) {
        PendingNotificationNavigation.instance.clear();
        final uid = _registeredUserId;
        _registeredUserId = null;
        if (uid != null) {
          await _removeTokenFromServer(uid);
        }
        try {
          await FirebaseMessaging.instance.deleteToken();
        } catch (_) {}
        _fcmToken = null;
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      _fcmToken = t;
      final u = Supabase.instance.client.auth.currentUser;
      if (u != null) await _saveToken(u.id, t);
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _registeredUserId = user.id;
      await _registerTokenForUser(user.id);
    }

    _initialized = true;
  }

  void dispose() {
    _authSub?.cancel();
    _authSub = null;
  }

  Future<void> _registerTokenForUser(String userId) async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null || t.isEmpty) return;
      _fcmToken = t;
      await _saveToken(userId, t);
    } catch (e) {
      debugPrint('PushNotificationService: getToken $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    final platform = kIsWeb ? 'web' : Platform.operatingSystem;
    await Supabase.instance.client.from('user_push_tokens').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,fcm_token',
    );
  }

  Future<void> _removeTokenFromServer(String userId) async {
    final token = _fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await Supabase.instance.client
          .from('user_push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', token);
    } catch (e) {
      debugPrint('PushNotificationService: delete token $e');
    }
  }

  void _onForegroundRemoteMessage(RemoteMessage message) {
    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        'Sembrapp';
    final body =
        message.notification?.body ??
        message.data['body'] as String? ??
        '';
    final payload = jsonEncode(message.data);
    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final p = response.payload;
    if (p == null || p.isEmpty) return;
    try {
      final map = jsonDecode(p) as Map<String, dynamic>;
      _navigateFromData(map);
    } catch (_) {}
  }

  void _navigateFromData(Map<String, dynamic> data) {
    PushNavigator.openFromPushData(data);
  }
}
